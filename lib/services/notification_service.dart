import 'dart:async';

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

  bool _initialized = false;
  // Completed (with or without error) once init() finishes.
  Completer<void>? _readyCompleter;

  Future<void> init() async {
    // Re-entrancy guard: if init() was already called (in-flight or done),
    // do nothing. Callers that need to wait for readiness use _awaitReady().
    if (_readyCompleter != null) return;
    // Capture in a local variable so the finally block always completes THIS
    // completer, regardless of any future state changes to _readyCompleter.
    final completer = Completer<void>();
    _readyCompleter = completer;
    try {
      tz.initializeTimeZones();
      try {
        final tzName = await _tzChannel.invokeMethod<String>('getLocalTimezone') ?? 'UTC';
        tz.setLocalLocation(tz.getLocation(tzName));
      } catch (e) {
        // Method channel not available yet or unknown timezone — fall back to UTC.
        debugPrint('NotificationService: timezone init failed ($e), using UTC.');
        tz.setLocalLocation(tz.UTC);
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService: plugin init failed ($e).');
    } finally {
      completer.complete();
    }
  }

  // Waits up to 3 s for init() to finish and returns whether it succeeded.
  // Returns false immediately if init() was never called.
  Future<bool> _awaitReady() async {
    if (_readyCompleter == null) return false;
    try {
      await _readyCompleter!.future.timeout(const Duration(seconds: 3));
    } catch (_) {
      return false;
    }
    return _initialized;
  }

  /// Request notification permissions from the user.
  /// Call this only when the user explicitly enables reminders.
  Future<bool> requestPermission() async {
    if (!await _awaitReady()) return false;
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
    if (!await _awaitReady()) return;
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
