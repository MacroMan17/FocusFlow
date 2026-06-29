import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final int color;
  final String icon;
  final DateTime createdAt;
  final bool isDefault;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.createdAt,
    required this.isDefault,
  });

  CategoryEntity copyWith({
    String? id,
    String? name,
    int? color,
    String? icon,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => [id, name, color, icon, createdAt, isDefault];
}
