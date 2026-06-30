import 'dart:math' as math;

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../core/router/router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../widgets/category_filter_chips.dart';
import '../../widgets/quote_card.dart';
import '../../widgets/task_card.dart';
import '../../widgets/task_list_shimmer.dart';
import '../../widgets/task_sort_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen
// Visual hierarchy (spec):
//   1. Greeting (36sp Bold) + date + quick actions
//   2. Quote card
//   3. Progress ring + today stats
//   4. Filter chips (status)
//   5. Category chips
//   6. Task list  ←  or empty state
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ringCtrl;
  late final AnimationController _fabCtrl;
  late final AnimationController _entranceCtrl;
  late final AnimationController _staggerCtrl;

  late final Animation<double> _ringAnim;
  late final Animation<double> _fabScale;

  double _ringTarget = 0.0;

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic);
    _fabScale = CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduce = MediaQuery.of(context).disableAnimations;
      if (reduce) {
        for (final c in [_ringCtrl, _fabCtrl, _entranceCtrl, _staggerCtrl]) {
          c.value = 1.0;
        }
      } else {
        _entranceCtrl.forward();
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted) _ringCtrl.forward();
        });
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) _fabCtrl.forward();
        });
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _staggerCtrl.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _fabCtrl.dispose();
    _entranceCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  void _updateRing(double t) {
    if ((t - _ringTarget).abs() > 0.001) {
      _ringTarget = t;
      _ringCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskListNotifierProvider);
    final tasks = taskState.filteredAndSorted;
    final all = taskState.tasks;
    final todayTotal = all.where((t) => t.isDueToday).length;
    final todayCompleted =
        all.where((t) => t.isDueToday && t.isCompleted).length;
    final ringTarget = todayTotal == 0 ? 0.0 : todayCompleted / todayTotal;

    _updateRing(ringTarget);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: kBg,
          elevation: 0,
          scrolledUnderElevation: 0),
      body: taskState.isLoading
          ? const TaskListShimmer()
          : taskState.error != null
              ? Center(
                  child: Text(taskState.error!,
                      style: const TextStyle(color: kTextSec)))
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── 1. Greeting header ─────────────────────
                    SliverToBoxAdapter(
                      child: _GreetingHeader(
                        todayTotal: todayTotal,
                        todayCompleted: todayCompleted,
                        ringAnim: _ringAnim,
                        entranceCtrl: _entranceCtrl,
                        onSearch: () => context.goNamed(RouteNames.search),
                        onCategories: () =>
                            context.goNamed(RouteNames.categories),
                        onSort: () => TaskSortSheet.show(context),
                      ),
                    ),

                    // ── Gap ────────────────────────────────────
                    const SliverToBoxAdapter(child: SizedBox(height: kSecGap)),

                    // ── 2. Quote card ──────────────────────────
                    const SliverToBoxAdapter(
                        child: RepaintBoundary(child: QuoteCard())),

                    // ── Gap ────────────────────────────────────
                    const SliverToBoxAdapter(child: SizedBox(height: kSecGap)),

                    // ── 3. Filter chips (status) ───────────────
                    SliverToBoxAdapter(child: _StatusFilterRow()),

                    // ── Gap ────────────────────────────────────
                    const SliverToBoxAdapter(child: SizedBox(height: kCardGap)),

                    // ── 4. Category chips ──────────────────────
                    const SliverToBoxAdapter(
                        child: RepaintBoundary(child: CategoryFilterChips())),

                    // ── Gap ────────────────────────────────────
                    const SliverToBoxAdapter(child: SizedBox(height: kSecGap)),

                    // ── Section title ──────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(kPad, 0, kPad, kCardGap),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _sectionTitle(taskState.filter),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: kText,
                                letterSpacing: -0.3,
                              ),
                            ),
                            // Task count badge
                            if (tasks.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: kGlass,
                                  borderRadius: BorderRadius.circular(20),
                                  border: const Border.fromBorderSide(
                                      BorderSide(color: kDivider)),
                                ),
                                child: Text(
                                  '${tasks.length}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: kPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // ── 5. Task list OR empty state ────────────
                    tasks.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: _HomeEmptyState(filter: taskState.filter),
                          )
                        : SliverPadding(
                            padding:
                                const EdgeInsets.fromLTRB(kPad, 0, kPad, 120),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) {
                                  final task = tasks[i];
                                  final start = (i * 55 / 1000).clamp(0.0, 0.9);
                                  final end =
                                      ((i * 55 + 280) / 1000).clamp(0.1, 1.0);
                                  final anim = CurvedAnimation(
                                    parent: _staggerCtrl,
                                    curve: Interval(start, end,
                                        curve: Curves.easeOut),
                                  );
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: kCardGap),
                                    child: FadeTransition(
                                      opacity: anim,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.06),
                                          end: Offset.zero,
                                        ).animate(anim),
                                        child: TaskCard(
                                          key: ValueKey(task.id),
                                          task: task,
                                          onTap: () => context.goNamed(
                                            RouteNames.taskDetail,
                                            pathParameters: {'id': task.id},
                                          ),
                                          onCheckboxChanged: (_) async {
                                            HapticFeedback.lightImpact();
                                            await ref
                                                .read(taskListNotifierProvider
                                                    .notifier)
                                                .toggleComplete(
                                                    task.id, task.isCompleted);
                                            if (!task.isCompleted &&
                                                context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                content: const Text(
                                                    'Task completed ✓'),
                                                action: SnackBarAction(
                                                  label: 'Undo',
                                                  onPressed: () => ref
                                                      .read(
                                                          taskListNotifierProvider
                                                              .notifier)
                                                      .toggleComplete(
                                                          task.id, true),
                                                ),
                                                duration:
                                                    const Duration(seconds: 4),
                                              ));
                                            }
                                          },
                                          onDismissed: () async {
                                            await ref
                                                .read(taskListNotifierProvider
                                                    .notifier)
                                                .deleteTask(task.id);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                content: Text('Task deleted'),
                                                duration: Duration(seconds: 3),
                                              ));
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                childCount: tasks.length,
                              ),
                            ),
                          ),
                  ],
                ),

      // ── FAB: 72dp, gradient Purple→Cyan ─────────────────────
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: _GradientFAB(
          onTap: () => context.goNamed(RouteNames.taskAdd),
        ),
      ),
    );
  }

  String _sectionTitle(TaskFilter f) {
    switch (f) {
      case TaskFilter.all:
        return "Today's Tasks";
      case TaskFilter.today:
        return 'Due Today';
      case TaskFilter.upcoming:
        return 'Upcoming';
      case TaskFilter.overdue:
        return 'Overdue';
      case TaskFilter.completed:
        return 'Completed';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting Header — spec hierarchy item 1
// Greeting: 36sp Bold / -0.5 / line-height 42
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  final int todayTotal;
  final int todayCompleted;
  final Animation<double> ringAnim;
  final AnimationController entranceCtrl;
  final VoidCallback onSearch;
  final VoidCallback onCategories;
  final VoidCallback onSort;

  const _GreetingHeader({
    required this.todayTotal,
    required this.todayCompleted,
    required this.ringAnim,
    required this.entranceCtrl,
    required this.onSearch,
    required this.onCategories,
    required this.onSort,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final reduce = MediaQuery.of(context).disableAnimations;
    final fade = CurvedAnimation(
        parent: entranceCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut));

    return Container(
      padding: const EdgeInsets.fromLTRB(kPad, 16, kPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: date + action icons ──────────────────────
          FadeTransition(
            opacity: fade,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Date pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: kGlass,
                    borderRadius: BorderRadius.circular(kChipRadius),
                    border: const Border.fromBorderSide(
                        BorderSide(color: kDivider)),
                  ),
                  child: Text(
                    dateStr,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: kTextSec,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),

                // Action buttons
                Row(
                  children: [
                    _ActionBtn(
                        icon: Icons.search_rounded,
                        tooltip: 'Search',
                        onTap: onSearch),
                    const SizedBox(width: 4),
                    _ActionBtn(
                        icon: Icons.label_outline_rounded,
                        tooltip: 'Categories',
                        onTap: onCategories),
                    const SizedBox(width: 4),
                    _ActionBtn(
                        icon: Icons.sort_rounded,
                        tooltip: 'Sort',
                        onTap: onSort),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Greeting 36sp Bold ────────────────────────────────
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.04, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: entranceCtrl,
                curve: const Interval(0.1, 0.8, curve: Curves.easeOut))),
            child: FadeTransition(
              opacity: fade,
              child: reduce
                  ? Text(
                      '${_greeting()} 👋',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: kText,
                        letterSpacing: -0.5,
                        height: 42 / 36,
                      ),
                    )
                  : DefaultTextStyle(
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: kText,
                        letterSpacing: -0.5,
                        height: 42 / 36,
                      ),
                      child: AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            '${_greeting()} 👋',
                            speed: const Duration(milliseconds: 52),
                          ),
                        ],
                        totalRepeatCount: 1,
                        displayFullTextOnTap: true,
                        stopPauseOnTap: true,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Progress ring + stats row ─────────────────────────
          FadeTransition(
            opacity: CurvedAnimation(
                parent: entranceCtrl,
                curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
            child: _ProgressRow(
              ringAnim: ringAnim,
              todayCompleted: todayCompleted,
              todayTotal: todayTotal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress ring + stats row
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  final Animation<double> ringAnim;
  final int todayCompleted;
  final int todayTotal;

  const _ProgressRow({
    required this.ringAnim,
    required this.todayCompleted,
    required this.todayTotal,
  });

  @override
  Widget build(BuildContext context) {
    final progress = todayTotal == 0 ? 0.0 : todayCompleted / todayTotal;

    return Container(
      padding: const EdgeInsets.all(kCardPad),
      decoration: BoxDecoration(
        color: kGlass,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: const Border.fromBorderSide(BorderSide(color: kDivider)),
      ),
      child: Row(
        children: [
          // ── Animated ring ────────────────────────────────────
          AnimatedBuilder(
            animation: ringAnim,
            builder: (_, __) => _RingWidget(
              animatedProgress: ringAnim.value * progress,
              completed: todayCompleted,
              total: todayTotal,
            ),
          ),

          const SizedBox(width: 20),

          // ── Stats ────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: kDivider,
                    valueColor: const AlwaysStoppedAnimation(kPrimary),
                  ),
                ),
                const SizedBox(height: 12),

                // Numbers row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatChip(
                        value: todayCompleted,
                        label: 'Done',
                        color: kCompleted),
                    _StatChip(
                        value: todayTotal - todayCompleted,
                        label: 'Left',
                        color: kWarning),
                    _StatChip(
                        value: todayTotal, label: 'Total', color: kPrimary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 32sp Bold statistics number
        Text(
          '$value',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        // 15sp Medium label
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: kTextSec,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ring widget with CustomPainter
// ─────────────────────────────────────────────────────────────────────────────

class _RingWidget extends StatelessWidget {
  final double animatedProgress;
  final int completed;
  final int total;

  const _RingWidget({
    required this.animatedProgress,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _RingPainter(progress: animatedProgress),
          ),
          Center(
            child: total == 0
                ? const Icon(Icons.check_circle_outline_rounded,
                    color: kPrimary, size: 28)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$completed',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                          height: 1,
                        ),
                      ),
                      Text(
                        'of $total',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: kTextSec,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - 7) / 2;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    // Track
    p.color = kDivider;
    canvas.drawCircle(c, r, p);

    if (progress > 0) {
      // Glow pass
      p.color = kPrimary.withValues(alpha: 0.3);
      p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2,
          2 * math.pi * progress, false, p);

      // Solid pass
      p.color = kPrimary;
      p.maskFilter = null;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2,
          2 * math.pi * progress, false, p);
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Action button (top-right icons)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: kGlass,
            borderRadius: BorderRadius.circular(14),
            border: const Border.fromBorderSide(BorderSide(color: kDivider)),
          ),
          child: Icon(icon, size: 20, color: kTextSec),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status filter row
// ─────────────────────────────────────────────────────────────────────────────

class _StatusFilterRow extends ConsumerWidget {
  const _StatusFilterRow();

  static const _items = [
    (TaskFilter.all, Icons.checklist_rounded, 'All'),
    (TaskFilter.today, Icons.wb_sunny_rounded, 'Today'),
    (TaskFilter.upcoming, Icons.upcoming_rounded, 'Upcoming'),
    (TaskFilter.overdue, Icons.warning_amber_rounded, 'Overdue'),
    (TaskFilter.completed, Icons.check_circle_rounded, 'Done'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(taskListNotifierProvider.select((s) => s.filter));

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: kPad),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final (filter, icon, label) = _items[i];
          final sel = current == filter;
          return _SpringFilterChip(
            icon: icon,
            label: label,
            selected: sel,
            onTap: () =>
                ref.read(taskListNotifierProvider.notifier).setFilter(filter),
          );
        },
      ),
    );
  }
}

class _SpringFilterChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SpringFilterChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SpringFilterChip> createState() => _SpringFilterChipState();
}

class _SpringFilterChipState extends State<_SpringFilterChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
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
          duration: const Duration(milliseconds: 220),
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: sel
                ? const LinearGradient(
                    colors: [Color(0x336C63FF), Color(0x1A00E5FF)],
                  )
                : null,
            color: sel ? null : kGlass,
            borderRadius: BorderRadius.circular(kChipRadius),
            border: Border.all(
              color: sel ? kPrimary.withValues(alpha: 0.5) : kDivider,
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                        color: kPrimary.withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: sel ? kPrimary : kTextSec),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                  color: sel ? kPrimary : kTextSec,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient FAB — 72dp, Purple→Cyan, outer glow
// ─────────────────────────────────────────────────────────────────────────────

class _GradientFAB extends StatelessWidget {
  final VoidCallback onTap;
  const _GradientFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [kPrimary, kAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withValues(alpha: 0.45),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: kAccent.withValues(alpha: 0.2),
              blurRadius: 35,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, size: 34, color: kText),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Empty State — Lottie + float
// ─────────────────────────────────────────────────────────────────────────────

class _HomeEmptyState extends StatefulWidget {
  final TaskFilter filter;
  const _HomeEmptyState({required this.filter});

  @override
  State<_HomeEmptyState> createState() => _HomeEmptyStateState();
}

class _HomeEmptyStateState extends State<_HomeEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !MediaQuery.of(context).disableAnimations) {
        _float.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = switch (widget.filter) {
      TaskFilter.all => (
          "You're all clear! 🌟",
          "Add something to tackle today."
        ),
      TaskFilter.today => ("Nothing due today ☀️", "Enjoy the breathing room."),
      TaskFilter.upcoming => (
          "Nothing scheduled ahead 🗓️",
          "A clear horizon awaits."
        ),
      TaskFilter.overdue => (
          "You're on top of everything! 🎉",
          "No overdue tasks. Great work."
        ),
      TaskFilter.completed => (
          "Nothing completed yet ✅",
          "Finish some tasks to see them here."
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kPad),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie with float
          AnimatedBuilder(
            animation: _float,
            builder: (_, child) => Transform.translate(
              offset: Offset(
                  0,
                  Tween<double>(begin: -8.0, end: 8.0).evaluate(CurvedAnimation(
                      parent: _float, curve: Curves.easeInOut))),
              child: child,
            ),
            child: Lottie.asset(
              'assets/lottie/empty_tasks.json',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              repeat: true,
              errorBuilder: (_, __, ___) => Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0x336C63FF), Color(0x1A00E5FF)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: kDivider),
                ),
                child: const Icon(Icons.task_alt_rounded,
                    size: 52, color: kPrimary),
              ),
            ),
          ),

          const SizedBox(height: 28),

          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: kText,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: kTextGap),

          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: kTextSec,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
