import 'package:dartz/dartz.dart';
import '../../../core/utils/failure.dart';
import '../../entities/task_entity.dart';
import '../../repositories/task_repository.dart';
import '../use_case.dart';

class GetTasksByCategoryUseCase implements UseCase<List<TaskEntity>, String> {
  final TaskRepository _repository;
  GetTasksByCategoryUseCase(this._repository);
  @override
  Future<Either<Failure, List<TaskEntity>>> call(String categoryId) =>
      _repository.getTasksByCategory(categoryId);
}
