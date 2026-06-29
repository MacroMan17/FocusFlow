import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/hive_constants.dart';
import '../models/task_model.dart';

/// Handles all raw Hive read/write/delete operations for [TaskModel].
/// No domain logic here — only persistence.
class TaskLocalDatasource {
  Box<TaskModel> get _box => Hive.box<TaskModel>(HiveConstants.taskBox);

  /// Returns all tasks as an unordered list.
  List<TaskModel> getAllTasks() {
    return _box.values.toList();
  }

  /// Returns the task with [id], or null if not found.
  TaskModel? getTaskById(String id) {
    return _box.get(id);
  }

  /// Returns all tasks whose categoryId matches [categoryId].
  List<TaskModel> getTasksByCategory(String categoryId) {
    return _box.values.where((t) => t.categoryId == categoryId).toList();
  }

  /// Returns all tasks whose dueDate matches the given [date] (year/month/day).
  List<TaskModel> getTasksByDate(DateTime date) {
    return _box.values.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == date.year &&
          t.dueDate!.month == date.month &&
          t.dueDate!.day == date.day;
    }).toList();
  }

  /// Returns all incomplete tasks whose dueDate is before today.
  List<TaskModel> getOverdueTasks() {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return _box.values.where((t) {
      if (t.isCompleted || t.dueDate == null) return false;
      final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return due.isBefore(startOfToday);
    }).toList();
  }

  /// Returns all incomplete tasks whose dueDate is today.
  List<TaskModel> getTodayTasks() {
    final now = DateTime.now();
    return _box.values.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == now.year &&
          t.dueDate!.month == now.month &&
          t.dueDate!.day == now.day;
    }).toList();
  }

  /// Returns all incomplete tasks whose dueDate is strictly after today.
  List<TaskModel> getUpcomingTasks() {
    final today = DateTime.now();
    final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59);
    return _box.values.where((t) {
      if (t.isCompleted || t.dueDate == null) return false;
      return t.dueDate!.isAfter(endOfToday);
    }).toList();
  }

  /// Returns all completed tasks.
  List<TaskModel> getCompletedTasks() {
    return _box.values.where((t) => t.isCompleted).toList();
  }

  /// Case-insensitive search across title and description.
  List<TaskModel> searchTasks(String query) {
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) return [];
    return _box.values.where((t) {
      final titleMatch = t.title.toLowerCase().contains(lower);
      final descMatch = t.description?.toLowerCase().contains(lower) ?? false;
      return titleMatch || descMatch;
    }).toList();
  }

  /// Saves a new task. Uses task.id as the Hive key.
  Future<void> saveTask(TaskModel task) async {
    await _box.put(task.id, task);
  }

  /// Overwrites an existing task by id.
  Future<void> updateTask(TaskModel task) async {
    await _box.put(task.id, task);
  }

  /// Deletes the task with [id]. No-op if not found.
  Future<void> deleteTask(String id) async {
    await _box.delete(id);
  }

  /// Deletes all tasks whose categoryId matches [categoryId].
  Future<void> deleteTasksByCategory(String categoryId) async {
    final toDelete = _box.values
        .where((t) => t.categoryId == categoryId)
        .map((t) => t.id)
        .toList();
    await _box.deleteAll(toDelete);
  }

  /// Sets categoryId to null for all tasks belonging to [categoryId].
  Future<void> unassignTasksFromCategory(String categoryId) async {
    final tasks = _box.values.where((t) => t.categoryId == categoryId).toList();
    for (final task in tasks) {
      await _box.put(task.id, task.copyWith(categoryId: null));
    }
  }

  /// Deletes all tasks. Used by Reset All Data.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Stream that emits the full task list whenever the box changes.
  Stream<List<TaskModel>> watchAllTasks() {
    return _box.watch().map((_) => _box.values.toList());
  }

  /// Returns true if the box is open and ready.
  bool get isOpen => _box.isOpen;
}
