import 'dart:convert';

class DailyEntry {
  final DateTime date;
  final Map<String, bool> habits;
  final String mood;
  final bool isSick;
  final bool hasPain;

  static const List<String> defaultHabits = [
    'Прогулянка',
    'Фізична активність',
    'Читання',
    'Творчість',
  ];

  DailyEntry({
    required this.date,
    required this.habits,
    required this.mood,
    required this.isSick,
    required this.hasPain,
  });

  factory DailyEntry.empty(DateTime date) => DailyEntry(
        date: date,
        habits: {for (final h in defaultHabits) h: false},
        mood: '',
        isSick: false,
        hasPain: false,
      );

  DailyEntry copyWith({
    DateTime? date,
    Map<String, bool>? habits,
    String? mood,
    bool? isSick,
    bool? hasPain,
  }) =>
      DailyEntry(
        date: date ?? this.date,
        habits: habits ?? Map<String, bool>.from(this.habits),
        mood: mood ?? this.mood,
        isSick: isSick ?? this.isSick,
        hasPain: hasPain ?? this.hasPain,
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'habits': habits,
        'mood': mood,
        'isSick': isSick,
        'hasPain': hasPain,
      };

  factory DailyEntry.fromJson(Map<String, dynamic> json) => DailyEntry(
        date: DateTime.parse(json['date'] as String),
        habits: Map<String, bool>.from(json['habits'] as Map),
        mood: json['mood'] as String? ?? '',
        isSick: json['isSick'] as bool? ?? false,
        hasPain: json['hasPain'] as bool? ?? false,
      );

  String toJsonString() => jsonEncode(toJson());
  factory DailyEntry.fromJsonString(String s) =>
      DailyEntry.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
