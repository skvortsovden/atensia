import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../models/daily_entry.dart';

/// Bridges Flutter app data to the native home screen widget (iOS + Android).
///
/// Call [init] once on startup, then [updateTodayWidget] whenever today's
/// entry changes.
class WidgetService {
  WidgetService._();

  static const _appGroupId = 'group.com.texapp.atensia';
  static const _iOSName = 'AtensiaWidget';
  static const _androidSmallName = 'com.texapp.atensia.AtensiaWidgetProvider';
  static const _androidMediumName = 'com.texapp.atensia.AtensiaWidgetMediumProvider';

  /// Keys written to shared storage — must match native widget code.
  static const kQuadrant = 'widget_quadrant';
  static const kStreak = 'widget_streak';
  static const kValenceLabel = 'widget_valence_label';
  static const kArousalLabel = 'widget_arousal_label';
  static const kHasEntry = 'widget_has_entry';

  /// Configures the App Group ID (required on iOS before first write).
  /// Safe to call multiple times; errors are swallowed.
  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (e) {
      debugPrint('WidgetService.init: $e');
    }
  }

  /// Writes today's state to shared storage and asks the OS to redraw the
  /// widget.  All failures are caught so callers need not handle errors.
  static Future<void> updateTodayWidget({
    required DailyEntry? todayEntry,
    required int streak,
  }) async {
    try {
      final hasState = todayEntry?.hasState ?? false;
      final quadrant = hasState
          ? _circumplexQuadrant(todayEntry!.valence!, todayEntry.arousal!)
          : '';
      final valenceLabel =
          todayEntry?.valence != null ? _valenceLabel(todayEntry!.valence!) : '';
      final arousalLabel =
          todayEntry?.arousal != null ? _arousalLabel(todayEntry!.arousal!) : '';

      await Future.wait([
        HomeWidget.saveWidgetData<String>(kQuadrant, quadrant),
        HomeWidget.saveWidgetData<int>(kStreak, streak),
        HomeWidget.saveWidgetData<String>(kValenceLabel, valenceLabel),
        HomeWidget.saveWidgetData<String>(kArousalLabel, arousalLabel),
        HomeWidget.saveWidgetData<bool>(kHasEntry, hasState),
      ]);

      await HomeWidget.updateWidget(
        iOSName: _iOSName,
        androidName: _androidSmallName,
      );
      await HomeWidget.updateWidget(
        androidName: _androidMediumName,
      );
    } catch (e) {
      debugPrint('WidgetService.updateTodayWidget: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the Ukrainian quadrant label for the given valence / arousal pair.
  /// Uses the same snap thresholds as [CircumplexButtons].
  static String _circumplexQuadrant(double valence, double arousal) {
    final v = valence >= 0.34 ? 'h' : (valence <= -0.34 ? 'l' : 'm');
    final a = arousal >= 0.34 ? 'h' : (arousal <= -0.34 ? 'l' : 'm');
    const labels = {
      'hh': 'На підйомі',
      'hm': 'Спокійно',
      'hl': 'Приємна втома',
      'mh': 'В тонусі',
      'mm': 'В рівновазі',
      'ml': 'Мляво',
      'lh': 'Стресово',
      'lm': 'Пригнічено',
      'll': 'Виснажено',
    };
    return labels['$v$a'] ?? '';
  }

  static String _valenceLabel(double v) {
    if (v >= 0.34) return 'Чудово';
    if (v <= -0.34) return 'Погано';
    return 'Нормально';
  }

  static String _arousalLabel(double a) {
    if (a >= 0.34) return 'Бадьоро';
    if (a <= -0.34) return 'Виснажено';
    return 'Нормально';
  }
}
