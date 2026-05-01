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

  static const _entriesKey = 'proso_entries';
  static const _usernameKey = 'proso_username';
  static const _remindersKey = 'proso_reminders';
  static const _reminderTimeKey = 'proso_reminder_time';
  static const _launchedKey = 'proso_launched';

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
      final filled = entry.mood.isNotEmpty ||
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
      e.mood.isNotEmpty ||
      e.isSick ||
      e.hasPain ||
      e.habits.values.any((v) => v)).length;

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
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

  void setMood(DateTime date, String mood) {
    final entry = getOrCreateEntry(date);
    _saveEntry(entry.copyWith(mood: mood));
  }

  void toggleSick(DateTime date) {
    final entry = getOrCreateEntry(date);
    _saveEntry(entry.copyWith(isSick: !entry.isSick));
  }

  void togglePain(DateTime date) {
    final entry = getOrCreateEntry(date);
    _saveEntry(entry.copyWith(hasPain: !entry.hasPain));
  }

  void setUsername(String name) {
    _username = name;
    _prefs.setString(_usernameKey, name);
    notifyListeners();
  }

  void markLaunched() {
    _prefs.setBool(_launchedKey, true);
  }

  void setReminders(bool enabled) {
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

  // ── Export ────────────────────────────────────────────────────────────────

  String buildCsv() {
    final habitNames = DailyEntry.defaultHabits;
    final buf = StringBuffer();

    // Header
    final headerCells = [
      'date', 'mood', 'sick', 'pain',
      ...habitNames.map((h) => _csvCell(h)),
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
        _csvCell(entry.mood),
        entry.isSick ? 'true' : 'false',
        entry.hasPain ? 'true' : 'false',
        ...habitNames.map((h) => (entry.habits[h] ?? false) ? 'true' : 'false'),
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

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _persistEntries() async {
    final encoded = jsonEncode(
      _entries.map((k, v) => MapEntry(k, v.toJson())),
    );
    await _prefs.setString(_entriesKey, encoded);
  }
}
