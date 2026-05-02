import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_entry.dart';
import '../services/notification_service.dart';

class AppProvider extends ChangeNotifier {
  Map<String, DailyEntry> _entries = {};
  String _username = '';
  bool _remindersEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  late SharedPreferences _prefs;

  static const _entriesKey = 'atensia_entries';
  static const _usernameKey = 'atensia_username';
  static const _remindersKey = 'atensia_reminders';
  static const _reminderTimeKey = 'atensia_reminder_time';
  static const _launchedKey = 'atensia_launched';

  // Old keys from when the app was named Proso — used for one-time migration
  static const _oldKeys = {
    'proso_entries': 'atensia_entries',
    'proso_username': 'atensia_username',
    'proso_reminders': 'atensia_reminders',
    'proso_reminder_time': 'atensia_reminder_time',
    'proso_launched': 'atensia_launched',
  };

  // ── Getters ──────────────────────────────────────────────────────────────

  Map<String, DailyEntry> get entries => Map.unmodifiable(_entries);
  String get username => _username;
  bool get remindersEnabled => _remindersEnabled;
  TimeOfDay get reminderTime => _reminderTime;
  bool get isFirstLaunch => !(_prefs.getBool(_launchedKey) ?? false);

  int get currentStreak {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int streak = 1; // today always counts, even without an entry yet
    for (int i = 1; ; i++) {
      final day = today.subtract(Duration(days: i));
      final entry = _entries[dateKey(day)];
      if (entry == null) break;
      final filled = entry.hasState ||
          entry.isSick ||
          entry.hasPain ||
          entry.habits.values.any((v) => v);
      if (filled) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int get totalFilledDays => _entries.values.where((e) =>
      e.hasState ||
      e.isSick ||
      e.hasPain ||
      e.habits.values.any((v) => v)).length;

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // One-time migration from proso_* keys to atensia_*
    for (final e in _oldKeys.entries) {
      if (_prefs.containsKey(e.key) && !_prefs.containsKey(e.value)) {
        final v = _prefs.get(e.key);
        if (v is String) await _prefs.setString(e.value, v);
        if (v is bool) await _prefs.setBool(e.value, v);
      }
      await _prefs.remove(e.key);
    }
    _username = _prefs.getString(_usernameKey) ?? '';
    _remindersEnabled = _prefs.getBool(_remindersKey) ?? false;
    final timeStr = _prefs.getString(_reminderTimeKey);
    if (timeStr != null) {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        _reminderTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 20,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    final raw = _prefs.getString(_entriesKey);
    if (raw != null) {
      try {
        final Map<String, dynamic> decoded =
            jsonDecode(raw) as Map<String, dynamic>;
        _entries = decoded.map(
          (k, v) =>
              MapEntry(k, DailyEntry.fromJson(v as Map<String, dynamic>)),
        );
      } catch (_) {
        _entries = {};
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  DailyEntry getOrCreateEntry(DateTime date) {
    final key = dateKey(date);
    return _entries[key] ?? DailyEntry.empty(date);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  void _saveEntry(DailyEntry entry) {
    final key = dateKey(entry.date);
    _entries[key] = entry;
    _persistEntries();
    notifyListeners();
  }

  void toggleHabit(DateTime date, String habit) {
    final entry = getOrCreateEntry(date);
    final habits = Map<String, bool>.from(entry.habits);
    habits[habit] = !(habits[habit] ?? false);
    _saveEntry(entry.copyWith(habits: habits));
  }

  void setCircumplex(DateTime date, double? valence, double? arousal) {
    final entry = getOrCreateEntry(date);
    _saveEntry(entry.copyWith(valence: valence, arousal: arousal));
  }

  void setValence(DateTime date, double valence) {
    final entry = getOrCreateEntry(date);
    _saveEntry(entry.copyWith(valence: valence));
  }

  void setArousal(DateTime date, double arousal) {
    final entry = getOrCreateEntry(date);
    _saveEntry(entry.copyWith(arousal: arousal));
  }

  void clearValence(DateTime date) {
    final entry = getOrCreateEntry(date);
    _saveEntry(entry.copyWith(valence: null));
  }

  void clearArousal(DateTime date) {
    final entry = getOrCreateEntry(date);
    _saveEntry(entry.copyWith(arousal: null));
  }

  void toggleSick(DateTime date) {
    final entry = getOrCreateEntry(date);
    _saveEntry(entry.copyWith(isSick: !entry.isSick));
  }

  void togglePain(DateTime date) {
    final entry = getOrCreateEntry(date);
    _saveEntry(entry.copyWith(hasPain: !entry.hasPain));
  }

  void setComment(DateTime date, String? comment) {
    final entry = getOrCreateEntry(date);
    _saveEntry(entry.copyWith(comment: comment?.trim().isEmpty == true ? null : comment?.trim()));
  }

  void setUsername(String name) {
    _username = name;
    _prefs.setString(_usernameKey, name);
    notifyListeners();
  }

  void markLaunched() {
    _prefs.setBool(_launchedKey, true);
  }

  Future<void> setReminders(bool enabled) async {
    if (enabled) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) return;
    }
    _remindersEnabled = enabled;
    _prefs.setBool(_remindersKey, enabled);
    NotificationService.instance.schedule(_reminderTime, enabled: enabled);
    notifyListeners();
  }

  void setReminderTime(TimeOfDay time) {
    _reminderTime = time;
    _prefs.setString(_reminderTimeKey,
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
    if (_remindersEnabled) {
      NotificationService.instance.schedule(time, enabled: true);
    }
    notifyListeners();
  }

  void updateEntry(DailyEntry entry) => _saveEntry(entry);

  Future<void> clearAllData() async {
    _entries = {};
    await _prefs.remove(_entriesKey);
    notifyListeners();
  }

  // ── Import ────────────────────────────────────────────────────────────────

  /// Parses [csv] content and merges it into existing entries.
  /// Returns null on success, or an error message string on failure.
  String? importCsv(String csv) {
    final lines = csv
        .split('\n')
        .map((l) => l.trimRight())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) return 'CSV is empty';

    final header = _parseCsvRow(lines.first);
    // Accept both new format (date,valence,arousal,sick,pain) and old (date,mood,sick,pain)
    final isLegacy = header.length >= 4 &&
        header[0] == 'date' && header[1] == 'mood' &&
        header[2] == 'sick' && header[3] == 'pain';
    final isNew = header.length >= 5 &&
        header[0] == 'date' && header[1] == 'valence' &&
        header[2] == 'arousal' && header[3] == 'sick' && header[4] == 'pain';
    if (!isLegacy && !isNew) {
      return 'CSV must start with columns: date,valence,arousal,sick,pain';
    }

    final dataStart = isLegacy ? 4 : 5;
    // Comment column is optional (last column named 'comment')
    final hasCommentCol = header.last == 'comment';
    final habitCols = header.sublist(dataStart, hasCommentCol ? header.length - 1 : null);
    final imported = <String, DailyEntry>{};

    for (int i = 1; i < lines.length; i++) {
      final cells = _parseCsvRow(lines[i]);
      if (cells.length != header.length) {
        return 'Row ${i + 1} has ${cells.length} columns, expected ${header.length}';
      }

      final date = DateTime.tryParse(cells[0]);
      if (date == null) return 'Row ${i + 1}: invalid date "${cells[0]}"';

      double? valence;
      double? arousal;
      bool isSick;
      bool hasPain;

      if (isLegacy) {
        // Map old mood string to circumplex values via fromJson migration
        final moodStr = cells[1];
        if (moodStr.isNotEmpty) {
          final tmp = DailyEntry.fromJson({'date': cells[0], 'habits': {}, 'mood': moodStr, 'isSick': false, 'hasPain': false});
          valence = tmp.valence;
          arousal = tmp.arousal;
        }
        isSick  = cells[2].toLowerCase() == 'true';
        hasPain = cells[3].toLowerCase() == 'true';
      } else {
        valence = double.tryParse(cells[1]);
        arousal = double.tryParse(cells[2]);
        isSick  = cells[3].toLowerCase() == 'true';
        hasPain = cells[4].toLowerCase() == 'true';
      }

      final habits = <String, bool>{};
      for (int j = 0; j < habitCols.length; j++) {
        habits[habitCols[j]] = cells[dataStart + j].toLowerCase() == 'true';
      }

      final commentRaw = hasCommentCol ? cells.last.trim() : null;
      final comment = (commentRaw?.isEmpty ?? true) ? null : commentRaw;

      final key = dateKey(date);
      imported[key] = DailyEntry(
        date: DateTime(date.year, date.month, date.day),
        valence: valence,
        arousal: arousal,
        isSick: isSick,
        hasPain: hasPain,
        habits: habits,
        comment: comment,
      );
    }

    _entries = {..._entries, ...imported};
    _persistEntries();
    notifyListeners();
    return null;
  }

  /// Returns a template CSV with just the header row + 3 blank example rows.
  String buildTemplateCsv() {
    final habitNames = DailyEntry.defaultHabits;
    final headerCells = [
      'date', 'valence', 'arousal', 'sick', 'pain',
      ...habitNames.map((h) => _csvCell(h)),
      'comment',
    ];
    final buf = StringBuffer();
    buf.writeln(headerCells.join(','));
    for (int i = 0; i < 3; i++) {
      final emptyCells = [
        '2026-01-0${i + 1}', '', '', 'false', 'false',
        ...habitNames.map((_) => 'false'),
        '',
      ];
      buf.writeln(emptyCells.join(','));
    }
    return buf.toString();
  }

  // ── Export ────────────────────────────────────────────────────────────────

  String buildCsv() {
    final habitNames = DailyEntry.defaultHabits;
    final buf = StringBuffer();

    // Header
    final headerCells = [
      'date', 'valence', 'arousal', 'sick', 'pain',
      ...habitNames.map((h) => _csvCell(h)),
      'comment',
    ];
    buf.writeln(headerCells.join(','));

    final sorted = _entries.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    for (final entry in sorted) {
      final date =
          '${entry.date.year.toString().padLeft(4, '0')}-'
          '${entry.date.month.toString().padLeft(2, '0')}-'
          '${entry.date.day.toString().padLeft(2, '0')}';
      final cells = [
        date,
        entry.valence != null ? entry.valence!.toStringAsFixed(3) : '',
        entry.arousal != null ? entry.arousal!.toStringAsFixed(3) : '',
        entry.isSick ? 'true' : 'false',
        entry.hasPain ? 'true' : 'false',
        ...habitNames.map((h) => (entry.habits[h] ?? false) ? 'true' : 'false'),
        _csvCell(entry.comment ?? ''),
      ];
      buf.writeln(cells.join(','));
    }

    return buf.toString();
  }

  static String _csvCell(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Parses a single CSV row, handling quoted fields.
  static List<String> _parseCsvRow(String line) {
    final fields = <String>[];
    final buf = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < line.length && line[i + 1] == '"') {
            buf.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          buf.write(ch);
        }
      } else {
        if (ch == '"') {
          inQuotes = true;
        } else if (ch == ',') {
          fields.add(buf.toString());
          buf.clear();
        } else {
          buf.write(ch);
        }
      }
    }
    fields.add(buf.toString());
    return fields;
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _persistEntries() async {
    final encoded = jsonEncode(
      _entries.map((k, v) => MapEntry(k, v.toJson())),
    );
    await _prefs.setString(_entriesKey, encoded);
  }
}
