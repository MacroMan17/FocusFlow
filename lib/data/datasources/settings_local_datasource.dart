import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/hive_constants.dart';
import '../models/settings_model.dart';

/// Handles all raw Hive read/write operations for [SettingsModel].
/// There is always exactly one record, keyed by [HiveConstants.settingsKey].
class SettingsLocalDatasource {
  Box<SettingsModel> get _box =>
      Hive.box<SettingsModel>(HiveConstants.settingsBox);

  /// Returns the saved settings, or null if not yet seeded.
  SettingsModel? getSettings() {
    return _box.get(HiveConstants.settingsKey);
  }

  /// Persists settings under the fixed key.
  Future<void> saveSettings(SettingsModel settings) async {
    await _box.put(HiveConstants.settingsKey, settings);
  }

  /// Removes the settings record. Used by Reset All Data.
  Future<void> clearSettings() async {
    await _box.delete(HiveConstants.settingsKey);
  }

  /// Clears the entire settings box (all keys).
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Stream that emits the settings model whenever it changes.
  /// Emits null if the record is deleted (e.g., during reset).
  Stream<SettingsModel?> watchSettings() {
    return _box
        .watch(key: HiveConstants.settingsKey)
        .map((_) => _box.get(HiveConstants.settingsKey));
  }

  /// Returns true if the box is open and ready.
  bool get isOpen => _box.isOpen;
}
