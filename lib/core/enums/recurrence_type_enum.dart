import 'package:hive/hive.dart';

part 'recurrence_type_enum.g.dart';

@HiveType(typeId: 1)
enum RecurrenceType {
  @HiveField(0)
  none(0, 'None'),
  @HiveField(1)
  daily(1, 'Daily'),
  @HiveField(2)
  weekly(2, 'Weekly'),
  @HiveField(3)
  biweekly(3, 'Bi-weekly'),
  @HiveField(4)
  monthly(4, 'Monthly');

  final int value;
  final String label;

  const RecurrenceType(this.value, this.label);

  static RecurrenceType fromValue(int value) {
    return RecurrenceType.values.firstWhere(
      (r) => r.value == value,
      orElse: () => RecurrenceType.none,
    );
  }
}
