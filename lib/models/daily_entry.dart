import 'dart:convert';

import '../l10n/strings.dart';

class DailyEntry {
  final DateTime date;
  final Map<String, bool> habits;
  /// Valence: -1.0 (unpleasant) to +1.0 (pleasant). Null = not set.
  final double? valence;
  /// Arousal: -1.0 (calm/low) to +1.0 (active/high). Null = not set.
  final double? arousal;
  final bool isSick;
  final bool hasPain;

  static List<String> get defaultHabits => S.defaultHabits;

  DailyEntry({
    required this.date,
    required this.habits,
    this.valence,
    this.arousal,
    required this.isSick,
    required this.hasPain,
  });

  /// True when the user has set their circumplex state for this day.
  bool get hasState => valence != null && arousal != null;

  factory DailyEntry.empty(DateTime date) => DailyEntry(
        date: date,
        habits: {for (final h in defaultHabits) h: false},
        isSick: false,
        hasPain: false,
      );

  DailyEntry copyWith({
    DateTime? date,
    Map<String, bool>? habits,
    // Use an Object sentinel so callers can explicitly pass null to clear.
    Object? valence = _keep,
    Object? arousal = _keep,
    bool? isSick,
    bool? hasPain,
  }) =>
      DailyEntry(
        date: date ?? this.date,
        habits: habits ?? Map<String, bool>.from(this.habits),
        valence: valence is _Sentinel ? this.valence : valence as double?,
        arousal: arousal is _Sentinel ? this.arousal : arousal as double?,
        isSick: isSick ?? this.isSick,
        hasPain: hasPain ?? this.hasPain,
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'habits': habits,
        if (valence != null) 'valence': valence,
        if (arousal != null) 'arousal': arousal,
        'isSick': isSick,
        'hasPain': hasPain,
      };

  factory DailyEntry.fromJson(Map<String, dynamic> json) {
    double? v = (json['valence'] as num?)?.toDouble();
    double? a = (json['arousal'] as num?)?.toDouble();
    // Backward-compat: migrate old mood string to approximate circumplex values.
    if (v == null && a == null) {
      final mood = json['mood'] as String? ?? '';
      if (mood.isNotEmpty) {
        final mapped = _moodToCircumplex(mood);
        v = mapped.$1;
        a = mapped.$2;
      }
    }
    return DailyEntry(
      date: DateTime.parse(json['date'] as String),
      habits: Map<String, bool>.from(json['habits'] as Map),
      valence: v,
      arousal: a,
      isSick: json['isSick'] as bool? ?? false,
      hasPain: json['hasPain'] as bool? ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());
  factory DailyEntry.fromJsonString(String s) =>
      DailyEntry.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

// Sentinel for copyWith optional-null parameters.
class _Sentinel { const _Sentinel(); }
const _keep = _Sentinel();

/// Maps legacy mood strings to approximate Russell's Circumplex positions.
(double, double) _moodToCircumplex(String mood) {
  if (mood.contains('Виснаж')) return (-0.5, -0.6); // exhausted → unpleasant + deactivated
  if (mood.contains('Добре'))  return (0.5, 0.0);   // good → pleasant + neutral
  if (mood.contains('Бадьор')) return (0.7, 0.7);   // energetic → pleasant + activated
  return (0.0, 0.0);
}
