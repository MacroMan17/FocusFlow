import 'package:dartz/dartz.dart';
import '../../core/utils/failure.dart';
import '../entities/task_entity.dart';

/// Abstract contract for all task persistence operations.
/// Implementations live in data/repositories/.
abstract class TaskRepository {
  /// Returns all tasks ordered by createdAt descending.
  Future<Either<Failure, List<TaskEntity>>> getAllTasks();

  /// Returns a single task by [id].
  /// Returns [NotFoundFailure] if no task with that id exists.
  Future<Either<Failure, TaskEntity>> getTaskById(String id);

  /// Returns all tasks belonging to [categoryId].
  Future<Either<Failure, List<TaskEntity>>> getTasksByCategory(
      String categoryId);

  /// Returns all tasks whose dueDate falls on [date] (year/month/day match).
  Future<Either<Failure, List<TaskEntity>>> getTasksByDate(DateTime date);

  /// Returns all incomplete tasks whose dueDate is strictly before today.
  Future<Either<Failure, List<TaskEntity>>> getOverdueTasks();

  /// Returns all incomplete tasks whose dueDate is today.
  Future<Either<Failure, List<TaskEntity>>> getTodayTasks();

  /// Returns all incomplete tasks whose dueDate is after today.
  Future<Either<Failure, List<TaskEntity>>> getUpcomingTasks();

  /// Returns all completed tasks.
  Future<Either<Failure, List<TaskEntity>>> getCompletedTasks();

  /// Full-text search across title and description (case-insensitive).
  Future<Either<Failure, List<TaskEntity>>> searchTasks(String query);

  /// Persists a new task. Returns the saved entity on success.
  Future<Either<Failure, TaskEntity>> createTask(TaskEntity task);

  /// Overwrites an existing task by id. Returns the updated entity.
  /// Returns [NotFoundFailure] if no task with that id exists.
  Future<Either<Failure, TaskEntity>> updateTask(TaskEntity task);

  /// Removes a task permanently by [id].
  /// Returns [NotFoundFailure] if no task with that id exists.
  Future<Either<Failure, Unit>> deleteTask(String id);

  /// Sets isCompleted = true and records completedAt = now.
  /// Returns [NotFoundFailure] if no task with that id exists.
  Future<Either<Failure, TaskEntity>> completeTask(String id);

  /// Sets isCompleted = false and clears completedAt.
  /// Returns [NotFoundFailure] if no task with that id exists.
  Future<Either<Failure, TaskEntity>> uncompleteTask(String id);

  /// Returns tasks grouped by completedAt date for streak calculation.
  /// Only returns completed tasks that have a non-null completedAt.
  Future<Either<Failure, Map<DateTime, List<TaskEntity>>>>
      getCompletedTasksByDate();

  /// Watches the task box and emits the full list on every change.
  Stream<List<TaskEntity>> watchAllTasks();
}
