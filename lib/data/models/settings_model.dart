import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 6)
class SettingsModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final ThemeMode themeMode;

  @HiveField(2)
  final int accentColor;

  @HiveField(3)
  final bool notificationsEnabled;

  @HiveField(4)
  final int defaultReminderOffsetMinutes;

  @HiveField(5)
  final int firstDayOfWeek;

  @HiveField(6)
  final bool onboardingCompleted;

  @HiveField(7)
  final int lastQuoteIndex;

  @HiveField(8)
  final DateTime? lastQuoteDate;

  SettingsModel({
    required this.id,
    required this.themeMode,
    required this.accentColor,
    required this.notificationsEnabled,
    required this.defaultReminderOffsetMinutes,
    required this.firstDayOfWeek,
    required this.onboardingCompleted,
    required this.lastQuoteIndex,
    this.lastQuoteDate,
  });

  SettingsModel copyWith({
    String? id,
    ThemeMode? themeMode,
    int? accentColor,
    bool? notificationsEnabled,
    int? defaultReminderOffsetMinutes,
    int? firstDayOfWeek,
    bool? onboardingCompleted,
    int? lastQuoteIndex,
    DateTime? lastQuoteDate,
  }) {
    return SettingsModel(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultReminderOffsetMinutes:
          defaultReminderOffsetMinutes ?? this.defaultReminderOffsetMinutes,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      lastQuoteIndex: lastQuoteIndex ?? this.lastQuoteIndex,
      lastQuoteDate: lastQuoteDate ?? this.lastQuoteDate,
    );
  }
}
