import 'package:hive/hive.dart';
import '../../core/enums/priority_enum.dart';
import '../../core/enums/recurrence_type_enum.dart';
import 'sub_task_model.dart';

part 'task_model.g.dart';

@HiveType(typeId: 4)
class TaskModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final String? categoryId;

  @HiveField(4)
  final Priority priority;

  @HiveField(5)
  final DateTime? dueDate;

  @HiveField(6)
  final TimeOfDay? dueTime;

  @HiveField(7)
  final bool isCompleted;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime? completedAt;

  @HiveField(10)
  final List<SubTaskModel> subTasks;

  @HiveField(11)
  final bool reminderEnabled;

  @HiveField(12)
  final DateTime? reminderDateTime;

  @HiveField(13)
  final RecurrenceType recurrenceType;

  @HiveField(14)
  final int? notificationId;

  TaskModel({
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

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    Priority? priority,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    List<SubTaskModel>? subTasks,
    bool? reminderEnabled,
    DateTime? reminderDateTime,
    RecurrenceType? recurrenceType,
    int? notificationId,
  }) {
    return TaskModel(
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
}

@HiveType(typeId: 5)
class TimeOfDay {
  @HiveField(0)
  final int hour;

  @HiveField(1)
  final int minute;

  TimeOfDay({required this.hour, required this.minute});

  TimeOfDay copyWith({int? hour, int? minute}) {
    return TimeOfDay(
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static TimeOfDay fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  DateTime toDateTime(DateTime date) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
