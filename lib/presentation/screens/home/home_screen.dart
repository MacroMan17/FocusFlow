import 'dart:math' as math;

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../core/router/router.dart';
import '../../../domain/entities/task_entity.dart';
import '../../providers/providers.dart';
import '../../widgets/category_filter_chips.dart';
import '../../widgets/quote_card.dart';
import '../../widgets/task_card.dart';
import '../../widgets/task_list_shimmer.dart';
import '../../widgets/task_sort_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Teal palette constants (matches teal dark theme)
// ─────────────────────────────────────────────────────────────────────────────
const _kTeal = Color(0xFF00695C); // teal[700]
const _kTeal400 = Color(0xFF26A69A); // teal[400]
const _kTeal200 = Color(0xFF80CBC4); // teal[200]

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen — ConsumerStatefulWidget for AnimationControllers
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ────────────────────────────────────────
  late final AnimationController _ringCtrl; // progress ring draw
  late final AnimationController _fabCtrl; // FAB scale bounce
  late final AnimationController _dateChipCtrl; // date chip slide-in
  late final AnimationController _quoteCtrl; // quote fade+slide
  late final AnimationController _staggerCtrl; // staggered task list

  // ── Derived animations ───────────────────────────────────────────
  late final Animation<double> _ringAnim;
  late final Animation<double> _fabAnim;
  late final Animation<Offset> _dateChipSlide;
  late final Animation<double> _quoteFade;
  late final Animation<Offset> _quoteSlide;

  double _ringTarget = 0.0; // updated when tasks load

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _dateChipCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _quoteCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic);

    _fabAnim = CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut);

    _dateChipSlide = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _dateChipCtrl, curve: Curves.easeOutCubic));

    _quoteFade = CurvedAnimation(parent: _quoteCtrl, curve: Curves.easeOut);
    _quoteSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _quoteCtrl, curve: Curves.easeOut));

    // Fire all entrance animations with staggered delays
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduce = MediaQuery.of(context).disableAnimations;
      if (reduce) {
        // Skip animations for accessibility
        _ringCtrl.value = 1.0;
        _fabCtrl.value = 1.0;
        _dateChipCtrl.value = 1.0;
        _quoteCtrl.value = 1.0;
        _staggerCtrl.value = 1.0;
      } else {
        _dateChipCtrl.forward();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _quoteCtrl.forward();
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _ringCtrl.forward();
        });
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _fabCtrl.forward();
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _staggerCtrl.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _fabCtrl.dispose();
    _dateChipCtrl.dispose();
    _quoteCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  // Re-animate the ring when the target changes
  void _updateRing(double target) {
    if ((target - _ringTarget).abs() > 0.001) {
      _ringTarget = target;
      _ringCtrl
        ..reset()
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskListNotifierProvider);
    final tasks = taskState.filteredAndSorted;
    final allTasks = taskState.tasks;

    final todayTotal = allTasks.where((t) => t.isDueToday).length;
    final todayCompleted =
        allTasks.where((t) => t.isDueToday && t.isCompleted).length;
    final ringTarget = todayTotal == 0 ? 0.0 : todayCompleted / todayTotal;

    // Trigger ring re-draw when progress changes
    _updateRing(ringTarget);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: taskState.isLoading
          ? const TaskListShimmer()
          : taskState.error != null
              ? Center(child: Text(taskState.error!))
              : Column(
                  children: [
                    // ── Hero header ──────────────────────────────
                    _HeroHeader(
                      todayTotal: todayTotal,
                      todayCompleted: todayCompleted,
                      ringAnim: _ringAnim,
                      dateChipSlide: _dateChipSlide,
                      onSearch: () => context.goNamed(RouteNames.search),
                      onCategories: () =>
                          context.goNamed(RouteNames.categories),
                      onSort: () => TaskSortSheet.show(context),
                    ),

                    // ── Quote card ───────────────────────────────
                    FadeTransition(
                      opacity: _quoteFade,
                      child: SlideTransition(
                        position: _quoteSlide,
                        child: const RepaintBoundary(child: QuoteCard()),
                      ),
                    ),

                    // ── Status filter bar ────────────────────────
                    const _FilterBar(),
                    const SizedBox(height: 2),

                    // ── Category chips ───────────────────────────
                    const RepaintBoundary(child: CategoryFilterChips()),
                    const SizedBox(height: 4),

                    // ── Task list / empty state ──────────────────
                    Expanded(
                      child: tasks.isEmpty
                          ? _HomeEmptyState(filter: taskState.filter)
                          : RefreshIndicator(
                              color: _kTeal400,
                              onRefresh: () => ref
                                  .read(taskListNotifierProvider.notifier)
                                  .load(),
                              child: _StaggeredTaskList(
                                tasks: tasks,
                                staggerCtrl: _staggerCtrl,
                                onToggle: (task) async {
                                  HapticFeedback.lightImpact();
                                  await ref
                                      .read(taskListNotifierProvider.notifier)
                                      .toggleComplete(
                                          task.id, task.isCompleted);
                                  if (!task.isCompleted && context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: const Text('Task completed ✓'),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () => ref
                                            .read(taskListNotifierProvider
                                                .notifier)
                                            .toggleComplete(task.id, true),
                                      ),
                                      duration: const Duration(seconds: 4),
                                    ));
                                  }
                                },
                                onDelete: (task) async {
                                  await ref
                                      .read(taskListNotifierProvider.notifier)
                                      .deleteTask(task.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text('Task deleted'),
                                      duration: Duration(seconds: 3),
                                    ));
                                  }
                                },
                                onTap: (task) => context.goNamed(
                                  RouteNames.taskDetail,
                                  pathParameters: {'id': task.id},
                                ),
                              ),
                            ),
                    ),
                  ],
                ),

      // ── FAB with bounce entrance ──────────────────────────────
      floatingActionButton: ScaleTransition(
        scale: _fabAnim,
        child: FloatingActionButton.extended(
          onPressed: () => context.goNamed(RouteNames.taskAdd),
          backgroundColor: _kTeal,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Task',
              style: TextStyle(fontWeight: FontWeight.w700)),
          elevation: 4,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Header
// ─────────────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final int todayTotal;
  final int todayCompleted;
  final Animation<double> ringAnim;
  final Animation<Offset> dateChipSlide;
  final VoidCallback onSearch;
  final VoidCallback onCategories;
  final VoidCallback onSort;

  const _HeroHeader({
    required this.todayTotal,
    required this.todayCompleted,
    required this.ringAnim,
    required this.dateChipSlide,
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dateStr = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final reduce = MediaQuery.of(context).disableAnimations;

    return Container(
      // Teal → transparent top gradient
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0x2200695C), // teal[700] at ~13% opacity
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left: date chip + typewriter greeting + progress bar ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date chip — slides in from left
                SlideTransition(
                  position: dateChipSlide,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _kTeal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _kTeal400.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      dateStr,
                      style: tt.labelSmall?.copyWith(
                        color: _kTeal400,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 7),

                // Typewriter greeting (first load only, no repeat)
                reduce
                    ? Text(
                        '${_greeting()} 👋',
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      )
                    : DefaultTextStyle(
                        style: tt.headlineSmall!.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                        child: AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              '${_greeting()} 👋',
                              speed: const Duration(milliseconds: 58),
                            ),
                          ],
                          totalRepeatCount: 1,
                          displayFullTextOnTap: true,
                          stopPauseOnTap: true,
                        ),
                      ),

                const SizedBox(height: 10),

                // Progress bar or tagline
                if (todayTotal > 0) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: todayTotal == 0
                                ? 0
                                : todayCompleted / todayTotal,
                            minHeight: 6,
                            backgroundColor: cs.surfaceContainerHighest,
                            valueColor: const AlwaysStoppedAnimation(_kTeal400),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$todayCompleted/$todayTotal today',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    "You're all clear! Add something to tackle today.",
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Right: animated ring + action icons ───────────────
          Column(
            children: [
              AnimatedBuilder(
                animation: ringAnim,
                builder: (_, __) => _ProgressRing(
                  animatedProgress: ringAnim.value *
                      (todayTotal == 0 ? 0.0 : todayCompleted / todayTotal),
                  completed: todayCompleted,
                  total: todayTotal,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SmallIconBtn(icon: Icons.search_rounded, onTap: onSearch),
                  _SmallIconBtn(
                      icon: Icons.label_outline_rounded, onTap: onCategories),
                  _SmallIconBtn(icon: Icons.sort_rounded, onTap: onSort),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Progress Ring
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressRing extends StatelessWidget {
  final double
      animatedProgress; // 0.0 → actual value, driven by AnimationController
  final int completed;
  final int total;

  const _ProgressRing({
    required this.animatedProgress,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _RingPainter(
              progress: animatedProgress,
              trackColor: cs.surfaceContainerHighest,
              fillColor: _kTeal400,
              strokeWidth: 6,
            ),
          ),
          Center(
            child: total == 0
                ? const Icon(Icons.check_circle_outline_rounded,
                    color: _kTeal200, size: 26)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$completed',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _kTeal400,
                          height: 1,
                        ),
                      ),
                      Text(
                        'of $total',
                        style: TextStyle(
                          fontSize: 9,
                          color: cs.onSurfaceVariant,
                          height: 1.2,
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
  final Color trackColor;
  final Color fillColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - strokeWidth) / 2;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    p.color = trackColor;
    canvas.drawCircle(c, r, p);

    if (progress > 0) {
      p.color = fillColor;
      // Glow effect for the arc
      p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        p,
      );
      // Crisp arc on top
      p.maskFilter = null;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.fillColor != fillColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// Small icon button helper
// ─────────────────────────────────────────────────────────────────────────────

class _SmallIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SmallIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onTap,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.all(6),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Empty State — Lottie + float loop
// ─────────────────────────────────────────────────────────────────────────────

class _HomeEmptyState extends StatefulWidget {
  final TaskFilter filter;

  const _HomeEmptyState({required this.filter});

  @override
  State<_HomeEmptyState> createState() => _HomeEmptyStateState();
}

class _HomeEmptyStateState extends State<_HomeEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!MediaQuery.of(context).disableAnimations) {
        _floatCtrl.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final (title, subtitle) = switch (widget.filter) {
      TaskFilter.all => (
          "You're all clear! 🌟",
          "Add something to tackle today."
        ),
      TaskFilter.today => (
          "Nothing due today ☀️",
          "Enjoy the breathing room — or plan ahead."
        ),
      TaskFilter.upcoming => (
          "Nothing scheduled ahead 🗓️",
          "No upcoming tasks yet. A clear horizon!"
        ),
      TaskFilter.overdue => (
          "You're on top of everything! 🎉",
          "No overdue tasks. Great job keeping up."
        ),
      TaskFilter.completed => (
          "Nothing completed yet ✅",
          "Finish some tasks and they'll show up here."
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Lottie animation with float loop ──────────────
            AnimatedBuilder(
              animation: _floatAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: child,
              ),
              child: Lottie.asset(
                'assets/lottie/empty_tasks.json',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                repeat: true,
                errorBuilder: (_, __, ___) => Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _kTeal.withValues(alpha: 0.3),
                        _kTeal400.withValues(alpha: 0.15)
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.task_alt_rounded,
                      size: 52, color: _kTeal400),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Title ──────────────────────────────────────────
            Text(
              title,
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            // ── Subtitle ───────────────────────────────────────
            Text(
              subtitle,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Staggered Task List
// ─────────────────────────────────────────────────────────────────────────────

class _StaggeredTaskList extends StatelessWidget {
  final List<TaskEntity> tasks;
  final AnimationController staggerCtrl;
  final ValueChanged<TaskEntity> onToggle;
  final ValueChanged<TaskEntity> onDelete;
  final ValueChanged<TaskEntity> onTap;

  const _StaggeredTaskList({
    required this.tasks,
    required this.staggerCtrl,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const staggerMs = 60;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final task = tasks[i];
        // Clamp interval end to 1.0
        final start = (i * staggerMs / 1000).clamp(0.0, 0.9);
        final end = ((i * staggerMs + 300) / 1000).clamp(0.1, 1.0);

        final itemAnim = CurvedAnimation(
          parent: staggerCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        );
        final slideAnim = Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(itemAnim);

        return FadeTransition(
          opacity: itemAnim,
          child: SlideTransition(
            position: slideAnim,
            child: TaskCard(
              key: ValueKey(task.id),
              task: task,
              onTap: () => onTap(task),
              onCheckboxChanged: (_) => onToggle(task),
              onDismissed: () => onDelete(task),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bar — icon+label chips with spring tap animation
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  static const _filters = [
    (TaskFilter.all, Icons.checklist_rounded, 'All'),
    (TaskFilter.today, Icons.wb_sunny_rounded, 'Today'),
    (TaskFilter.upcoming, Icons.upcoming_rounded, 'Upcoming'),
    (TaskFilter.overdue, Icons.warning_amber_rounded, 'Overdue'),
    (TaskFilter.completed, Icons.check_circle_rounded, 'Done'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final current = ref.watch(
      taskListNotifierProvider.select((s) => s.filter),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 0, 6),
          child: Text(
            'FILTER BY STATUS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontSize: 10,
                ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final (filter, icon, label) = _filters[i];
              final selected = current == filter;
              return _SpringChip(
                icon: icon,
                label: label,
                selected: selected,
                onTap: () => ref
                    .read(taskListNotifierProvider.notifier)
                    .setFilter(filter),
                selectedColor: _kTeal,
                selectedOnColor: Colors.white,
                unselectedColor: cs.surfaceContainerHighest,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spring-animated chip
// ─────────────────────────────────────────────────────────────────────────────

class _SpringChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color selectedOnColor;
  final Color unselectedColor;

  const _SpringChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedColor,
    required this.selectedOnColor,
    required this.unselectedColor,
  });

  @override
  State<_SpringChip> createState() => _SpringChipState();
}

class _SpringChipState extends State<_SpringChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (MediaQuery.of(context).disableAnimations) {
      widget.onTap();
      return;
    }
    await _ctrl.forward();
    _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.selected
        ? widget.selectedOnColor
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                widget.selected ? widget.selectedColor : widget.unselectedColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: _kTeal.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: textColor),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight:
                      widget.selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
