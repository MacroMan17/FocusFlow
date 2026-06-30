import 'dart:math' as math;

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../core/router/router.dart';
import '../../providers/providers.dart';
import '../../widgets/category_filter_chips.dart';
import '../../widgets/quote_card.dart';
import '../../widgets/task_card.dart';
import '../../widgets/task_list_shimmer.dart';
import '../../widgets/task_sort_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Jungle / Screenshot-match color tokens
// ─────────────────────────────────────────────────────────────────────────────
const _kBg = Color(0xFF070D1A); // near-black bg
const _kBg2 = Color(0xFF0D1628); // card bg
const _kGlass = Color(0x1AFFFFFF); // glass surface
const _kTeal = Color(0xFF00C896); // jungle teal / primary green
const _kTealDim = Color(0x2600C896); // teal 15% fill
const _kPurple = Color(0xFF7C4DFF); // "All Tasks" card
const _kAmber = Color(0xFFF39C12); // Pending
const _kRed = Color(0xFFFF5C7A); // Overdue
const _kGreen = Color(0xFF2ECC71); // Completed
const _kText = Color(0xFFFFFFFF);
const _kTextSec = Color(0xFF8899AA);
const _kDivider = Color(0x18FFFFFF);
const _kBorder = Color(0x33FFFFFF);

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
        vsync: this, duration: const Duration(milliseconds: 600));

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
    final total = all.length;
    final completed = all.where((t) => t.isCompleted).length;
    final pending = all.where((t) => !t.isCompleted).length;
    final overdue = all.where((t) => t.isOverdue).length;
    final ringTarget = total == 0 ? 0.0 : completed / total;

    _updateRing(ringTarget);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: _kBg,
          elevation: 0,
          scrolledUnderElevation: 0),
      body: taskState.isLoading
          ? const TaskListShimmer()
          : taskState.error != null
              ? Center(
                  child: Text(taskState.error!,
                      style: const TextStyle(color: _kTextSec)))
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── HEADER: date + greeting + ring ─────────
                    SliverToBoxAdapter(
                      child: _Header(
                        total: total,
                        completedCount: completed,
                        ringAnim: _ringAnim,
                        entranceCtrl: _entranceCtrl,
                        onSearch: () => context.goNamed(RouteNames.search),
                        onCategories: () =>
                            context.goNamed(RouteNames.categories),
                        onSort: () => TaskSortSheet.show(context),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // ── QUOTE CARD ─────────────────────────────
                    const SliverToBoxAdapter(
                        child: RepaintBoundary(child: QuoteCard())),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // ── STAT CARDS ROW ─────────────────────────
                    SliverToBoxAdapter(
                      child: _StatCardsRow(
                        total: total,
                        completed: completed,
                        pending: pending,
                        overdue: overdue,
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // ── FILTER BY STATUS ───────────────────────
                    SliverToBoxAdapter(
                      child: _SectionLabel('FILTER BY STATUS'),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 10)),
                    SliverToBoxAdapter(child: _StatusChips()),

                    const SliverToBoxAdapter(child: SizedBox(height: 18)),

                    // ── FILTER BY CATEGORY ─────────────────────
                    SliverToBoxAdapter(
                      child: _SectionLabel('FILTER BY CATEGORY'),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 10)),
                    const SliverToBoxAdapter(
                        child: RepaintBoundary(child: CategoryFilterChips())),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // ── TASK LIST / EMPTY STATE ────────────────
                    tasks.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyState(filter: taskState.filter),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) {
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
                                    padding: const EdgeInsets.only(bottom: 12),
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
                                          onTap: () => ctx.goNamed(
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
                                                ctx.mounted) {
                                              ScaffoldMessenger.of(ctx)
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
                                            if (ctx.mounted) {
                                              ScaffoldMessenger.of(ctx)
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

      // ── FAB — teal pill matching screenshot ───────────────────
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: _FAB(onTap: () => context.goNamed(RouteNames.taskAdd)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header: date pill + greeting + subtitle + progress ring + actions
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int total;
  final int completedCount;
  final Animation<double> ringAnim;
  final AnimationController entranceCtrl;
  final VoidCallback onSearch;
  final VoidCallback onCategories;
  final VoidCallback onSort;

  const _Header({
    required this.total,
    required this.completedCount,
    required this.ringAnim,
    required this.entranceCtrl,
    required this.onSearch,
    required this.onCategories,
    required this.onSort,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final reduce = MediaQuery.of(context).disableAnimations;
    final fade = CurvedAnimation(
        parent: entranceCtrl,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut));
    final progress = total == 0 ? 0.0 : completedCount / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: FadeTransition(
        opacity: fade,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── LEFT: date + greeting + subtitle + actions ─────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date pill with calendar icon
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _kTealDim,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _kTeal.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 12, color: _kTeal),
                        const SizedBox(width: 5),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kTeal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Greeting line: "Good afternoon, Sumit 👋"
                  // "Good afternoon," in white, name in teal
                  reduce
                      ? _GreetingText(greeting: _greeting())
                      : _TypewriterGreeting(greeting: _greeting()),

                  const SizedBox(height: 8),

                  // Subtitle
                  const Text(
                    "You're all clear! Add something\nto tackle today.",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: _kTextSec,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action buttons row
                  Row(
                    children: [
                      _ActionBtn(icon: Icons.search_rounded, onTap: onSearch),
                      const SizedBox(width: 10),
                      _ActionBtn(
                          icon: Icons.label_outline_rounded,
                          onTap: onCategories),
                      const SizedBox(width: 10),
                      _ActionBtn(icon: Icons.sort_rounded, onTap: onSort),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // ── RIGHT: Progress ring ────────────────────────────
            AnimatedBuilder(
              animation: ringAnim,
              builder: (_, __) => _RingWidget(
                animatedProgress: ringAnim.value * progress,
                completed: completedCount,
                total: total,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingText extends StatelessWidget {
  final String greeting;
  const _GreetingText({required this.greeting});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 26,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        children: [
          TextSpan(text: '$greeting ', style: const TextStyle(color: _kText)),
          const TextSpan(text: 'Sumit ', style: TextStyle(color: _kTeal)),
          const TextSpan(text: '👋', style: TextStyle(color: _kText)),
        ],
      ),
    );
  }
}

class _TypewriterGreeting extends StatelessWidget {
  final String greeting;
  const _TypewriterGreeting({required this.greeting});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: _kText,
        height: 1.2,
      ),
      child: AnimatedTextKit(
        animatedTexts: [
          TypewriterAnimatedText(
            '$greeting Sumit 👋',
            speed: const Duration(milliseconds: 50),
          ),
        ],
        totalRepeatCount: 1,
        displayFullTextOnTap: true,
        stopPauseOnTap: true,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress Ring — teal arc, "X/Y\nTasks Done" center
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
      width: 88,
      height: 88,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _RingPainter(progress: animatedProgress)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                total == 0
                    ? const Icon(Icons.check_rounded, color: _kTeal, size: 28)
                    : Text(
                        '$completed / $total',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kText,
                          height: 1,
                        ),
                      ),
                if (total > 0) ...[
                  const SizedBox(height: 3),
                  const Text(
                    'Tasks Done',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9,
                      color: _kTextSec,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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
    final r = (size.width - 8) / 2;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    p.color = _kTeal.withValues(alpha: 0.18);
    canvas.drawCircle(c, r, p);

    if (progress > 0) {
      p.color = _kTeal.withValues(alpha: 0.3);
      p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2,
          2 * math.pi * progress, false, p);
      p.color = _kTeal;
      p.maskFilter = null;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2,
          2 * math.pi * progress, false, p);
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// 4 Stat Cards Row: All Tasks / Completed / Pending / Overdue
// ─────────────────────────────────────────────────────────────────────────────

class _StatCardsRow extends StatelessWidget {
  final int total, completed, pending, overdue;
  const _StatCardsRow({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
              child: _StatCard(
            icon: Icons.list_alt_rounded,
            value: total,
            label: 'All Tasks',
            color: _kPurple,
          )),
          const SizedBox(width: 10),
          Expanded(
              child: _StatCard(
            icon: Icons.check_circle_rounded,
            value: completed,
            label: 'Completed',
            color: _kGreen,
          )),
          const SizedBox(width: 10),
          Expanded(
              child: _StatCard(
            icon: Icons.access_time_rounded,
            value: pending,
            label: 'Pending',
            color: _kAmber,
          )),
          const SizedBox(width: 10),
          Expanded(
              child: _StatCard(
            icon: Icons.warning_rounded,
            value: overdue,
            label: 'Overdue',
            color: _kRed,
          )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      decoration: BoxDecoration(
        color: _kBg2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),

          const SizedBox(height: 10),

          // Number
          Text(
            '$value',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _kText,
              height: 1,
            ),
          ),

          const SizedBox(height: 4),

          // Label
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _kTextSec,
            ),
          ),

          const SizedBox(height: 12),

          // Bottom color bar
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _kTextSec,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status filter chips
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChips extends ConsumerWidget {
  const _StatusChips();

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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final (filter, icon, label) = _items[i];
          final sel = current == filter;
          return _SpringChip(
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

class _SpringChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SpringChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: sel ? _kTeal : _kGlass,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: sel ? _kTeal : _kBorder,
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                        color: _kTeal.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: sel ? _kBg : _kTextSec),
              const SizedBox(width: 6),
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

// ─────────────────────────────────────────────────────────────────────────────
// Action button
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _kGlass,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Icon(icon, size: 19, color: _kTextSec),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAB — teal pill "  + Add Task"
// ─────────────────────────────────────────────────────────────────────────────

class _FAB extends StatelessWidget {
  final VoidCallback onTap;
  const _FAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: _kTeal,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: _kTeal.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 22, color: _kBg),
            SizedBox(width: 8),
            Text(
              'Add Task',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kBg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State — trophy Lottie + float animation
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatefulWidget {
  final TaskFilter filter;
  const _EmptyState({required this.filter});
  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400));
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
    final (title, sub) = switch (widget.filter) {
      TaskFilter.all => (
          "You're all clear! 🌟",
          "Add something to tackle today\nand keep the streak going."
        ),
      TaskFilter.today => ("Nothing due today ☀️", "Enjoy the breathing room."),
      TaskFilter.upcoming => (
          "Nothing scheduled 🗓️",
          "A clear horizon awaits."
        ),
      TaskFilter.overdue => (
          "You're on top! 🎉",
          "No overdue tasks. Great work."
        ),
      TaskFilter.completed => (
          "Nothing completed yet ✅",
          "Finish some tasks to see them here."
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie with float
          AnimatedBuilder(
            animation: _float,
            builder: (_, child) => Transform.translate(
              offset: Offset(
                  0,
                  Tween<double>(begin: -10.0, end: 10.0).evaluate(
                      CurvedAnimation(
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
                  color: _kTealDim,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kTeal.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    size: 56, color: _kTeal),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _kText,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          Text(
            sub,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: _kTextSec,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
