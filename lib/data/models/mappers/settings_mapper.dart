import '../../../domain/entities/settings_entity.dart';
import '../settings_model.dart';

/// Bidirectional mapper between [SettingsModel] and [SettingsEntity].
class SettingsMapper {
  SettingsMapper._();

  static SettingsEntity modelToEntity(SettingsModel model) {
    return SettingsEntity(
      id: model.id,
      themeMode: model.themeMode,
      accentColor: model.accentColor,
      notificationsEnabled: model.notificationsEnabled,
      defaultReminderOffsetMinutes: model.defaultReminderOffsetMinutes,
      firstDayOfWeek: model.firstDayOfWeek,
      onboardingCompleted: model.onboardingCompleted,
      lastQuoteIndex: model.lastQuoteIndex,
      lastQuoteDate: model.lastQuoteDate,
    );
  }

  static SettingsModel entityToModel(SettingsEntity entity) {
    return SettingsModel(
      id: entity.id,
      themeMode: entity.themeMode,
      accentColor: entity.accentColor,
      notificationsEnabled: entity.notificationsEnabled,
      defaultReminderOffsetMinutes: entity.defaultReminderOffsetMinutes,
      firstDayOfWeek: entity.firstDayOfWeek,
      onboardingCompleted: entity.onboardingCompleted,
      lastQuoteIndex: entity.lastQuoteIndex,
      lastQuoteDate: entity.lastQuoteDate,
    );
  }
}
