import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static String supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  static String supabasePublishableKey =
      const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static Future<void> load() async {
    try {
      final config = jsonDecode(await rootBundle.loadString('env.json'));
      if (config is! Map<String, dynamic>) return;
      final url = config['SUPABASE_URL'];
      final key = config['SUPABASE_PUBLISHABLE_KEY'];
      if (url is String && url.trim().isNotEmpty) supabaseUrl = url.trim();
      if (key is String && key.trim().isNotEmpty) {
        supabasePublishableKey = key.trim();
      }
    } on FlutterError {
      // Build-time defines remain available when env.json is not bundled.
    } on FormatException {
      // Build-time defines remain available when env.json is invalid.
    }
  }

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
