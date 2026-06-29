import 'package:dartz/dartz.dart';
import '../../../core/utils/failure.dart';
import '../../entities/task_entity.dart';
import '../../repositories/task_repository.dart';
import '../use_case.dart';

class SearchTasksUseCase implements UseCase<List<TaskEntity>, String> {
  final TaskRepository _repository;
  SearchTasksUseCase(this._repository);
  @override
  Future<Either<Failure, List<TaskEntity>>> call(String query) =>
      _repository.searchTasks(query);
}
