import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

/// Singleton service wrapping flutter_local_notifications.
/// Call [NotificationService.init] once at app startup.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── Channel constants ────────────────────────────────────────────────────

  static const _channelId = 'focusflow_reminders';
  static const _channelName = 'Task Reminders';
  static const _channelDesc = 'Reminders for your FocusFlow tasks';

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    // Timezone already initialized in main(). No-op here.

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create the high-importance Android channel.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );

    _initialized = true;
  }

  // ── Permission ───────────────────────────────────────────────────────────

  /// Requests POST_NOTIFICATIONS permission on Android 13+.
  /// Returns true if granted.
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Returns true if notification permission is currently granted.
  Future<bool> isPermissionGranted() async {
    return (await Permission.notification.status).isGranted;
  }

  // ── Schedule ─────────────────────────────────────────────────────────────

  /// Schedules an exact alarm notification for [scheduledDate].
  /// [id] must be unique per task (use hashCode of task UUID).
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_initialized) await init();

    if (scheduledDate.isBefore(DateTime.now())) {
      debugPrint('[Notifications] Skipping past reminder: $scheduledDate');
      return;
    }

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // ── Cancel ───────────────────────────────────────────────────────────────

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  // ── Pending ──────────────────────────────────────────────────────────────

  Future<List<PendingNotificationRequest>> getPending() async {
    return _plugin.pendingNotificationRequests();
  }

  // ── Deep-link tap handler ────────────────────────────────────────────────

  // The router navigates to the task on tap.
  // We store the last tapped payload here so the router redirect can consume it.
  static String? pendingNavigationPayload;

  static void _onNotificationTap(NotificationResponse response) {
    pendingNavigationPayload = response.payload;
  }

  /// Returns a notification ID (int) derived from a task UUID string.
  static int idFromTaskId(String taskId) => taskId.hashCode.abs() % 2147483647;
}
