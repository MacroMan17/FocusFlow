import 'package:dartz/dartz.dart';
import '../../../core/utils/failure.dart';
import '../../entities/category_entity.dart';
import '../../repositories/category_repository.dart';
import '../use_case.dart';

class UpdateCategoryUseCase implements UseCase<CategoryEntity, CategoryEntity> {
  final CategoryRepository _repository;
  UpdateCategoryUseCase(this._repository);
  @override
  Future<Either<Failure, CategoryEntity>> call(CategoryEntity params) {
    if (params.name.trim().isEmpty) {
      return Future.value(const Left(ValidationFailure('Category name cannot be empty.')));
    }
    return _repository.updateCategory(params);
  }
}
