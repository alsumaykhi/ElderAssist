import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/medication/models/medication.dart';

/// Production-level local medication reminder service.
///
/// Architecture: UI → MedicationProvider → NotificationService
class NotificationService {
  NotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const String _channelId = 'medication_reminders';
  static const String _channelName = 'Medication Reminders';

  bool _isInitialized = false;
  bool _timezoneInitialized = false;

  /// Initialize the notification plugin and timezone.
  /// Must be called during app startup before scheduling.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _initializeTimezone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createNotificationChannel();
    _isInitialized = true;
  }

  Future<void> _initializeTimezone() async {
    if (_timezoneInitialized) return;

    try {
      tz_data.initializeTimeZones();
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(timezoneName);
      tz.setLocalLocation(location);
      _timezoneInitialized = true;
    } catch (e) {
      debugPrint('NotificationService: timezone init failed, using UTC: $e');
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.UTC);
      _timezoneInitialized = true;
    }
  }

  Future<void> _createNotificationChannel() async {
    if (!_isAndroid) return;

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Reminders for taking medications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Optional: handle notification tap, e.g. navigate to medication list
    debugPrint('Medication reminder tapped: ${response.payload}');
  }

  bool get _isAndroid {
    try {
      return defaultTargetPlatform == TargetPlatform.android;
    } catch (_) {
      return false;
    }
  }

  /// Request notification permission (Android 13+).
  /// Does not crash if permission is denied.
  Future<bool> requestNotificationPermission() async {
    if (!_isAndroid) return true;

    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Schedule daily reminders for a medication.
  /// Applies scheduling rules: isActive, startDate, endDate.
  Future<void> scheduleMedicationReminder(Medication medication) async {
    if (!_isInitialized || !_timezoneInitialized) {
      debugPrint('NotificationService: not initialized, skipping schedule');
      return;
    }

    if (!medication.isActive) return;

    final today = _todayDateOnly();
    if (today.isBefore(_dateOnly(medication.startDate))) return;
    if (medication.endDate != null &&
        today.isAfter(_dateOnly(medication.endDate!))) {
      return;
    }

    if (medication.times.isEmpty) return;

    for (final timeStr in medication.times) {
      final scheduledDate = _parseScheduledDateTime(timeStr, today);
      if (scheduledDate == null) continue;

      final id = _notificationId(medication.id, timeStr);

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Reminders for taking medications',
        importance: Importance.high,
        priority: Priority.high,
      );

      const details = NotificationDetails(android: androidDetails);

      try {
        await _plugin.zonedSchedule(
          id,
          'Medication Reminder',
          'Time to take ${medication.name}',
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('Failed to schedule reminder for ${medication.name} at $timeStr: $e');
      }
    }
  }

  /// Cancel all reminders for a medication.
  Future<void> cancelMedicationReminders(Medication medication) async {
    if (!_isInitialized) return;

    for (final timeStr in medication.times) {
      final id = _notificationId(medication.id, timeStr);
      try {
        await _plugin.cancel(id);
      } catch (_) {}
    }
  }

  /// Cancel all scheduled medication reminders.
  Future<void> cancelAllReminders() async {
    if (!_isInitialized) return;
    await _plugin.cancelAll();
  }

  /// Rehydrate scheduled reminders from the current medication list.
  /// Call on app startup after loading medications.
  Future<void> rehydrateScheduledReminders(List<Medication> medications) async {
    if (!_isInitialized) return;

    await cancelAllReminders();

    for (final medication in medications) {
      await scheduleMedicationReminder(medication);
    }
  }

  /// Schedule a generic daily check-in notification at a specific time.
  Future<void> scheduleDailyCheckInNotification({
    required String timeStr,
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized || !_timezoneInitialized) {
      debugPrint('NotificationService: not initialized, skipping check-in schedule');
      return;
    }

    final today = _todayDateOnly();
    final scheduledDate = _parseScheduledDateTime(timeStr, today);
    if (scheduledDate == null) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Daily check-in reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Failed to schedule check-in notification at $timeStr: $e');
    }
  }

  int _notificationId(String medicationId, String timeStr) {
    final hash = Object.hash(medicationId, timeStr);
    return hash & 0x7FFFFFFF;
  }

  DateTime _todayDateOnly() {
    final now = tz.TZDateTime.now(tz.local);
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Parse "HH:mm" into TZDateTime for today at that time (local timezone).
  tz.TZDateTime? _parseScheduledDateTime(String timeStr, DateTime today) {
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return tz.TZDateTime(
      tz.local,
      today.year,
      today.month,
      today.day,
      hour,
      minute,
    );
  }
}

