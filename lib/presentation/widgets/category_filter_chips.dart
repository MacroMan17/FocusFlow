import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Category filter chips
// Spec: height 42dp, horizontal padding 18dp, radius 20dp, 14sp Medium
// ─────────────────────────────────────────────────────────────────────────────

class CategoryFilterChips extends ConsumerWidget {
  const CategoryFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListNotifierProvider);
    final taskState = ref.watch(taskListNotifierProvider);

    return categoriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: kPad),
            itemCount: categories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              if (i == 0) {
                final sel = taskState.categoryFilter == null;
                return _FilterChip(
                  label: 'All',
                  color: kPrimary,
                  selected: sel,
                  onTap: () => ref
                      .read(taskListNotifierProvider.notifier)
                      .setCategoryFilter(null),
                );
              }
              final cat = categories[i - 1];
              final sel = taskState.categoryFilter == cat.id;
              return _FilterChip(
                label: cat.name,
                color: Color(cat.color),
                selected: sel,
                onTap: () => ref
                    .read(taskListNotifierProvider.notifier)
                    .setCategoryFilter(sel ? null : cat.id),
                dot: true,
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single chip with spring press animation
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatefulWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool dot;

  const _FilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.dot = false,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (!MediaQuery.of(context).disableAnimations) {
      await _ctrl.forward();
      _ctrl.reverse();
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTap: _tap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: widget.selected ? c.withValues(alpha: 0.18) : kGlass,
            borderRadius: BorderRadius.circular(kChipRadius),
            border: Border.all(
              color: widget.selected ? c.withValues(alpha: 0.55) : kDivider,
              width: 1,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: c.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.dot) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight:
                      widget.selected ? FontWeight.w600 : FontWeight.w500,
                  color: widget.selected ? c : kTextSec,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
