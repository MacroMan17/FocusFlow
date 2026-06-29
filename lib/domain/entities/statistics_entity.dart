class StatisticsEntity {
  final int totalCreated;
  final int totalCompleted;
  final int totalPending;
  final int currentStreak;
  final int bestStreak;
  final double weeklyCompletionRate;
  final List<DailyCompletion> dailyCompletions; // last 7 days
  final Map<String, int> categoryDistribution;  // categoryId -> count
  final String? mostProductiveDay;              // e.g. "Monday"

  const StatisticsEntity({
    required this.totalCreated,
    required this.totalCompleted,
    required this.totalPending,
    required this.currentStreak,
    required this.bestStreak,
    required this.weeklyCompletionRate,
    required this.dailyCompletions,
    required this.categoryDistribution,
    this.mostProductiveDay,
  });

  static const empty = StatisticsEntity(
    totalCreated:        0,
    totalCompleted:      0,
    totalPending:        0,
    currentStreak:       0,
    bestStreak:          0,
    weeklyCompletionRate: 0,
    dailyCompletions:    [],
    categoryDistribution: {},
  );
}

class DailyCompletion {
  final DateTime date;
  final int      count;
  const DailyCompletion({required this.date, required this.count});
}
