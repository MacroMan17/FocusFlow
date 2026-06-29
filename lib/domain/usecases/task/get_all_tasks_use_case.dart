import 'package:dartz/dartz.dart';
import '../../../core/utils/failure.dart';
import '../../entities/task_entity.dart';
import '../../repositories/task_repository.dart';
import '../use_case.dart';

class GetAllTasksUseCase implements NoParamsUseCase<List<TaskEntity>> {
  final TaskRepository _repository;
  GetAllTasksUseCase(this._repository);
  @override
  Future<Either<Failure, List<TaskEntity>>> call() => _repository.getAllTasks();
}
