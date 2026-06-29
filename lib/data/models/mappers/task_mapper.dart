import '../../../domain/entities/sub_task_entity.dart';
import '../../../domain/entities/task_entity.dart';
import '../sub_task_model.dart';
import '../task_model.dart';

/// Bidirectional mapper between [TaskModel] / [SubTaskModel]
/// and their corresponding domain entities.
class TaskMapper {
  TaskMapper._();

  // ── SubTask ────────────────────────────────────────────────────────────────

  static SubTaskEntity subTaskModelToEntity(SubTaskModel model) {
    return SubTaskEntity(
      id: model.id,
      title: model.title,
      isCompleted: model.isCompleted,
      createdAt: model.createdAt,
      completedAt: model.completedAt,
      order: model.order,
    );
  }

  static SubTaskModel subTaskEntityToModel(SubTaskEntity entity) {
    return SubTaskModel(
      id: entity.id,
      title: entity.title,
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
      completedAt: entity.completedAt,
      order: entity.order,
    );
  }

  // ── Task ───────────────────────────────────────────────────────────────────

  static TaskEntity taskModelToEntity(TaskModel model) {
    return TaskEntity(
      id: model.id,
      title: model.title,
      description: model.description,
      categoryId: model.categoryId,
      priority: model.priority,
      dueDate: model.dueDate,
      dueTime: model.dueTime == null
          ? null
          : TaskTimeOfDay(
              hour: model.dueTime!.hour,
              minute: model.dueTime!.minute,
            ),
      isCompleted: model.isCompleted,
      createdAt: model.createdAt,
      completedAt: model.completedAt,
      subTasks: model.subTasks.map((s) => subTaskModelToEntity(s)).toList(),
      reminderEnabled: model.reminderEnabled,
      reminderDateTime: model.reminderDateTime,
      recurrenceType: model.recurrenceType,
      notificationId: model.notificationId,
    );
  }

  static TaskModel taskEntityToModel(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      categoryId: entity.categoryId,
      priority: entity.priority,
      dueDate: entity.dueDate,
      dueTime: entity.dueTime == null
          ? null
          : TimeOfDay(
              hour: entity.dueTime!.hour,
              minute: entity.dueTime!.minute,
            ),
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
      completedAt: entity.completedAt,
      subTasks: entity.subTasks.map((s) => subTaskEntityToModel(s)).toList(),
      reminderEnabled: entity.reminderEnabled,
      reminderDateTime: entity.reminderDateTime,
      recurrenceType: entity.recurrenceType,
      notificationId: entity.notificationId,
    );
  }
}
