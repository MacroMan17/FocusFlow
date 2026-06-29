import 'package:dartz/dartz.dart';

import '../../core/utils/failure.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../models/mappers/settings_mapper.dart';
import '../models/settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDatasource _datasource;

  SettingsRepositoryImpl(this._datasource);

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<Either<Failure, T>> _tryCatch<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } catch (e) {
      if (e is Failure) return Left(e);
      return Left(StorageFailure(e.toString()));
    }
  }

  /// Returns the default [SettingsModel] used when no settings exist yet.
  SettingsModel _defaultModel() {
    final defaults = SettingsEntity.defaults();
    return SettingsMapper.entityToModel(defaults);
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, SettingsEntity>> getSettings() async {
    return _tryCatch(() async {
      final model = _datasource.getSettings();
      if (model == null) {
        // First launch — seed defaults and return them.
        final defaults = _defaultModel();
        await _datasource.saveSettings(defaults);
        return SettingsMapper.modelToEntity(defaults);
      }
      return SettingsMapper.modelToEntity(model);
    });
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, SettingsEntity>> updateSettings(
      SettingsEntity settings) async {
    return _tryCatch(() async {
      final model = SettingsMapper.entityToModel(settings);
      await _datasource.saveSettings(model);
      return settings;
    });
  }

  // ── Seed ───────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> seedDefaultSettings() async {
    return _tryCatch(() async {
      // No-op if settings already exist.
      if (_datasource.getSettings() != null) return unit;
      await _datasource.saveSettings(_defaultModel());
      return unit;
    });
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> resetSettings() async {
    return _tryCatch(() async {
      await _datasource.clearAll();
      // Re-seed defaults immediately so the app is never in a settings-less state.
      await _datasource.saveSettings(_defaultModel());
      return unit;
    });
  }

  // ── Stream ─────────────────────────────────────────────────────────────────

  @override
  Stream<SettingsEntity> watchSettings() {
    return _datasource.watchSettings().map((model) {
      if (model == null) return SettingsEntity.defaults();
      return SettingsMapper.modelToEntity(model);
    });
  }
}
