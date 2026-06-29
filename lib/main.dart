import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz_tz;

import 'core/constants/hive_constants.dart';
import 'core/enums/priority_enum.dart';
import 'core/enums/recurrence_type_enum.dart';
import 'core/router/router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/theme_provider.dart';
import 'data/models/adapters/theme_mode_adapter.dart';
import 'data/models/category_model.dart';
import 'data/models/settings_model.dart';
import 'data/models/sub_task_model.dart';
import 'data/models/task_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Timezone initialisation ────────────────────────────────────────────────
  tz.initializeTimeZones();
  // Try to set local timezone; fall back to UTC if unavailable
  try {
    final String timezoneName = await _getLocalTimezoneName();
    tz_tz.setLocalLocation(tz_tz.getLocation(timezoneName));
  } catch (_) {
    tz_tz.setLocalLocation(tz_tz.UTC);
  }

  // ── Hive initialisation ────────────────────────────────────────────────────
  await Hive.initFlutter();
  _registerHiveAdapters();
  await _openHiveBoxes();
  await NotificationService.instance.init();
  // ──────────────────────────────────────────────────────────────────────────

  runApp(
    const ProviderScope(
      child: FocusFlowApp(),
    ),
  );
}

Future<String> _getLocalTimezoneName() async {
  // On Android the system locale offset gives us a reasonable fallback,
  // but the simplest cross-platform way is using DateTime.now().timeZoneName.
  return DateTime.now().timeZoneName;
}

/// Register every TypeAdapter before opening any box.
void _registerHiveAdapters() {
  // Enums
  Hive.registerAdapter(PriorityAdapter());
  Hive.registerAdapter(RecurrenceTypeAdapter());

  // Nested model (must be registered before TaskModel)
  Hive.registerAdapter(SubTaskModelAdapter());
  Hive.registerAdapter(TimeOfDayAdapter());

  // Top-level models
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(TaskModelAdapter());
  Hive.registerAdapter(SettingsModelAdapter());

  // Flutter types
  Hive.registerAdapter(ThemeModeAdapter());
}

/// Open all Hive boxes. Must complete before runApp so widgets never
/// encounter a closed box.
Future<void> _openHiveBoxes() async {
  await Future.wait([
    Hive.openBox<TaskModel>(HiveConstants.taskBox),
    Hive.openBox<CategoryModel>(HiveConstants.categoryBox),
    Hive.openBox<SettingsModel>(HiveConstants.settingsBox),
    // Untyped meta box stores boolean seed flags and other primitives.
    Hive.openBox(HiveConstants.metaBox),
  ]);
}

class FocusFlowApp extends ConsumerWidget {
  const FocusFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final light = ref.watch(lightThemeProvider);
    final dark = ref.watch(darkThemeProvider);

    return MaterialApp.router(
      title: 'FocusFlow',
      theme: light,
      darkTheme: dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
