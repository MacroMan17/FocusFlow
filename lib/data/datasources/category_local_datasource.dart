import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/hive_constants.dart';
import '../models/category_model.dart';

/// Handles all raw Hive read/write/delete operations for [CategoryModel].
class CategoryLocalDatasource {
  Box<CategoryModel> get _box =>
      Hive.box<CategoryModel>(HiveConstants.categoryBox);

  /// Returns all categories as an unordered list.
  List<CategoryModel> getAllCategories() {
    return _box.values.toList();
  }

  /// Returns the category with [id], or null if not found.
  CategoryModel? getCategoryById(String id) {
    return _box.get(id);
  }

  /// Returns true if a category with the given [name] already exists
  /// (case-insensitive comparison).
  bool categoryNameExists(String name) {
    final lower = name.toLowerCase().trim();
    return _box.values.any((c) => c.name.toLowerCase().trim() == lower);
  }

  /// Saves a new category. Uses category.id as the Hive key.
  Future<void> saveCategory(CategoryModel category) async {
    await _box.put(category.id, category);
  }

  /// Overwrites an existing category by id.
  Future<void> updateCategory(CategoryModel category) async {
    await _box.put(category.id, category);
  }

  /// Deletes the category with [id]. No-op if not found.
  Future<void> deleteCategory(String id) async {
    await _box.delete(id);
  }

  /// Returns true if the seed flag is present (categories already seeded).
  bool isCategoriesSeeded() {
    final metaBox = Hive.box(HiveConstants.metaBox);
    return metaBox.get(HiveConstants.categoriesSeededKey, defaultValue: false)
        as bool;
  }

  /// Persists all provided categories and marks the seed flag.
  Future<void> seedCategories(List<CategoryModel> categories) async {
    for (final category in categories) {
      await _box.put(category.id, category);
    }
    final metaBox = Hive.box(HiveConstants.metaBox);
    await metaBox.put(HiveConstants.categoriesSeededKey, true);
  }

  /// Deletes all categories. Used by Reset All Data.
  Future<void> clearAll() async {
    await _box.clear();
    // Also reset the seed flag so defaults re-seed after reset.
    final metaBox = Hive.box(HiveConstants.metaBox);
    await metaBox.delete(HiveConstants.categoriesSeededKey);
  }

  /// Stream that emits the full category list whenever the box changes.
  Stream<List<CategoryModel>> watchAllCategories() {
    return _box.watch().map((_) => _box.values.toList());
  }

  /// Returns true if the box is open and ready.
  bool get isOpen => _box.isOpen;
}
