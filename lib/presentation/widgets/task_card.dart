import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/enums/priority_enum.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../providers/providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Task Card
// Spec: height 88–96dp, border-radius 24dp, glass card, 26dp checkbox
// ─────────────────────────────────────────────────────────────────────────────

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
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onCheck(bool? v) {
    HapticFeedback.lightImpact();
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onCheckboxChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListNotifierProvider).maybeWhen(
          data: (c) => c,
          orElse: () => <CategoryEntity>[],
        );
    final category = widget.task.categoryId != null
        ? categories.where((c) => c.id == widget.task.categoryId).firstOrNull
        : null;

    final isOverdue = widget.task.isOverdue;
    final isDone = widget.task.isCompleted;
    final borderColor =
        isOverdue && !isDone ? kOverdue.withValues(alpha: 0.4) : kDivider;

    Widget card = AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: Container(
        constraints: const BoxConstraints(minHeight: 88, maxHeight: 96),
        decoration: BoxDecoration(
          color: kGlass,
          borderRadius: BorderRadius.circular(kCardRadius),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(kCardRadius),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(kCardRadius),
            splashColor: kPrimary.withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: kCardPad, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Checkbox 26dp ────────────────────────────
                  _Checkbox(
                    value: isDone,
                    onChanged: _onCheck,
                    label: widget.task.title,
                  ),
                  const SizedBox(width: 14),

                  // ── Content ──────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title — 18sp Medium
                        Text(
                          widget.task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: isDone
                                ? kTextSec.withValues(alpha: 0.5)
                                : isOverdue
                                    ? kOverdue
                                    : kText,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                            decorationColor: kTextSec,
                          ),
                        ),

                        // Description — 15sp Regular
                        if (widget.task.description != null &&
                            widget.task.description!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            widget.task.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: kTextSec,
                            ),
                          ),
                        ],

                        // Sub-task progress
                        if (widget.task.subTasks.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          _SubTaskBar(task: widget.task),
                        ],

                        const SizedBox(height: 6),

                        // Meta row: priority + date + category
                        Row(
                          children: [
                            _PriorityBadge(priority: widget.task.priority),
                            if (widget.task.dueDate != null) ...[
                              const SizedBox(width: 8),
                              _DateBadge(task: widget.task),
                            ],
                            if (category != null) ...[
                              const SizedBox(width: 8),
                              _CategoryPill(category: category),
                            ],
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
      ),
    );

    if (widget.onDismissed != null) {
      card = Dismissible(
        key: ValueKey(widget.task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: kCardPad),
          decoration: BoxDecoration(
            color: kOverdue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(kCardRadius),
            border: Border.all(color: kOverdue.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.delete_rounded, color: kOverdue, size: 24),
        ),
        onDismissed: (_) => widget.onDismissed!(),
        child: card,
      );
    }

    return card;
  }
}

// ── Custom checkbox 26dp ──────────────────────────────────────────────────────

class _Checkbox extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool?> onChanged;

  const _Checkbox({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: value ? 'Mark $label incomplete' : 'Mark $label complete',
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: value ? kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: value ? kPrimary : kTextSec.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: value
              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

// ── Priority badge 26dp ───────────────────────────────────────────────────────

class _PriorityBadge extends StatelessWidget {
  final Priority priority;
  const _PriorityBadge({required this.priority});

  Color get _color {
    switch (priority) {
      case Priority.high:
        return kOverdue;
      case Priority.medium:
        return kWarning;
      case Priority.low:
        return kAccent;
      case Priority.none:
        return kTextSec;
    }
  }

  String get _label {
    switch (priority) {
      case Priority.high:
        return '● High';
      case Priority.medium:
        return '● Med';
      case Priority.low:
        return '● Low';
      case Priority.none:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (priority == Priority.none) return const SizedBox.shrink();
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(kChipRadius),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      alignment: Alignment.center,
      child: Text(
        _label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Date badge ────────────────────────────────────────────────────────────────

class _DateBadge extends StatelessWidget {
  final TaskEntity task;
  const _DateBadge({required this.task});

  @override
  Widget build(BuildContext context) {
    final isOverdue = task.isOverdue;
    final isToday = task.isDueToday;
    final color = isOverdue
        ? kOverdue
        : isToday
            ? kPrimary
            : kTextSec;
    final label =
        isToday ? 'Today' : '${task.dueDate!.day}/${task.dueDate!.month}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Category pill 30dp ────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  final CategoryEntity category;
  const _CategoryPill({required this.category});

  @override
  Widget build(BuildContext context) {
    final color = Color(category.color);
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(kChipRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            category.name,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-task progress bar ─────────────────────────────────────────────────────

class _SubTaskBar extends StatelessWidget {
  final TaskEntity task;
  const _SubTaskBar({required this.task});

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
              minHeight: 3,
              backgroundColor: kDivider,
              valueColor: const AlwaysStoppedAnimation(kPrimary),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$done/$total',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: kTextSec,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
