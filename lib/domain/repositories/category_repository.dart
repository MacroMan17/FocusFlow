import 'package:dartz/dartz.dart';
import '../../core/utils/failure.dart';
import '../entities/category_entity.dart';

/// Abstract contract for all category persistence operations.
/// Implementations live in data/repositories/.
abstract class CategoryRepository {
  /// Returns all categories ordered by createdAt ascending.
  Future<Either<Failure, List<CategoryEntity>>> getAllCategories();

  /// Returns a single category by [id].
  /// Returns [NotFoundFailure] if no category with that id exists.
  Future<Either<Failure, CategoryEntity>> getCategoryById(String id);

  /// Persists a new category. Returns the saved entity on success.
  Future<Either<Failure, CategoryEntity>> createCategory(
      CategoryEntity category);

  /// Overwrites an existing category by id. Returns the updated entity.
  /// Returns [NotFoundFailure] if no category with that id exists.
  Future<Either<Failure, CategoryEntity>> updateCategory(
      CategoryEntity category);

  /// Removes a category by [id].
  /// Does NOT delete associated tasks — caller must unassign them first.
  /// Returns [NotFoundFailure] if no category with that id exists.
  Future<Either<Failure, Unit>> deleteCategory(String id);

  /// Returns true if any category with [name] already exists (case-insensitive).
  Future<Either<Failure, bool>> categoryNameExists(String name);

  /// Seeds the 4 default categories if they have never been seeded before.
  /// Should be called once on first launch.
  Future<Either<Failure, Unit>> seedDefaultCategories();

  /// Watches the category box and emits the full list on every change.
  Stream<List<CategoryEntity>> watchAllCategories();
}
