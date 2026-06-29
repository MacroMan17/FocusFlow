import 'package:dartz/dartz.dart';

import '../../core/utils/failure.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';
import '../datasources/task_local_datasource.dart';
import '../models/mappers/category_mapper.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDatasource _categoryDatasource;
  final TaskLocalDatasource _taskDatasource;

  CategoryRepositoryImpl(this._categoryDatasource, this._taskDatasource);

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<Either<Failure, T>> _tryCatch<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } catch (e, st) {
      if (e is Failure) return Left(e);
      return Left(StorageFailure('$e\n$st'));
    }
  }

  Either<Failure, T> _tryCatchSync<T>(T Function() action) {
    try {
      return Right(action());
    } catch (e) {
      if (e is Failure) return Left(e);
      return Left(StorageFailure(e.toString()));
    }
  }

  // ── Reads ──────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<CategoryEntity>>> getAllCategories() async {
    return _tryCatchSync(() => _categoryDatasource
        .getAllCategories()
        .map(CategoryMapper.modelToEntity)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
  }

  @override
  Future<Either<Failure, CategoryEntity>> getCategoryById(String id) async {
    return _tryCatchSync(() {
      final model = _categoryDatasource.getCategoryById(id);
      if (model == null) {
        throw NotFoundFailure('Category not found: $id');
      }
      return CategoryMapper.modelToEntity(model);
    });
  }

  @override
  Future<Either<Failure, bool>> categoryNameExists(String name) async {
    return _tryCatchSync(() => _categoryDatasource.categoryNameExists(name));
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, CategoryEntity>> createCategory(
      CategoryEntity category) async {
    return _tryCatch(() async {
      final model = CategoryMapper.entityToModel(category);
      await _categoryDatasource.saveCategory(model);
      return category;
    });
  }

  @override
  Future<Either<Failure, CategoryEntity>> updateCategory(
      CategoryEntity category) async {
    return _tryCatch(() async {
      final existing = _categoryDatasource.getCategoryById(category.id);
      if (existing == null) {
        throw NotFoundFailure('Category not found: ${category.id}');
      }
      final model = CategoryMapper.entityToModel(category);
      await _categoryDatasource.updateCategory(model);
      return category;
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteCategory(String id) async {
    return _tryCatch(() async {
      final existing = _categoryDatasource.getCategoryById(id);
      if (existing == null) {
        throw NotFoundFailure('Category not found: $id');
      }
      // Unassign tasks first (do NOT delete them).
      await _taskDatasource.unassignTasksFromCategory(id);
      await _categoryDatasource.deleteCategory(id);
      return unit;
    });
  }

  // ── Seeding ────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> seedDefaultCategories() async {
    return _tryCatch(() async {
      if (_categoryDatasource.isCategoriesSeeded()) return unit;

      final now = DateTime.now();
      final defaults = [
        CategoryEntity(
          id: 'cat_personal',
          name: 'Personal',
          color: 0xFF9C27B0, // Purple
          icon: 'person',
          createdAt: now,
          isDefault: true,
        ),
        CategoryEntity(
          id: 'cat_work',
          name: 'Work',
          color: 0xFF2196F3, // Blue
          icon: 'work',
          createdAt: now.add(const Duration(milliseconds: 1)),
          isDefault: true,
        ),
        CategoryEntity(
          id: 'cat_study',
          name: 'Study',
          color: 0xFF4CAF50, // Green
          icon: 'school',
          createdAt: now.add(const Duration(milliseconds: 2)),
          isDefault: true,
        ),
        CategoryEntity(
          id: 'cat_health',
          name: 'Health',
          color: 0xFFF44336, // Red
          icon: 'favorite',
          createdAt: now.add(const Duration(milliseconds: 3)),
          isDefault: true,
        ),
      ];

      await _categoryDatasource
          .seedCategories(defaults.map(CategoryMapper.entityToModel).toList());
      return unit;
    });
  }

  // ── Streams ────────────────────────────────────────────────────────────────

  @override
  Stream<List<CategoryEntity>> watchAllCategories() {
    return _categoryDatasource.watchAllCategories().map((models) =>
        models.map(CategoryMapper.modelToEntity).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));
  }
}
