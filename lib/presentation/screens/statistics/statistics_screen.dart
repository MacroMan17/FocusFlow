import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/statistics_entity.dart';
import '../../providers/providers.dart';
import '../../widgets/empty_state.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statisticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (stats) {
          if (stats.totalCreated == 0) {
            return const EmptyState(
              icon:     Icons.bar_chart_rounded,
              title:    'No data yet',
              subtitle: 'Complete some tasks to see your productivity stats here.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StreakRow(stats: stats),
              const SizedBox(height: 16),
              _SummaryRow(stats: stats),
              const SizedBox(height: 16),
              _WeeklyCompletionCard(stats: stats),
              const SizedBox(height: 16),
              _BarChartCard(stats: stats),
              const SizedBox(height: 16),
              if (stats.categoryDistribution.isNotEmpty) ...[
                _CategoryDonutCard(stats: stats),
                const SizedBox(height: 16),
              ],
              if (stats.mostProductiveDay != null)
                _ProductiveDayCard(day: stats.mostProductiveDay!),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}

// ── Streak row ─────────────────────────────────────────────────────────────

class _StreakRow extends StatelessWidget {
  final StatisticsEntity stats;
  const _StreakRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StreakCard(
          label:  'Current Streak',
          value:  stats.currentStreak,
          icon:   Icons.local_fire_department_rounded,
          color:  Colors.deepOrange,
        )),
        const SizedBox(width: 12),
        Expanded(child: _StreakCard(
          label:  'Best Streak',
          value:  stats.bestStreak,
          icon:   Icons.emoji_events_rounded,
          color:  Colors.amber,
        )),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  final String  label;
  final int     value;
  final IconData icon;
  final Color   color;
  const _StreakCard({required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color:      cs.primary,
              ),
            ),
            Text(
              '$label\n${value == 1 ? 'day' : 'days'}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary row ────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final StatisticsEntity stats;
  const _SummaryRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryChip(
            label: 'Created',   value: stats.totalCreated,   color: Colors.blue)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryChip(
            label: 'Done',      value: stats.totalCompleted, color: Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryChip(
            label: 'Pending',   value: stats.totalPending,   color: Colors.orange)),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int    value;
  final Color  color;
  const _SummaryChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ── Weekly completion card ─────────────────────────────────────────────────

class _WeeklyCompletionCard extends StatelessWidget {
  final StatisticsEntity stats;
  const _WeeklyCompletionCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final pct     = stats.weeklyCompletionRate;
    final pctStr  = '${pct.toStringAsFixed(0)}%';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('This Week',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(pctStr,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.primary)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value:           pct / 100,
                minHeight:       12,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor:      AlwaysStoppedAnimation(cs.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${stats.totalCompleted} of ${stats.totalCreated} tasks completed',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 7-day bar chart ────────────────────────────────────────────────────────

class _BarChartCard extends StatelessWidget {
  final StatisticsEntity stats;
  const _BarChartCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final daily  = stats.dailyCompletions;
    final maxY   = (daily.map((d) => d.count).fold(0, (a, b) => a > b ? a : b) + 1)
        .toDouble();
    final dayLabels = ['', 'M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last 7 Days',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY:          maxY,
                  gridData:      FlGridData(
                    show:                true,
                    drawVerticalLine:    false,
                    horizontalInterval:  1,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color:       cs.outlineVariant.withValues(alpha: 0.4),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData:    FlBorderData(show: false),
                  titlesData:    FlTitlesData(
                    leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles:   true,
                        reservedSize: 28,
                        getTitlesWidget: (v, meta) {
                          final d = daily[v.toInt()].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              dayLabels[d.weekday],
                              style: TextStyle(
                                  fontSize: 11,
                                  color:    cs.onSurfaceVariant),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: daily.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY:             e.value.count.toDouble(),
                          color:           e.value.count > 0
                              ? cs.primary
                              : cs.surfaceContainerHighest,
                          width:           22,
                          borderRadius:    const BorderRadius.vertical(
                              top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category donut chart ───────────────────────────────────────────────────

class _CategoryDonutCard extends ConsumerWidget {
  final StatisticsEntity stats;
  const _CategoryDonutCard({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs         = Theme.of(context).colorScheme;
    final categories = ref.watch(categoryListNotifierProvider)
        .maybeWhen(data: (c) => c, orElse: () => []);
    final dist       = stats.categoryDistribution;
    final total      = dist.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final sections = dist.entries.map((e) {
      final cat   = categories.where((c) => c.id == e.key).firstOrNull;
      final color = cat != null ? Color(cat.color) : cs.primary;
      final pct   = e.value / total * 100;
      return PieChartSectionData(
        value:         e.value.toDouble(),
        color:         color,
        title:         '${pct.toStringAsFixed(0)}%',
        radius:        55,
        titleStyle:    const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('By Category',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(PieChartData(
                      sections:         sections,
                      centerSpaceRadius: 40,
                      sectionsSpace:    3,
                    )),
                  ),
                  const SizedBox(width: 16),
                  // Legend
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dist.entries.map((e) {
                      final cat   = categories
                          .where((c) => c.id == e.key)
                          .firstOrNull;
                      final color = cat != null
                          ? Color(cat.color)
                          : cs.primary;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat?.name ?? 'Unknown',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Most productive day ────────────────────────────────────────────────────

class _ProductiveDayCard extends StatelessWidget {
  final String day;
  const _ProductiveDayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 28),
        title: const Text('Most Productive Day',
            style: TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(
          day,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color:      cs.primary),
        ),
      ),
    );
  }
}
