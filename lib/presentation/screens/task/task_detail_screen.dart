import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/router/router.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/task_entity.dart';
import '../../../domain/usecases/task/get_filtered_tasks_use_case.dart';
import '../../providers/providers.dart';
import '../../widgets/category_chip_widget.dart';
import '../../widgets/priority_badge.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  TaskEntity? _task;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await ref
        .read(getTaskByIdUseCaseProvider)(GetTaskByIdParams(id: widget.taskId));
    result.fold(
      (f) {
        if (mounted) setState(() => _isLoading = false);
        _snack(f.message, isError: true);
      },
      (task) {
        if (mounted) setState(() { _task = task; _isLoading = false; });
      },
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
    ));
  }

  Future<void> _toggleComplete() async {
    if (_task == null) return;
    final notifier = ref.read(taskListNotifierProvider.notifier);
    await notifier.toggleComplete(_task!.id, _task!.isCompleted);
    await _load();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await ref.read(deleteTaskUseCaseProvider)(widget.taskId);
    result.fold(
      (f) => _snack(f.message, isError: true),
      (_) async {
        if (_task?.notificationId != null) {
          await NotificationService.instance
              .cancelNotification(_task!.notificationId!);
        }
        ref.read(taskListNotifierProvider.notifier).load();
        if (mounted) context.pop();
      },
    );
  }

  Future<void> _toggleSubTask(int index) async {
    if (_task == null) return;
    final updated = List.from(_task!.subTasks);
    updated[index] = updated[index].copyWith(
      isCompleted: !updated[index].isCompleted,
      completedAt: !updated[index].isCompleted ? DateTime.now() : null,
    );
    final updatedTask = _task!.copyWith(subTasks: List.from(updated));
    final result = await ref.read(updateTaskUseCaseProvider)(updatedTask);
    result.fold(
      (f) => _snack(f.message, isError: true),
      (t) {
        ref.read(taskListNotifierProvider.notifier).load();
        if (mounted) setState(() => _task = t);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Task not found')),
      );
    }

    final task = _task!;
    final categories = ref.watch(categoryListNotifierProvider)
        .maybeWhen(data: (c) => c, orElse: () => <CategoryEntity>[]);
    final category = task.categoryId != null
        ? categories.where((c) => c.id == task.categoryId).firstOrNull
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit',
            onPressed: () async {
              await context.pushNamed(
                RouteNames.taskEdit,
                pathParameters: {'id': task.id},
              );
              _load();
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_rounded, color: cs.error),
            tooltip: 'Delete',
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header card ────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: tt.headlineSmall?.copyWith(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted
                                ? cs.onSurface.withValues(alpha: 0.4)
                                : null,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(task.description!,
                        style: tt.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Meta row ───────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  if (category != null)
                    _MetaTile(
                      icon: Icons.label_rounded,
                      label: 'Category',
                      trailing: CategoryChip(category: category),
                    ),
                  _MetaTile(
                    icon: Icons.flag_rounded,
                    label: 'Priority',
                    trailing: PriorityBadge(priority: task.priority),
                  ),
                  if (task.dueDate != null)
                    _MetaTile(
                      icon: Icons.calendar_today_rounded,
                      label: 'Due Date',
                      trailing: Text(
                        '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'
                        '${task.dueTime != null ? '  ${task.dueTime!.hour.toString().padLeft(2, '0')}:${task.dueTime!.minute.toString().padLeft(2, '0')}' : ''}',
                        style: TextStyle(
                          color: task.isOverdue ? cs.error : null,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  if (task.reminderEnabled && task.reminderDateTime != null)
                    _MetaTile(
                      icon: Icons.notifications_rounded,
                      label: 'Reminder',
                      trailing: Text(
                        '${task.reminderDateTime!.day}/${task.reminderDateTime!.month}/${task.reminderDateTime!.year} '
                        '${task.reminderDateTime!.hour.toString().padLeft(2, '0')}:${task.reminderDateTime!.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  _MetaTile(
                    icon: Icons.access_time_rounded,
                    label: 'Created',
                    trailing: Text(
                      '${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Sub-tasks ──────────────────────────────────────────────────
          if (task.subTasks.isNotEmpty) ...[
            Text('Sub-tasks (${task.completedSubTaskCount}/${task.totalSubTaskCount})',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: task.subTasks.asMap().entries.map((e) {
                  final st = e.value;
                  return CheckboxListTile(
                    value: st.isCompleted,
                    onChanged: (_) => _toggleSubTask(e.key),
                    title: Text(
                      st.title,
                      style: TextStyle(
                        fontSize: 14,
                        decoration: st.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: st.isCompleted
                            ? cs.onSurface.withValues(alpha: 0.4)
                            : null,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Complete button ────────────────────────────────────────────
          FilledButton.icon(
            onPressed: _toggleComplete,
            icon: Icon(task.isCompleted
                ? Icons.undo_rounded
                : Icons.check_circle_rounded),
            label: Text(
                task.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
            style: FilledButton.styleFrom(
              backgroundColor:
                  task.isCompleted ? cs.surfaceContainerHighest : cs.primary,
              foregroundColor:
                  task.isCompleted ? cs.onSurface : cs.onPrimary,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  const _MetaTile(
      {required this.icon, required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: cs.primary),
      title: Text(label,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      trailing: trailing,
    );
  }
}
