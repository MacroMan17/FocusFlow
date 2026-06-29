import 'package:dartz/dartz.dart';
import '../../../core/utils/failure.dart';
import '../../repositories/task_repository.dart';
import '../use_case.dart';

class DeleteTaskUseCase implements UseCase<void, String> {
  final TaskRepository _repository;
  DeleteTaskUseCase(this._repository);
  @override
  Future<Either<Failure, void>> call(String id) => _repository.deleteTask(id);
}
