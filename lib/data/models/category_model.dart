import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 3)
class CategoryModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int color;

  @HiveField(3)
  final String icon;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final bool isDefault;

  CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.createdAt,
    required this.isDefault,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    int? color,
    String? icon,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
