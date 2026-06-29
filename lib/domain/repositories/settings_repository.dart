import 'package:dartz/dartz.dart';
import '../../core/utils/failure.dart';
import '../entities/settings_entity.dart';

/// Abstract contract for all settings persistence operations.
/// There is always exactly one SettingsEntity in storage (id = 'settings').
/// Implementations live in data/repositories/.
abstract class SettingsRepository {
  /// Returns the current settings.
  /// Seeds and returns defaults if no settings exist yet.
  Future<Either<Failure, SettingsEntity>> getSettings();

  /// Persists the given settings, overwriting the existing record.
  /// Returns the saved entity on success.
  Future<Either<Failure, SettingsEntity>> updateSettings(
      SettingsEntity settings);

  /// Seeds default settings if no settings exist yet.
  /// Safe to call multiple times — no-op if settings already exist.
  Future<Either<Failure, Unit>> seedDefaultSettings();

  /// Clears all settings and re-seeds defaults.
  /// Used by the "Reset All Data" flow.
  Future<Either<Failure, Unit>> resetSettings();

  /// Watches the settings box and emits the entity on every change.
  Stream<SettingsEntity> watchSettings();
}
