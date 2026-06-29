import 'package:dartz/dartz.dart';
import '../../../core/utils/failure.dart';
import '../../entities/category_entity.dart';
import '../../repositories/category_repository.dart';
import '../use_case.dart';

class CreateCategoryUseCase
    implements UseCase<CategoryEntity, CreateCategoryParams> {
  final CategoryRepository _repository;

  CreateCategoryUseCase(this._repository);

  @override
  Future<Either<Failure, CategoryEntity>> call(
      CreateCategoryParams params) async {
    final trimmedName = params.name.trim();

    if (trimmedName.isEmpty) {
      return const Left(ValidationFailure('Category name cannot be empty.'));
    }

    if (trimmedName.length > 30) {
      return const Left(
          ValidationFailure('Category name must be 30 characters or fewer.'));
    }

    // Guard against duplicate names.
    final existsResult = await _repository.categoryNameExists(trimmedName);
    final alreadyExists = existsResult.fold((_) => false, (exists) => exists);
    if (alreadyExists) {
      return Left(
          ValidationFailure('A category named "$trimmedName" already exists.'));
    }

    final category = CategoryEntity(
      id: params.id,
      name: trimmedName,
      color: params.color,
      icon: params.icon,
      createdAt: DateTime.now(),
      isDefault: false,
    );

    return _repository.createCategory(category);
  }
}

class CreateCategoryParams {
  final String id;
  final String name;
  final int color;
  final String icon;

  const CreateCategoryParams({
    required this.id,
    required this.name,
    required this.color,
    this.icon = 'label',
  });
}
