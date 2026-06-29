import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/router.dart';
import '../../../core/services/notification_service.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data: (settings) => ListView(
          children: [
            // ── Appearance ───────────────────────────────────────────────
            const _SectionHeader('Appearance'),
            ListTile(
              leading:  const Icon(Icons.palette_outlined),
              title:    const Text('Theme & Colours'),
              subtitle: Text(_themeName(settings.themeMode)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap:    () => context.goNamed(RouteNames.appearance),
            ),

            // ── Notifications ────────────────────────────────────────────
            const _SectionHeader('Notifications'),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title:     const Text('Enable Notifications'),
              value:     settings.notificationsEnabled,
              onChanged: (v) async {
                if (v) {
                  final granted =
                      await NotificationService.instance.requestPermission();
                  if (!granted) return;
                }
                ref.read(settingsNotifierProvider.notifier).update(
                      settings.copyWith(notificationsEnabled: v),
                    );
              },
            ),
            ListTile(
              leading:  const Icon(Icons.alarm_outlined),
              title:    const Text('Default Reminder'),
              subtitle: Text(
                  '${settings.defaultReminderOffsetMinutes} min before due'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showReminderPicker(context, ref, settings),
            ),

            // ── General ──────────────────────────────────────────────────
            const _SectionHeader('General'),
            ListTile(
              leading:  const Icon(Icons.calendar_today_outlined),
              title:    const Text('First Day of Week'),
              subtitle: Text(settings.firstDayOfWeek == DateTime.monday
                  ? 'Monday'
                  : 'Sunday'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showWeekStartPicker(context, ref, settings),
            ),

            // ── Data ─────────────────────────────────────────────────────
            const _SectionHeader('Data'),
            ListTile(
              leading:  const Icon(Icons.delete_forever_outlined,
                  color: Colors.red),
              title: const Text('Reset All Data',
                  style: TextStyle(color: Colors.red)),
              subtitle: const Text('Permanently delete all tasks and categories'),
              onTap: () => _confirmReset(context, ref),
            ),

            // ── About ────────────────────────────────────────────────────
            const _SectionHeader('About'),
            const ListTile(
              leading:  Icon(Icons.info_outline_rounded),
              title:    Text('App Version'),
              trailing: Text('1.0.0',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading:  const Icon(Icons.description_outlined),
              title:    const Text('Open Source Licences'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap:    () => showLicensePage(
                context: context,
                applicationName:    'FocusFlow',
                applicationVersion: '1.0.0',
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  String _themeName(ThemeMode m) {
    switch (m) {
      case ThemeMode.system: return 'Follow system';
      case ThemeMode.light:  return 'Light';
      case ThemeMode.dark:   return 'Dark';
    }
  }

  void _showReminderPicker(BuildContext ctx, WidgetRef ref, settings) {
    const options = [15, 30, 60, 120];
    showModalBottomSheet(
      context:        ctx,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Default Reminder Offset',
                style: Theme.of(ctx).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...options.map((min) => RadioListTile<int>(
                  title: Text(min >= 60
                      ? '${min ~/ 60} hour${min == 60 ? '' : 's'}'
                      : '$min minutes'),
                  value:    min,
                  groupValue: settings.defaultReminderOffsetMinutes,
                  onChanged: (v) {
                    ref.read(settingsNotifierProvider.notifier).update(
                          settings.copyWith(
                              defaultReminderOffsetMinutes: v),
                        );
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showWeekStartPicker(BuildContext ctx, WidgetRef ref, settings) {
    showModalBottomSheet(
      context:        ctx,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('First Day of Week',
                style: Theme.of(ctx).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            RadioListTile<int>(
              title:      const Text('Monday'),
              value:      DateTime.monday,
              groupValue: settings.firstDayOfWeek,
              onChanged: (v) {
                ref.read(settingsNotifierProvider.notifier).update(
                      settings.copyWith(firstDayOfWeek: v),
                    );
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<int>(
              title:      const Text('Sunday'),
              value:      DateTime.sunday,
              groupValue: settings.firstDayOfWeek,
              onChanged: (v) {
                ref.read(settingsNotifierProvider.notifier).update(
                      settings.copyWith(firstDayOfWeek: v),
                    );
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext ctx, WidgetRef ref) async {
    final step1 = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title:   const Text('Reset All Data?'),
        content: const Text(
            'This will permanently delete ALL tasks, categories, and settings. '
            'This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Continue')),
        ],
      ),
    );
    if (step1 != true || !ctx.mounted) return;

    final step2 = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title:   const Text('Are you absolutely sure?'),
        content: const Text(
            'All your tasks and categories will be gone forever.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Delete Everything')),
        ],
      ),
    );
    if (step2 != true || !ctx.mounted) return;

    await NotificationService.instance.cancelAllNotifications();
    await ref.read(resetSettingsUseCaseProvider)();
    // Also clear tasks and categories via their repos
    ref.read(taskListNotifierProvider.notifier).load();
    ref.read(categoryListNotifierProvider.notifier).load();
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('All data has been reset.')));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color:          cs.primary,
              fontWeight:     FontWeight.w700,
              letterSpacing:  1.2,
            ),
      ),
    );
  }
}
