import 'package:dartz/dartz.dart';

import '../../core/utils/failure.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_datasource.dart';
import '../models/mappers/task_mapper.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDatasource _datasource;

  TaskRepositoryImpl(this._datasource);

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<Either<Failure, T>> _tryCatch<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } catch (e) {
      if (e is Failure) return Left(e);
      return Left(StorageFailure(e.toString()));
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
  Future<Either<Failure, List<TaskEntity>>> getAllTasks() async {
    return _tryCatchSync(() =>
        _datasource.getAllTasks().map(TaskMapper.taskModelToEntity).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  @override
  Future<Either<Failure, TaskEntity>> getTaskById(String id) async {
    return _tryCatchSync(() {
      final model = _datasource.getTaskById(id);
      if (model == null) throw NotFoundFailure('Task not found: $id');
      return TaskMapper.taskModelToEntity(model);
    });
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getTasksByCategory(
      String categoryId) async {
    return _tryCatchSync(() => _datasource
        .getTasksByCategory(categoryId)
        .map(TaskMapper.taskModelToEntity)
        .toList());
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getTasksByDate(
      DateTime date) async {
    return _tryCatchSync(() => _datasource
        .getTasksByDate(date)
        .map(TaskMapper.taskModelToEntity)
        .toList());
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getOverdueTasks() async {
    return _tryCatchSync(() => _datasource
        .getOverdueTasks()
        .map(TaskMapper.taskModelToEntity)
        .toList());
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getTodayTasks() async {
    return _tryCatchSync(() =>
        _datasource.getTodayTasks().map(TaskMapper.taskModelToEntity).toList());
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getUpcomingTasks() async {
    return _tryCatchSync(() => _datasource
        .getUpcomingTasks()
        .map(TaskMapper.taskModelToEntity)
        .toList());
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> getCompletedTasks() async {
    return _tryCatchSync(() => _datasource
        .getCompletedTasks()
        .map(TaskMapper.taskModelToEntity)
        .toList());
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> searchTasks(String query) async {
    return _tryCatchSync(() => _datasource
        .searchTasks(query)
        .map(TaskMapper.taskModelToEntity)
        .toList());
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, TaskEntity>> createTask(TaskEntity task) async {
    return _tryCatch(() async {
      final model = TaskMapper.taskEntityToModel(task);
      await _datasource.saveTask(model);
      return task;
    });
  }

  @override
  Future<Either<Failure, TaskEntity>> updateTask(TaskEntity task) async {
    return _tryCatch(() async {
      final existing = _datasource.getTaskById(task.id);
      if (existing == null) {
        throw NotFoundFailure('Task not found: ${task.id}');
      }
      final model = TaskMapper.taskEntityToModel(task);
      await _datasource.updateTask(model);
      return task;
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteTask(String id) async {
    return _tryCatch(() async {
      final existing = _datasource.getTaskById(id);
      if (existing == null) throw NotFoundFailure('Task not found: $id');
      await _datasource.deleteTask(id);
      return unit;
    });
  }

  @override
  Future<Either<Failure, TaskEntity>> completeTask(String id) async {
    return _tryCatch(() async {
      final model = _datasource.getTaskById(id);
      if (model == null) throw NotFoundFailure('Task not found: $id');
      final updated = model.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      await _datasource.updateTask(updated);
      return TaskMapper.taskModelToEntity(updated);
    });
  }

  @override
  Future<Either<Failure, TaskEntity>> uncompleteTask(String id) async {
    return _tryCatch(() async {
      final model = _datasource.getTaskById(id);
      if (model == null) throw NotFoundFailure('Task not found: $id');
      final entity = TaskMapper.taskModelToEntity(model);
      // Reconstruct with isCompleted=false and completedAt=null explicitly.
      final cleared = TaskEntity(
        id: entity.id,
        title: entity.title,
        description: entity.description,
        categoryId: entity.categoryId,
        priority: entity.priority,
        dueDate: entity.dueDate,
        dueTime: entity.dueTime,
        isCompleted: false,
        createdAt: entity.createdAt,
        completedAt: null,
        subTasks: entity.subTasks,
        reminderEnabled: entity.reminderEnabled,
        reminderDateTime: entity.reminderDateTime,
        recurrenceType: entity.recurrenceType,
        notificationId: entity.notificationId,
      );
      await _datasource.updateTask(TaskMapper.taskEntityToModel(cleared));
      return cleared;
    });
  }

  // ── Statistics helper ──────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Map<DateTime, List<TaskEntity>>>>
      getCompletedTasksByDate() async {
    return _tryCatchSync(() {
      final completed = _datasource
          .getCompletedTasks()
          .where((m) => m.completedAt != null)
          .map(TaskMapper.taskModelToEntity)
          .toList();

      final Map<DateTime, List<TaskEntity>> grouped = {};
      for (final task in completed) {
        final day = DateTime(
          task.completedAt!.year,
          task.completedAt!.month,
          task.completedAt!.day,
        );
        grouped.putIfAbsent(day, () => []).add(task);
      }
      return grouped;
    });
  }

  // ── Streams ────────────────────────────────────────────────────────────────

  @override
  Stream<List<TaskEntity>> watchAllTasks() {
    return _datasource.watchAllTasks().map(
          (models) => models.map(TaskMapper.taskModelToEntity).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }
}
