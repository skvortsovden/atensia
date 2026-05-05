import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _tzChannel = MethodChannel('com.texapp.atensia/timezone');

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'atensia_daily';
  static const _notifId = 1;

  Future<void> init() async {
    tz.initializeTimeZones();
    final tzName = await _tzChannel.invokeMethod<String>('getLocalTimezone') ?? 'UTC';
    tz.setLocalLocation(tz.getLocation(tzName));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  /// Request notification permissions from the user.
  /// Call this only when the user explicitly enables reminders.
  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      // null means POST_NOTIFICATIONS is not a runtime permission on this
      // Android version (< 13 / API 33) — treat as granted.
      return granted ?? true;
    }
    return true;
  }

  /// Check whether notifications are currently enabled at OS level.
  /// Use this as a fallback when [requestPermission] returns false on OEMs
  /// where the callback fires before the system registers the new grant.
  Future<bool> isPermissionGranted() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? true;
    }
    // On iOS the permission state is managed via requestPermission only.
    return true;
  }

  /// Schedule (or reschedule) a daily notification at [time].
  /// Call with [enabled] = false to cancel.
  Future<void> schedule(TimeOfDay time, {required bool enabled}) async {
    await _plugin.cancel(_notifId);
    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    // If the time already passed today, fire tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Щоденне нагадування',
        channelDescription: 'Нагадування звернути увагу на себе',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        _notifId,
        'Атенція',
        'час звернути увагу на себе',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on PlatformException catch (e) {
      // Exact alarm permission not granted (Android 12+); fall back to inexact.
      debugPrint('NotificationService: exact alarm unavailable ($e), falling back to inexact.');
      await _plugin.zonedSchedule(
        _notifId,
        'Атенція',
        'час звернути увагу на себе',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}
