import 'package:dartz/dartz.dart';
import '../../../core/utils/failure.dart';
import '../../entities/settings_entity.dart';
import '../../repositories/settings_repository.dart';
import '../use_case.dart';

/// Returns the persisted [SettingsEntity].
/// Seeds and returns defaults on first launch if none exist yet.
class GetSettingsUseCase implements NoParamsUseCase<SettingsEntity> {
  final SettingsRepository _repository;

  GetSettingsUseCase(this._repository);

  @override
  Future<Either<Failure, SettingsEntity>> call() {
    return _repository.getSettings();
  }
}
