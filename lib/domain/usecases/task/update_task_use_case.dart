import 'package:dartz/dartz.dart';
import '../../../core/utils/failure.dart';
import '../../entities/task_entity.dart';
import '../../repositories/task_repository.dart';
import '../use_case.dart';

class UpdateTaskUseCase implements UseCase<TaskEntity, TaskEntity> {
  final TaskRepository _repository;
  UpdateTaskUseCase(this._repository);
  @override
  Future<Either<Failure, TaskEntity>> call(TaskEntity params) {
    if (params.title.trim().isEmpty) {
      return Future.value(const Left(ValidationFailure('Title cannot be empty.')));
    }
    return _repository.updateTask(params);
  }
}
