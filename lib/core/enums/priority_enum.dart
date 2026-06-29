import 'package:hive/hive.dart';

part 'priority_enum.g.dart';

@HiveType(typeId: 0)
enum Priority {
  @HiveField(0)
  none(0, 'None'),
  @HiveField(1)
  low(1, 'Low'),
  @HiveField(2)
  medium(2, 'Medium'),
  @HiveField(3)
  high(3, 'High');

  final int value;
  final String label;

  const Priority(this.value, this.label);

  static Priority fromValue(int value) {
    return Priority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => Priority.none,
    );
  }
}
