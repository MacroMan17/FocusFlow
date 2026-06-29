import 'package:dartz/dartz.dart';
import '../../../core/utils/failure.dart';
import '../../entities/task_entity.dart';
import '../../repositories/task_repository.dart';
import '../use_case.dart';

class CompleteTaskUseCase implements UseCase<TaskEntity, String> {
  final TaskRepository _repository;
  CompleteTaskUseCase(this._repository);
  @override
  Future<Either<Failure, TaskEntity>> call(String id) => _repository.completeTask(id);
}

class UncompleteTaskUseCase implements UseCase<TaskEntity, String> {
  final TaskRepository _repository;
  UncompleteTaskUseCase(this._repository);
  @override
  Future<Either<Failure, TaskEntity>> call(String id) => _repository.uncompleteTask(id);
}
