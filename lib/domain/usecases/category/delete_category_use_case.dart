import 'package:dartz/dartz.dart';
import '../../../core/utils/failure.dart';
import '../../repositories/category_repository.dart';
import '../use_case.dart';

class DeleteCategoryUseCase implements UseCase<void, String> {
  final CategoryRepository _repository;
  DeleteCategoryUseCase(this._repository);
  @override
  Future<Either<Failure, void>> call(String id) => _repository.deleteCategory(id);
}
