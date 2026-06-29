import 'package:dartz/dartz.dart';
import '../../../core/enums/priority_enum.dart';
import '../../../core/enums/recurrence_type_enum.dart';
import '../../../core/utils/failure.dart';
import '../../entities/sub_task_entity.dart';
import '../../entities/task_entity.dart';
import '../../repositories/task_repository.dart';
import '../use_case.dart';

class CreateTaskUseCase implements UseCase<TaskEntity, CreateTaskParams> {
  final TaskRepository _repository;

  CreateTaskUseCase(this._repository);

  @override
  Future<Either<Failure, TaskEntity>> call(CreateTaskParams params) {
    if (params.title.trim().isEmpty) {
      return Future.value(
          const Left(ValidationFailure('Task title cannot be empty.')));
    }

    final task = TaskEntity(
      id: params.id,
      title: params.title.trim(),
      description: params.description?.trim(),
      categoryId: params.categoryId,
      priority: params.priority,
      dueDate: params.dueDate,
      dueTime: params.dueTime,
      isCompleted: false,
      createdAt: DateTime.now(),
      completedAt: null,
      subTasks: params.subTasks,
      reminderEnabled: params.reminderEnabled,
      reminderDateTime: params.reminderDateTime,
      recurrenceType: params.recurrenceType,
      notificationId: params.notificationId,
    );

    return _repository.createTask(task);
  }
}

class CreateTaskParams {
  final String id;
  final String title;
  final String? description;
  final String? categoryId;
  final Priority priority;
  final DateTime? dueDate;
  final TaskTimeOfDay? dueTime;
  final List<SubTaskEntity> subTasks;
  final bool reminderEnabled;
  final DateTime? reminderDateTime;
  final RecurrenceType recurrenceType;
  final int? notificationId;

  const CreateTaskParams({
    required this.id,
    required this.title,
    this.description,
    this.categoryId,
    this.priority = Priority.none,
    this.dueDate,
    this.dueTime,
    this.subTasks = const [],
    this.reminderEnabled = false,
    this.reminderDateTime,
    this.recurrenceType = RecurrenceType.none,
    this.notificationId,
  });
}
