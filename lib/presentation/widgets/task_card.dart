import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/providers.dart';
import 'category_chip_widget.dart';
import 'priority_badge.dart';

class TaskCard extends ConsumerStatefulWidget {
  final TaskEntity task;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onCheckboxChanged;
  final VoidCallback? onDismissed;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onCheckboxChanged,
    this.onDismissed,
  });

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>    _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.94), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onCheck(bool? v) {
    HapticFeedback.lightImpact();
    _ctrl.forward(from: 0);
    widget.onCheckboxChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final categories = ref.watch(categoryListNotifierProvider).maybeWhen(
          data: (cats) => cats,
          orElse: () => <CategoryEntity>[],
        );
    final category = widget.task.categoryId != null
        ? categories.where((c) => c.id == widget.task.categoryId).firstOrNull
        : null;

    final isOverdue = widget.task.isOverdue;
    final titleStyle = tt.bodyLarge?.copyWith(
      decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
      color: widget.task.isCompleted
          ? cs.onSurface.withValues(alpha: 0.4)
          : isOverdue
              ? cs.error
              : cs.onSurface,
      fontWeight: FontWeight.w500,
    );

    Widget card = ScaleTransition(
      scale: _scale,
      child: Card(
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24, height: 24,
                  child: Semantics(
                    label: widget.task.isCompleted
                        ? 'Mark ${widget.task.title} incomplete'
                        : 'Mark ${widget.task.title} complete',
                    child: Checkbox(
                      value:     widget.task.isCompleted,
                      onChanged: _onCheck,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                      side: BorderSide(
                        color: widget.task.isCompleted
                            ? cs.primary
                            : cs.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(widget.task.title,
                          style: titleStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (widget.task.description != null &&
                          widget.task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.task.description!,
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      if (widget.task.subTasks.isNotEmpty) ...[
                        _SubTaskProgress(task: widget.task, cs: cs),
                        const SizedBox(height: 6),
                      ],
                      Wrap(
                        spacing: 6, runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          PriorityBadge(
                              priority: widget.task.priority, compact: true),
                          if (widget.task.dueDate != null)
                            _DueDateChip(task: widget.task, cs: cs),
                          if (category != null)
                            CategoryChip(category: category, compact: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.onDismissed != null) {
      card = Dismissible(
        key:       ValueKey(widget.task.id),
        direction: DismissDirection.endToStart,
        background: _DismissBackground(cs: cs),
        onDismissed: (_) => widget.onDismissed!(),
        child: card,
      );
    }

    return card;
  }
}

class _DismissBackground extends StatelessWidget {
  final ColorScheme cs;
  const _DismissBackground({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.delete_rounded, color: cs.onErrorContainer),
    );
  }
}

class _DueDateChip extends StatelessWidget {
  final TaskEntity task;
  final ColorScheme cs;
  const _DueDateChip({required this.task, required this.cs});

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue;
    final isToday = task.isDueToday;
    final color = isOverdue
        ? cs.error
        : isToday
            ? cs.primary
            : cs.onSurfaceVariant;

    String label;
    if (isToday) {
      label = 'Today';
    } else if (task.dueDate != null) {
      final d = task.dueDate!;
      label = '${d.day}/${d.month}/${d.year}';
    } else {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 12, color: color),
        const SizedBox(width: 2),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SubTaskProgress extends StatelessWidget {
  final TaskEntity task;
  final ColorScheme cs;
  const _SubTaskProgress({required this.task, required this.cs});

  @override
  Widget build(BuildContext context) {
    final done = task.subTasks.where((s) => s.isCompleted).length;
    final total = task.subTasks.length;
    final progress = total == 0 ? 0.0 : done / total;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$done/$total',
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
