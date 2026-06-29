import 'package:dartz/dartz.dart';
import '../../../core/utils/failure.dart';
import '../../entities/task_entity.dart';
import '../../repositories/task_repository.dart';
import '../use_case.dart';

class GetTasksByDateUseCase implements UseCase<List<TaskEntity>, DateTime> {
  final TaskRepository _repository;
  GetTasksByDateUseCase(this._repository);
  @override
  Future<Either<Failure, List<TaskEntity>>> call(DateTime date) =>
      _repository.getTasksByDate(date);
}
