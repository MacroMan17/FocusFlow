/// Hive box names and key constants used across datasources.
class HiveConstants {
  HiveConstants._();

  // Box names
  static const String taskBox = 'tasks';
  static const String categoryBox = 'categories';

  /// Typed box — stores the single SettingsModel record.
  static const String settingsBox = 'settings';

  /// Untyped box — stores boolean seed flags and other primitives.
  static const String metaBox = 'meta';

  // Settings key (used inside settingsBox)
  static const String settingsKey = 'settings';

  // Seed flag keys stored inside metaBox
  static const String categoriesSeededKey = 'categories_seeded';
}
