import '../../../domain/entities/category_entity.dart';
import '../category_model.dart';

/// Bidirectional mapper between [CategoryModel] and [CategoryEntity].
class CategoryMapper {
  CategoryMapper._();

  static CategoryEntity modelToEntity(CategoryModel model) {
    return CategoryEntity(
      id: model.id,
      name: model.name,
      color: model.color,
      icon: model.icon,
      createdAt: model.createdAt,
      isDefault: model.isDefault,
    );
  }

  static CategoryModel entityToModel(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      color: entity.color,
      icon: entity.icon,
      createdAt: entity.createdAt,
      isDefault: entity.isDefault,
    );
  }
}
