import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/enums/priority_enum.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/sub_task_entity.dart';
import '../../../domain/entities/task_entity.dart';
import '../../../domain/usecases/task/create_task_use_case.dart';
import '../../../domain/usecases/task/get_filtered_tasks_use_case.dart';
import '../../providers/providers.dart';
import '../../widgets/priority_badge.dart';

class AddEditTaskScreen extends ConsumerStatefulWidget {
  final String? taskId;
  const AddEditTaskScreen({super.key, this.taskId});

  @override
  ConsumerState<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends ConsumerState<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  Priority _priority = Priority.none;
  String? _categoryId;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _reminderEnabled = false;
  DateTime? _reminderDateTime;
  List<SubTaskEntity> _subTasks = [];

  bool _isLoading = false;
  bool _isDirty = false;
  bool _isEditMode = false;
  TaskEntity? _originalTask;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.taskId != null;
    if (_isEditMode) _loadTask();
    _titleCtrl.addListener(() => setState(() => _isDirty = true));
    _descCtrl.addListener(() => setState(() => _isDirty = true));
  }

  Future<void> _loadTask() async {
    final result = await ref.read(getTaskByIdUseCaseProvider)(
      GetTaskByIdParams(id: widget.taskId!),
    );
    result.fold(
      (f) => _showSnack(f.message, isError: true),
      (task) {
        _originalTask = task;
        _titleCtrl.text = task.title;
        _descCtrl.text = task.description ?? '';
        setState(() {
          _priority = task.priority;
          _categoryId = task.categoryId;
          _dueDate = task.dueDate;
          _dueTime = task.dueTime != null
              ? TimeOfDay(
                  hour: task.dueTime!.hour, minute: task.dueTime!.minute)
              : null;
          _reminderEnabled = task.reminderEnabled;
          _reminderDateTime = task.reminderDateTime;
          _subTasks = List.from(task.subTasks);
          _isDirty = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() {
        _dueDate = d;
        _isDirty = true;
      });
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (t != null) {
      setState(() {
        _dueTime = t;
        _isDirty = true;
      });
    }
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderDateTime != null
          ? TimeOfDay.fromDateTime(_reminderDateTime!)
          : TimeOfDay.now(),
    );
    if (time == null) return;
    final dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (dt.isBefore(DateTime.now())) {
      _showSnack('Reminder must be in the future', isError: true);
      return;
    }
    setState(() {
      _reminderDateTime = dt;
      _isDirty = true;
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
    ));
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your unsaved changes will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep editing')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Discard')),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    TaskTimeOfDay? taskTime;
    if (_dueTime != null) {
      taskTime = TaskTimeOfDay(hour: _dueTime!.hour, minute: _dueTime!.minute);
    }

    try {
      if (_isEditMode && _originalTask != null) {
        // Cancel old notification before saving
        if (_originalTask!.notificationId != null) {
          await NotificationService.instance
              .cancelNotification(_originalTask!.notificationId!);
        }

        final notifId = _reminderEnabled && _reminderDateTime != null
            ? NotificationService.idFromTaskId(_originalTask!.id)
            : null;

        final updated = _originalTask!.copyWith(
          title: _titleCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          priority: _priority,
          categoryId: _categoryId,
          dueDate: _dueDate,
          dueTime: taskTime,
          reminderEnabled: _reminderEnabled,
          reminderDateTime: _reminderEnabled ? _reminderDateTime : null,
          notificationId: notifId,
          subTasks: _subTasks,
        );
        final result = await ref.read(updateTaskUseCaseProvider)(updated);
        result.fold(
          (f) => _showSnack(f.message, isError: true),
          (_) async {
            // Schedule new notification if needed
            if (_reminderEnabled &&
                _reminderDateTime != null &&
                notifId != null) {
              await NotificationService.instance.scheduleNotification(
                id: notifId,
                title: '⏰ ${_titleCtrl.text.trim()}',
                body: 'Your task reminder is due now.',
                scheduledDate: _reminderDateTime!,
                payload: _originalTask!.id,
              );
            }
            ref.read(taskListNotifierProvider.notifier).load();
            if (mounted) context.pop();
          },
        );
      } else {
        final newId = const Uuid().v4();
        final notifId = _reminderEnabled && _reminderDateTime != null
            ? NotificationService.idFromTaskId(newId)
            : null;

        final params = CreateTaskParams(
          id: newId,
          title: _titleCtrl.text.trim(),
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          priority: _priority,
          categoryId: _categoryId,
          dueDate: _dueDate,
          dueTime: taskTime,
          reminderEnabled: _reminderEnabled,
          reminderDateTime: _reminderEnabled ? _reminderDateTime : null,
          notificationId: notifId,
          subTasks: _subTasks,
        );
        final result = await ref.read(createTaskUseCaseProvider)(params);
        result.fold(
          (f) => _showSnack(f.message, isError: true),
          (_) async {
            if (_reminderEnabled &&
                _reminderDateTime != null &&
                notifId != null) {
              await NotificationService.instance.scheduleNotification(
                id: notifId,
                title: '⏰ ${_titleCtrl.text.trim()}',
                body: 'Your task reminder is due now.',
                scheduledDate: _reminderDateTime!,
                payload: newId,
              );
            }
            ref.read(taskListNotifierProvider.notifier).load();
            if (mounted) context.pop();
          },
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categories = ref
        .watch(categoryListNotifierProvider)
        .maybeWhen(data: (c) => c, orElse: () => <CategoryEntity>[]);

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final should = await _onWillPop();
          if (should && mounted) context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? 'Edit Task' : 'New Task'),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else
              TextButton(
                onPressed: _save,
                child: const Text('Save',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Title ───────────────────────────────────────────────────
              TextFormField(
                controller: _titleCtrl,
                autofocus: !_isEditMode,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Task title *',
                  hintText: 'What do you need to do?',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
                maxLength: 200,
              ),
              const SizedBox(height: 12),

              // ── Description ─────────────────────────────────────────────
              TextFormField(
                controller: _descCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add more details...',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 2000,
              ),
              const SizedBox(height: 16),

              // ── Priority ─────────────────────────────────────────────────
              const _SectionLabel('Priority'),
              const SizedBox(height: 8),
              Row(
                children: Priority.values.map((p) {
                  final selected = _priority == p;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PriorityBadge(priority: p, compact: true),
                            const SizedBox(width: 4),
                            Text(p.name, style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          _priority = p;
                          _isDirty = true;
                        }),
                        selectedColor: cs.primaryContainer,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ── Category ─────────────────────────────────────────────────
              if (categories.isNotEmpty) ...[
                const _SectionLabel('Category'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    hintText: 'No category',
                    prefixIcon: Icon(Icons.label_outline_rounded),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('No category')),
                    ...categories.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                    color: Color(c.color),
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(c.name),
                            ],
                          ),
                        )),
                  ],
                  onChanged: (v) => setState(() {
                    _categoryId = v;
                    _isDirty = true;
                  }),
                ),
                const SizedBox(height: 16),
              ],

              // ── Due date & time ───────────────────────────────────────────
              const _SectionLabel('Due Date & Time'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(_dueDate == null
                          ? 'Pick date'
                          : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time_rounded, size: 18),
                      label: Text(_dueTime == null
                          ? 'Pick time'
                          : _dueTime!.format(context)),
                      onPressed: _pickTime,
                    ),
                  ),
                  if (_dueDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      tooltip: 'Clear date',
                      onPressed: () => setState(() {
                        _dueDate = null;
                        _dueTime = null;
                        _isDirty = true;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Reminder ─────────────────────────────────────────────────
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Set Reminder'),
                        subtitle: _reminderEnabled && _reminderDateTime != null
                            ? Text(
                                'Remind at ${_reminderDateTime!.day}/${_reminderDateTime!.month}/${_reminderDateTime!.year} '
                                '${_reminderDateTime!.hour.toString().padLeft(2, '0')}:${_reminderDateTime!.minute.toString().padLeft(2, '0')}',
                                style:
                                    TextStyle(fontSize: 12, color: cs.primary),
                              )
                            : const Text('No reminder set'),
                        value: _reminderEnabled,
                        onChanged: (v) {
                          setState(() {
                            _reminderEnabled = v;
                            _isDirty = true;
                          });
                          if (v) _pickReminder();
                        },
                      ),
                      if (_reminderEnabled)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_notifications_rounded,
                              color: cs.primary),
                          title: const Text('Change reminder time'),
                          onTap: _pickReminder,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Sub-tasks ─────────────────────────────────────────────────
              _SubTaskEditor(
                subTasks: _subTasks,
                onChanged: (updated) => setState(() {
                  _subTasks = updated;
                  _isDirty = true;
                }),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      );
}

