import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/router/router.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/task_entity.dart';
import '../../providers/providers.dart';
import '../../widgets/category_chip_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/priority_badge.dart';

// ── Provider: tasks keyed by date ─────────────────────────────────────────

final _tasksByDateProvider =
    Provider<Map<DateTime, List<TaskEntity>>>((ref) {
  final tasks = ref.watch(taskListNotifierProvider).tasks;
  final map   = <DateTime, List<TaskEntity>>{};
  for (final t in tasks) {
    if (t.dueDate != null) {
      final key = _dayKey(t.dueDate!);
      map.putIfAbsent(key, () => []).add(t);
    }
  }
  return map;
});

DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

// ── Screen ────────────────────────────────────────────────────────────────

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime  _focusedDay  = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final cs         = Theme.of(context).colorScheme;
    final tasksByDay = ref.watch(_tasksByDateProvider);
    final selected   = _selectedDay ?? _focusedDay;
    final dayTasks   = tasksByDay[_dayKey(selected)] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          // ── Calendar ──────────────────────────────────────────────────
          TableCalendar<TaskEntity>(
            firstDay:      DateTime(2020),
            lastDay:       DateTime(2100),
            focusedDay:    _focusedDay,
            selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
            eventLoader:   (day) => tasksByDay[_dayKey(day)] ?? [],
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color:        cs.primaryContainer,
                shape:        BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color:        cs.onPrimaryContainer,
                fontWeight:   FontWeight.w700,
              ),
              selectedDecoration: BoxDecoration(
                color:  cs.primary,
                shape:  BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(color: cs.onPrimary),
              markerDecoration: BoxDecoration(
                color:  cs.primary,
                shape:  BoxShape.circle,
              ),
              markerSize:        6,
              markersMaxCount:   3,
              outsideDaysVisible: false,
              weekendTextStyle:
                  TextStyle(color: cs.onSurfaceVariant),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible:  false,
              titleCentered:        true,
              titleTextStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize:   16,
              ),
              leftChevronIcon:
                  Icon(Icons.chevron_left_rounded, color: cs.primary),
              rightChevronIcon:
                  Icon(Icons.chevron_right_rounded, color: cs.primary),
            ),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay  = selected;
                _focusedDay   = focused;
              });
            },
            onPageChanged: (focused) =>
                setState(() => _focusedDay = focused),
          ),

          const Divider(height: 1),

          // ── Day task list ─────────────────────────────────────────────
          Expanded(
            child: dayTasks.isEmpty
                ? const EmptyState(
                    icon:     Icons.event_available_rounded,
                    title:    'No tasks on this day',
                    subtitle: 'Tap + on the Home screen to add a task with this date.',
                  )
                : _DayTaskList(tasks: dayTasks),
          ),
        ],
      ),
    );
  }
}

// ── Day task list ─────────────────────────────────────────────────────────

class _DayTaskList extends ConsumerWidget {
  final List<TaskEntity> tasks;
  const _DayTaskList({required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs         = Theme.of(context).colorScheme;
    final categories = ref.watch(categoryListNotifierProvider)
        .maybeWhen(data: (c) => c, orElse: () => <CategoryEntity>[]);

    return ListView.separated(
      padding:         const EdgeInsets.all(16),
      itemCount:       tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final task     = tasks[i];
        final category = task.categoryId != null
            ? categories.where((c) => c.id == task.categoryId).firstOrNull
            : null;
        final isOverdue = task.isOverdue;

        return Card(
          child: ListTile(
            leading: Checkbox(
              value:     task.isCompleted,
              onChanged: (_) => ref
                  .read(taskListNotifierProvider.notifier)
                  .toggleComplete(task.id, task.isCompleted),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                color: task.isCompleted
                    ? cs.onSurface.withValues(alpha: 0.4)
                    : isOverdue
                        ? cs.error
                        : null,
              ),
            ),
            subtitle: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PriorityBadge(priority: task.priority, compact: true),
                if (category != null) ...[
                  const SizedBox(width: 6),
                  CategoryChip(category: category, compact: true),
                ],
              ],
            ),
            trailing: isOverdue && !task.isCompleted
                ? Icon(Icons.warning_amber_rounded,
                    color: cs.error, size: 18)
                : null,
            onTap: () => context.goNamed(
              RouteNames.taskDetail,
              pathParameters: {'id': task.id},
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }
}
