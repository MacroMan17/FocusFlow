import 'package:dartz/dartz.dart';
import '../../../core/utils/failure.dart';
import '../../repositories/category_repository.dart';
import '../use_case.dart';

/// Seeds the 4 default categories (Personal, Work, Study, Health)
/// on first run. Safe to call on every launch — no-op if already seeded.
class SeedDefaultCategoriesUseCase implements NoParamsUseCase<Unit> {
  final CategoryRepository _repository;

  SeedDefaultCategoriesUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call() {
    return _repository.seedDefaultCategories();
  }
}
