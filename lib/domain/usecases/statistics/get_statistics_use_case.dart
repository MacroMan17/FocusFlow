import 'package:dartz/dartz.dart';

import '../../../core/utils/failure.dart';
import '../../entities/statistics_entity.dart';
import '../../entities/task_entity.dart';
import '../../repositories/task_repository.dart';
import '../use_case.dart';

class GetStatisticsUseCase implements NoParamsUseCase<StatisticsEntity> {
  final TaskRepository _repository;
  GetStatisticsUseCase(this._repository);

  @override
  Future<Either<Failure, StatisticsEntity>> call() async {
    final result = await _repository.getAllTasks();
    return result.fold(Left.new, (tasks) => Right(_compute(tasks)));
  }

  StatisticsEntity _compute(List<TaskEntity> tasks) {
    final now   = DateTime.now();
    final today = _day(now);

    // ── Basic counts ──────────────────────────────────────────────────────
    final completed = tasks.where((t) => t.isCompleted).toList();
    final pending   = tasks.where((t) => !t.isCompleted).toList();

    // ── Weekly completion rate ─────────────────────────────────────────────
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final createdThisWeek =
        tasks.where((t) => !t.createdAt.isBefore(weekStart)).length;
    final completedThisWeek = completed
        .where((t) =>
            t.completedAt != null && !t.completedAt!.isBefore(weekStart))
        .length;
    final weeklyRate = createdThisWeek == 0
        ? 0.0
        : (completedThisWeek / createdThisWeek * 100).clamp(0, 100).toDouble();

    // ── Last 7 days bar chart data ────────────────────────────────────────
    final daily = List.generate(7, (i) {
      final date  = today.subtract(Duration(days: 6 - i));
      final count = completed
          .where((t) =>
              t.completedAt != null && _day(t.completedAt!) == date)
          .length;
      return DailyCompletion(date: date, count: count);
    });

    // ── Streak calculation ────────────────────────────────────────────────
    // Build a Set of dates on which ≥1 task was completed.
    final completionDays = completed
        .where((t) => t.completedAt != null)
        .map((t) => _day(t.completedAt!))
        .toSet();

    int currentStreak = 0;
    int bestStreak    = 0;
    int runStreak     = 0;

    // Walk backwards from today to calculate current streak.
    for (int i = 0; i < 365; i++) {
      final d = today.subtract(Duration(days: i));
      if (completionDays.contains(d)) {
        currentStreak++;
      } else {
        break; // gap found — streak broken
      }
    }

    // Walk all unique completion days sorted ascending for best streak.
    final sortedDays = completionDays.toList()..sort();
    for (int i = 0; i < sortedDays.length; i++) {
      if (i == 0) {
        runStreak = 1;
      } else {
        final prev = sortedDays[i - 1];
        final curr = sortedDays[i];
        if (curr.difference(prev).inDays == 1) {
          runStreak++;
        } else {
          runStreak = 1;
        }
      }
      if (runStreak > bestStreak) bestStreak = runStreak;
    }

    // ── Category distribution ─────────────────────────────────────────────
    final catDist = <String, int>{};
    for (final t in tasks) {
      if (t.categoryId != null) {
        catDist[t.categoryId!] = (catDist[t.categoryId!] ?? 0) + 1;
      }
    }

    // ── Most productive day of week ───────────────────────────────────────
    final weekdayCount = List.filled(8, 0); // index 1=Mon … 7=Sun
    for (final t in completed) {
      if (t.completedAt != null) {
        weekdayCount[t.completedAt!.weekday]++;
      }
    }
    int maxIdx = 0;
    int maxVal = 0;
    for (int i = 1; i <= 7; i++) {
      if (weekdayCount[i] > maxVal) { maxVal = weekdayCount[i]; maxIdx = i; }
    }
    final dayNames = ['', 'Monday', 'Tuesday', 'Wednesday',
                       'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final productiveDay = maxIdx > 0 ? dayNames[maxIdx] : null;

    return StatisticsEntity(
      totalCreated:         tasks.length,
      totalCompleted:       completed.length,
      totalPending:         pending.length,
      currentStreak:        currentStreak,
      bestStreak:           bestStreak,
      weeklyCompletionRate: weeklyRate,
      dailyCompletions:     daily,
      categoryDistribution: catDist,
      mostProductiveDay:    productiveDay,
    );
  }

  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}