// ── Sub-task editor ───────────────────────────────────────────────────────

class _SubTaskEditor extends StatefulWidget {
  final List<SubTaskEntity> subTasks;
  final ValueChanged<List<SubTaskEntity>> onChanged;
  const _SubTaskEditor({required this.subTasks, required this.onChanged});

  @override
  State<_SubTaskEditor> createState() => _SubTaskEditorState();
}

class _SubTaskEditorState extends State<_SubTaskEditor> {
  final _ctrl = TextEditingController();

  void _add() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final updated = [
      ...widget.subTasks,
      SubTaskEntity(
        id: const Uuid().v4(),
        title: text,
        isCompleted: false,
        createdAt: DateTime.now(),
        order: widget.subTasks.length,
      ),
    ];
    _ctrl.clear();
    widget.onChanged(updated);
  }

  void _delete(int i) {
    final updated = List<SubTaskEntity>.from(widget.subTasks)..removeAt(i);
    widget.onChanged(updated);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Sub-tasks (${widget.subTasks.length})'),
        const SizedBox(height: 8),
        ...widget.subTasks.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.drag_handle_rounded, color: cs.outlineVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(e.value.title,
                        style: const TextStyle(fontSize: 14)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => _delete(e.key),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            )),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Add a sub-task…',
                  isDense: true,
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.add_rounded),
              onPressed: _add,
              tooltip: 'Add sub-task',
            ),
          ],
        ),
      ],
    );
  }
}
