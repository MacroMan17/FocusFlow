import 'package:dartz/dartz.dart';
import '../../../core/utils/failure.dart';
import '../../entities/category_entity.dart';
import '../../repositories/category_repository.dart';
import '../use_case.dart';

class GetAllCategoriesUseCase implements NoParamsUseCase<List<CategoryEntity>> {
  final CategoryRepository _repository;
  GetAllCategoriesUseCase(this._repository);
  @override
  Future<Either<Failure, List<CategoryEntity>>> call() =>
      _repository.getAllCategories();
}
