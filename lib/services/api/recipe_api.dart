import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:asan/models/api_recipe.dart';
export 'package:asan/models/api_recipe.dart';

class RecipeApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? quotaLeft;

  const RecipeApiException(this.message, {this.statusCode, this.quotaLeft});

  @override
  String toString() => message;
}

String _httpErrorMessage(int statusCode) => switch (statusCode) {
      400 => 'Bad Request: the recipe service could not understand the request.',
      401 => 'Unauthorized: the recipe service did not accept the credentials.',
      403 => 'Forbidden: the recipe service denied access to this request.',
      404 => 'Not Found: the requested recipe or service endpoint could not be found.',
      402 => 'Daily API quota exceeded: the recipe searches will be available again after the quota resets at midnight UTC.',
      429 => 'Rate limit exceeded: the recipe service allows only a limited number of requests per minute. Please wait and try again.',
      500 => 'Internal Server Error: the recipe service encountered a problem.',
      502 => 'Bad Gateway: the recipe provider returned an invalid response.',
      503 => 'Service Unavailable: the recipe service is temporarily unavailable.',
      504 => 'Gateway Timeout: the recipe provider took too long to respond.',
      _ => 'The recipe service returned an HTTP error. Please try again later.',
    };


class RecipeApi {
  RecipeApi({http.Client? client}) : _client = client ?? http.Client();

  static String _supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  static String _supabasePublishableKey =
      const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static Future<void> loadConfig() async {
    try {
      final config = jsonDecode(
        await rootBundle.loadString('env.json'),
      );
      if (config is Map<String, dynamic>) {
        final url = config['SUPABASE_URL'];
        final publishableKey = config['SUPABASE_PUBLISHABLE_KEY'];
        if (url is String && url.trim().isNotEmpty) {
          _supabaseUrl = url.trim();
        }
        if (publishableKey is String && publishableKey.trim().isNotEmpty) {
          _supabasePublishableKey = publishableKey.trim();
        }
      }
    } on FlutterError {
      // The runtime config is optional when build-time defines are supplied.
    } on FormatException {
      // Keep build-time values if the local config file is invalid.
    }
  }

  final http.Client _client;

  Future<String?> imageFor(String recipeTitle, {String? imageUrl}) async {
    if (imageUrl == null || imageUrl.trim().isEmpty) return null;
    final uri = Uri.tryParse(imageUrl.trim());
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? uri.toString()
        : null;
  }

  Future<List<ApiRecipe>> search(String query, {String? type}) async {
    final trimmedQuery = query.trim();
    final trimmedType = type?.trim();
    if (trimmedQuery.length > 100 || (trimmedType?.length ?? 0) > 100) {
      throw const RecipeApiException('Search must be 100 characters or fewer.');
    }
    _checkSupabaseConfig();
    final payload = <String, Object>{'action': 'search', 'query': trimmedQuery};
    if (trimmedType != null && trimmedType.isNotEmpty) payload['type'] = trimmedType;
    late final Map<String, dynamic> response;
    try {
      response = await _invokeSpoonacular(payload);
    } on RecipeApiException catch (error) {
      // Provider gateway failures are often transient; retry once before
      // reporting the search as failed.
      if (error.statusCode != 502 &&
          error.statusCode != 503 &&
          error.statusCode != 504) {
        rethrow;
      }
      await Future<void>.delayed(const Duration(milliseconds: 350));
      response = await _invokeSpoonacular(payload);
    }
    final recipes = response['results'];
    if (recipes is! List) throw const RecipeApiException('Spoonacular returned invalid data.');
    return recipes.whereType<Map<String, dynamic>>().map(ApiRecipe.fromSpoonacularJson).toList();
  }

  Future<ApiRecipe> getById(String id) async {
    final sourceId = id.startsWith('spoonacular:') ? id.substring('spoonacular:'.length) : id;
    if (sourceId.isEmpty || sourceId.length > 64 || !RegExp(r'^\d+$').hasMatch(sourceId)) {
      throw const RecipeApiException('Invalid recipe id.');
    }
    _checkSupabaseConfig();
    final response = await _invokeSpoonacular({'action': 'information', 'id': sourceId});
    return ApiRecipe.fromSpoonacularJson(response);
  }

  void _checkSupabaseConfig() {
    if (_supabaseUrl.isEmpty || _supabasePublishableKey.isEmpty) {
      throw const RecipeApiException('Recipe search is not configured. Add SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY to env.json.');
    }
  }

  Future<Map<String, dynamic>> _invokeSpoonacular(Map<String, Object> payload) =>
      _post(Uri.parse('$_supabaseUrl/functions/v1/spoonacular'), payload);

  Future<Map<String, dynamic>> _post(Uri uri, Map<String, Object> payload) async {
    late final http.Response response;
    try {
      response = await _client.post(uri,
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json', 'apikey': _supabasePublishableKey},
        body: jsonEncode(payload));
    } on Exception {
      throw const RecipeApiException('Could not reach the recipe service. Check your connection.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var statusCode = response.statusCode;
      try {
        final errorBody = jsonDecode(response.body);
        if (errorBody is Map<String, dynamic>) {
          final upstreamStatus = errorBody['upstreamStatus'];
          if (upstreamStatus is int && upstreamStatus >= 100 && upstreamStatus <= 599) {
            statusCode = upstreamStatus;
          }
        }
      } on FormatException {
        // Fall back to the HTTP status returned by the function.
      }
      final quotaLeft = response.headers['x-api-quota-left'];
      final message = _httpErrorMessage(statusCode);
      throw RecipeApiException(
        quotaLeft == null || quotaLeft.isEmpty
            ? message
            : '$message Quota points remaining today: $quotaLeft.',
        statusCode: statusCode,
        quotaLeft: quotaLeft,
      );
    }
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) return body;
    } on FormatException {}
    throw const RecipeApiException('Recipe service returned invalid data.');
  }

  void close() => _client.close();
}


