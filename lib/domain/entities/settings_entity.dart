import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsEntity extends Equatable {
  final String id;
  final ThemeMode themeMode;
  final int accentColor;
  final bool notificationsEnabled;
  final int defaultReminderOffsetMinutes;
  final int firstDayOfWeek;
  final bool onboardingCompleted;
  final int lastQuoteIndex;
  final DateTime? lastQuoteDate;

  const SettingsEntity({
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

  /// Default settings used on first launch.
  factory SettingsEntity.defaults() => const SettingsEntity(
        id: 'settings',
        themeMode: ThemeMode.system,
        accentColor: 0xFF6750A4,
        notificationsEnabled: true,
        defaultReminderOffsetMinutes: 30,
        firstDayOfWeek: DateTime.monday,
        onboardingCompleted: false,
        lastQuoteIndex: 0,
        lastQuoteDate: null,
      );

  SettingsEntity copyWith({
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
    return SettingsEntity(
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

  @override
  List<Object?> get props => [
        id,
        themeMode,
        accentColor,
        notificationsEnabled,
        defaultReminderOffsetMinutes,
        firstDayOfWeek,
        onboardingCompleted,
        lastQuoteIndex,
        lastQuoteDate,
      ];
}
