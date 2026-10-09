import 'package:asan/data/storage_box.dart';
import 'package:asan/models/api_recipe.dart';

class SavedRecipeBox {
  SavedRecipeBox(this._box);
  final StorageBox _box;

  List<String> read() => _box.readStrings();
  Future<void> write(Iterable<String> titles) => _box.writeStrings(titles);

  List<ApiRecipe> readRecipes() => _box
      .readMaps()
      .map(ApiRecipe.fromJson)
      .where((recipe) => recipe.title.isNotEmpty)
      .toList();

  static Map<String, dynamic> toJson(ApiRecipe recipe) => recipe.toJson();
  static ApiRecipe fromJson(Map<String, dynamic> json) =>
      ApiRecipe.fromJson(json);

  Future<void> writeRecipes(Iterable<ApiRecipe> recipes) =>
      _box.writeMaps(recipes.map((recipe) => recipe.toJson()));
}
