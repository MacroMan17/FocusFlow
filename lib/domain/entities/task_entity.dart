import 'package:equatable/equatable.dart';
import '../../core/enums/priority_enum.dart';
import '../../core/enums/recurrence_type_enum.dart';
import 'sub_task_entity.dart';

class TaskEntity extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String? categoryId;
  final Priority priority;
  final DateTime? dueDate;
  final TaskTimeOfDay? dueTime;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<SubTaskEntity> subTasks;
  final bool reminderEnabled;
  final DateTime? reminderDateTime;
  final RecurrenceType recurrenceType;
  final int? notificationId;

  const TaskEntity({
    required this.id,
    required this.title,
    this.description,
    this.categoryId,
    required this.priority,
    this.dueDate,
    this.dueTime,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
    required this.subTasks,
    required this.reminderEnabled,
    this.reminderDateTime,
    required this.recurrenceType,
    this.notificationId,
  });

  /// Whether this task is overdue (past due date and not completed).
  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    final due = dueDate!;
    if (dueTime != null) {
      final dueWithTime = DateTime(
        due.year,
        due.month,
        due.day,
        dueTime!.hour,
        dueTime!.minute,
      );
      return dueWithTime.isBefore(now);
    }
    final endOfDueDay = DateTime(due.year, due.month, due.day, 23, 59, 59);
    return endOfDueDay.isBefore(now);
  }

  /// Whether this task is due today.
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  /// Whether this task is due in the future (after today).
  bool get isUpcoming {
    if (isCompleted || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return due.isAfter(today);
  }

  /// Completed sub-tasks count.
  int get completedSubTaskCount => subTasks.where((s) => s.isCompleted).length;

  /// Total sub-tasks count.
  int get totalSubTaskCount => subTasks.length;

  /// Whether all sub-tasks are complete.
  bool get allSubTasksCompleted =>
      subTasks.isNotEmpty && completedSubTaskCount == totalSubTaskCount;

  TaskEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    Priority? priority,
    DateTime? dueDate,
    TaskTimeOfDay? dueTime,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    List<SubTaskEntity>? subTasks,
    bool? reminderEnabled,
    DateTime? reminderDateTime,
    RecurrenceType? recurrenceType,
    int? notificationId,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      subTasks: subTasks ?? this.subTasks,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDateTime: reminderDateTime ?? this.reminderDateTime,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  /// Creates a copy clearing nullable fields to null.
  TaskEntity clearCategoryId() => copyWith(categoryId: null);
  TaskEntity clearDueDate() => TaskEntity(
        id: id,
        title: title,
        description: description,
        categoryId: categoryId,
        priority: priority,
        dueDate: null,
        dueTime: null,
        isCompleted: isCompleted,
        createdAt: createdAt,
        completedAt: completedAt,
        subTasks: subTasks,
        reminderEnabled: reminderEnabled,
        reminderDateTime: null,
        recurrenceType: recurrenceType,
        notificationId: notificationId,
      );

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        categoryId,
        priority,
        dueDate,
        dueTime,
        isCompleted,
        createdAt,
        completedAt,
        subTasks,
        reminderEnabled,
        reminderDateTime,
        recurrenceType,
        notificationId,
      ];
}

/// Pure Dart time-of-day value used in the domain layer.
/// Mirrors the Hive TimeOfDay model without any storage dependency.
class TaskTimeOfDay extends Equatable {
  final int hour;
  final int minute;

  const TaskTimeOfDay({required this.hour, required this.minute});

  TaskTimeOfDay copyWith({int? hour, int? minute}) =>
      TaskTimeOfDay(hour: hour ?? this.hour, minute: minute ?? this.minute);

  DateTime toDateTime(DateTime date) =>
      DateTime(date.year, date.month, date.day, hour, minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [hour, minute];
}
