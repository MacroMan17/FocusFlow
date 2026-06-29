import 'package:dartz/dartz.dart';
import '../../../core/utils/failure.dart';
import '../../entities/task_entity.dart';
import '../../repositories/task_repository.dart';
import '../use_case.dart';

/// Returns all incomplete tasks due today.
class GetTodayTasksUseCase implements NoParamsUseCase<List<TaskEntity>> {
  final TaskRepository _repository;

  GetTodayTasksUseCase(this._repository);

  @override
  Future<Either<Failure, List<TaskEntity>>> call() {
    return _repository.getTodayTasks();
  }
}

/// Returns all incomplete tasks due after today.
class GetUpcomingTasksUseCase implements NoParamsUseCase<List<TaskEntity>> {
  final TaskRepository _repository;

  GetUpcomingTasksUseCase(this._repository);

  @override
  Future<Either<Failure, List<TaskEntity>>> call() {
    return _repository.getUpcomingTasks();
  }
}

/// Returns all incomplete tasks whose dueDate is in the past.
class GetOverdueTasksUseCase implements NoParamsUseCase<List<TaskEntity>> {
  final TaskRepository _repository;

  GetOverdueTasksUseCase(this._repository);

  @override
  Future<Either<Failure, List<TaskEntity>>> call() {
    return _repository.getOverdueTasks();
  }
}

/// Returns all completed tasks.
class GetCompletedTasksUseCase implements NoParamsUseCase<List<TaskEntity>> {
  final TaskRepository _repository;

  GetCompletedTasksUseCase(this._repository);

  @override
  Future<Either<Failure, List<TaskEntity>>> call() {
    return _repository.getCompletedTasks();
  }
}

/// Returns a single task by id.
class GetTaskByIdUseCase implements UseCase<TaskEntity, GetTaskByIdParams> {
  final TaskRepository _repository;

  GetTaskByIdUseCase(this._repository);

  @override
  Future<Either<Failure, TaskEntity>> call(GetTaskByIdParams params) {
    return _repository.getTaskById(params.id);
  }
}

class GetTaskByIdParams {
  final String id;

  const GetTaskByIdParams({required this.id});
}
