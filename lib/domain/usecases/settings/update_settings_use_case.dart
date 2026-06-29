import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/failure.dart';
import '../../entities/settings_entity.dart';
import '../../repositories/settings_repository.dart';
import '../use_case.dart';

/// Persists a full [SettingsEntity] update.
class UpdateSettingsUseCase
    implements UseCase<SettingsEntity, SettingsEntity> {
  final SettingsRepository _repository;

  UpdateSettingsUseCase(this._repository);

  @override
  Future<Either<Failure, SettingsEntity>> call(SettingsEntity params) {
    return _repository.updateSettings(params);
  }
}

/// Convenience use case for updating only the theme mode.
class UpdateThemeModeUseCase implements UseCase<SettingsEntity, ThemeMode> {
  final SettingsRepository _repository;

  UpdateThemeModeUseCase(this._repository);

  @override
  Future<Either<Failure, SettingsEntity>> call(ThemeMode themeMode) async {
    final result = await _repository.getSettings();
    return result.fold(
      (failure) async => Left(failure),
      (settings) => _repository.updateSettings(
        settings.copyWith(themeMode: themeMode),
      ),
    );
  }
}

/// Convenience use case for updating only the accent color.
class UpdateAccentColorUseCase implements UseCase<SettingsEntity, int> {
  final SettingsRepository _repository;

  UpdateAccentColorUseCase(this._repository);

  @override
  Future<Either<Failure, SettingsEntity>> call(int colorValue) async {
    final result = await _repository.getSettings();
    return result.fold(
      (failure) async => Left(failure),
      (settings) => _repository.updateSettings(
        settings.copyWith(accentColor: colorValue),
      ),
    );
  }
}

/// Marks onboarding as complete.
class CompleteOnboardingUseCase implements NoParamsUseCase<SettingsEntity> {
  final SettingsRepository _repository;

  CompleteOnboardingUseCase(this._repository);

  @override
  Future<Either<Failure, SettingsEntity>> call() async {
    final result = await _repository.getSettings();
    return result.fold(
      (failure) async => Left(failure),
      (settings) => _repository.updateSettings(
        settings.copyWith(onboardingCompleted: true),
      ),
    );
  }
}

/// Resets all settings to factory defaults.
class ResetSettingsUseCase implements NoParamsUseCase<Unit> {
  final SettingsRepository _repository;

  ResetSettingsUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call() {
    return _repository.resetSettings();
  }
}
