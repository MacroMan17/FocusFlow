import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/router.dart';
import '../providers/providers.dart';

const _kTeal = Color(0xFF00C896);
const _kBg = Color(0xFF070D1A);
const _kGlass = Color(0x1AFFFFFF);
const _kBorder = Color(0x33FFFFFF);
const _kTextSec = Color(0xFF8899AA);

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
        return SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // "All" chip
              _Chip(
                label: 'All',
                color: _kTeal,
                selected: taskState.categoryFilter == null,
                onTap: () => ref
                    .read(taskListNotifierProvider.notifier)
                    .setCategoryFilter(null),
                showCheck: true,
              ),

              // Category chips
              ...categories.map((cat) {
                final sel = taskState.categoryFilter == cat.id;
                final color = Color(cat.color);
                return Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: _Chip(
                    label: cat.name,
                    color: color,
                    selected: sel,
                    onTap: () => ref
                        .read(taskListNotifierProvider.notifier)
                        .setCategoryFilter(sel ? null : cat.id),
                    dot: true,
                  ),
                );
              }),

              // "+" add category
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  if (context.mounted) {
                    context.goNamed(RouteNames.categories);
                  }
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _kGlass,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(color: _kBorder),
                  ),
                  child:
                      const Icon(Icons.add_rounded, size: 20, color: _kTextSec),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatefulWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool dot;
  final bool showCheck;

  const _Chip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.dot = false,
    this.showCheck = false,
  });

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _scale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
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
    final sel = widget.selected;
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTap: _tap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: sel ? widget.color : _kGlass,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: sel ? widget.color : _kBorder,
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                        color: widget.color.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showCheck && sel) ...[
                Icon(Icons.check_rounded, size: 14, color: _kBg),
                const SizedBox(width: 5),
              ] else if (widget.dot) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: sel ? _kBg : widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                  color: sel ? _kBg : _kTextSec,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
