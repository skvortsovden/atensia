import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

/// Static strings loaded from assets/l10n/uk.yaml.
/// Call [S.load()] once in main() before runApp().
class S {
  S._();

  static Map<String, dynamic> _m = {};

  static Future<void> load() async {
    final raw = await rootBundle.loadString('assets/l10n/uk.yaml');
    _m = Map<String, dynamic>.from(loadYaml(raw) as Map);
  }

  static String _s(String key) => _m[key] as String? ?? key;

  // ── Onboarding ──────────────────────────────────────────────────────────
  static String get onboardingNameTitle => _s('onboarding_name_title');
  static String get onboardingNameHint => _s('onboarding_name_hint');
  static String get onboardingNameBtn => _s('onboarding_name_btn');
  static String onboardingGreetingTitle(String name) =>
      _s('onboarding_greeting_title').replaceFirst('{name}', name);
  static String get onboardingGreetingTitleDefault =>
      _s('onboarding_greeting_title_default');
  static String get onboardingGreetingText => _s('onboarding_greeting_text');
  static String get onboardingGreetingBtn => _s('onboarding_greeting_btn');
  static String get onboardingNotificationsTitle =>
      _s('onboarding_notifications_title');
  static String get onboardingNotificationsDesc =>
      _s('onboarding_notifications_desc');
  static String get onboardingNotificationsSkip =>
      _s('onboarding_notifications_skip');
  static String get onboardingNotificationsDone =>
      _s('onboarding_notifications_done');
  static String get onboardingGuideTitle => _s('onboarding_guide_title');
  static String get onboardingGuideText => _s('onboarding_guide_text');
  static String get onboardingGuideBtn => _s('onboarding_guide_btn');

  // ── App ─────────────────────────────────────────────────────────────────
  static String get appTitle => _s('app_title');
  static String get appTagline => _s('app_tagline');

  // ── Navigation ──────────────────────────────────────────────────────────
  static String get tabCalendar => _s('tab_calendar');
  static String get tabToday => _s('tab_today');
  static String get tabStats => _s('tab_stats');
  static String get tabSettings => _s('tab_settings');

  // ── Today view ──────────────────────────────────────────────────────────
  static String greetingNamed(String name) =>
      _s('today_greeting_named').replaceFirst('{name}', name);
  static String get greetingDefault => _s('today_greeting_default');
  static String get todayDatePrefix => _s('today_date_prefix');
  static String get todaySubtitle => _s('today_subtitle');
  static String get todaySectionHealth => _s('today_section_health');
  static String get todaySectionLeisure => _s('today_section_leisure');
  static String get todayValenceLabel => _s('today_valence_label');
  static String get todayArousalLabel => _s('today_arousal_label');
  static String get todayValenceMin => _s('today_valence_min');
  static String get todayValenceMax => _s('today_valence_max');
  static String get todayArousalMin => _s('today_arousal_min');
  static String get todayArousalMax => _s('today_arousal_max');
  static String get todayValenceLow  => _s('today_valence_low');
  static String get todayValenceMid  => _s('today_valence_mid');
  static String get todayValenceHigh => _s('today_valence_high');
  static String get todayArousalLow  => _s('today_arousal_low');
  static String get todayArousalMid  => _s('today_arousal_mid');
  static String get todayArousalHigh => _s('today_arousal_high');

  // ── Edit day screen ──────────────────────────────────────────────────────
  static String get editSubtitle => _s('edit_subtitle');
  static String get editSectionHealth => _s('edit_section_health');
  static String get editSectionLeisure => _s('edit_section_leisure');
  static String get editSectionNote => _s('edit_section_note');
  static String get editNoteHint => _s('edit_note_hint');
  static String get editBtnSave => _s('edit_btn_save');

  // ── Calendar / History ───────────────────────────────────────────────────
  static String get calendarTitle => _s('calendar_title');
  static String get calendarFutureDay => _s('calendar_future_day');
  static String get calendarNoData => _s('calendar_no_data');
  static String get calendarBtnAdd => _s('calendar_btn_add');
  static String get calendarBtnEdit => _s('calendar_btn_edit');
  static String get calendarRowFeel => _s('calendar_row_feel');
  static String get calendarRowHealth => _s('calendar_row_health');
  static String get calendarRowLeisure => _s('calendar_row_leisure');
  static String get calendarRowNote => _s('calendar_row_note');

  // ── Settings ─────────────────────────────────────────────────────────────
  static String get settingsTitle => _s('settings_title');
  static String get settingsNameLabel => _s('settings_name_label');
  static String get settingsNameHint => _s('settings_name_hint');
  static String get settingsReminders => _s('settings_reminders');
  static String get settingsReminderTime => _s('settings_reminder_time');
  static String get settingsExportBtn => _s('settings_export_btn');
  static String get settingsExportTitle => _s('settings_export_title');
  static String get settingsExportMessage => _s('settings_export_message');
  static String get settingsExportSave => _s('settings_export_save');
  static String get settingsExportCancel => _s('settings_export_cancel');
  static String get settingsClearBtn => _s('settings_clear_btn');
  static String get settingsClearTitle => _s('settings_clear_title');
  static String get settingsClearMessage => _s('settings_clear_message');
  static String get settingsClearExport => _s('settings_clear_export');
  static String get settingsClearErase => _s('settings_clear_erase');
  static String get settingsClearCancel => _s('settings_clear_cancel');
  static String get settingsClearExportError => _s('settings_clear_export_error');
  static String get settingsClearDoneTitle => _s('settings_clear_done_title');
  static String get settingsClearDoneMessage => _s('settings_clear_done_message');
  static String get settingsClearDoneBtn => _s('settings_clear_done_btn');
  static String get settingsImportBtn => _s('settings_import_btn');
  static String get settingsImportTitle => _s('settings_import_title');
  static String get settingsImportMessage => _s('settings_import_message');
  static String get settingsImportTemplate => _s('settings_import_template');
  static String get settingsImportChoose => _s('settings_import_choose');
  static String get settingsImportCancel => _s('settings_import_cancel');
  static String get settingsImportDoneTitle => _s('settings_import_done_title');
  static String get settingsImportDoneMessage => _s('settings_import_done_message');
  static String get settingsImportDoneBtn => _s('settings_import_done_btn');
  static String get settingsImportErrorTitle => _s('settings_import_error_title');
  static String get settingsImportErrorBtn => _s('settings_import_error_btn');
  static String get settingsImportErrorEncoding => _s('settings_import_error_encoding');
  static String get settingsPrivacy => _s('settings_privacy');

  // ── Stats ────────────────────────────────────────────────────────────────
  static String get statsTitle => _s('stats_title');
  static String get statsPeriodWeek => _s('stats_period_week');
  static String get statsPeriodMonth => _s('stats_period_month');
  static String get statsPeriodYear => _s('stats_period_year');
  static String get statsSectionTrend => _s('stats_section_trend');
  static String get statsSectionMood => _s('stats_section_mood');
  static String get statsSectionHealth => _s('stats_section_health');
  static String get statsSectionHabits => _s('stats_section_habits');
  static String get statsSectionFill => _s('stats_section_fill');
  static String get statsDaysSuffix => _s('stats_days_suffix');
  static String get statsSickLabel => _s('stats_sick_label');
  static String get statsPainLabel => _s('stats_pain_label');
  static String get statsMaxStreak => _s('stats_max_streak');
  static String get statsShareBtn => _s('stats_share_btn');
  static String get statsStoryLeisureTitle => _s('stats_story_leisure_title');
  static String get statsStoryPeriodPrefix => _s('stats_story_period_prefix');
  static String get statsNoData => _s('stats_no_data');
  static String get statsCustomRange => _s('stats_custom_range');
  static String get statsPickDates => _s('stats_pick_dates');

  // ── Shared labels ────────────────────────────────────────────────────────
  static String get labelSick => _s('label_sick');
  static String get labelPain => _s('label_pain');

  // ── Moods (kept for backward-compat migration) ────────────────────────────
  static String get moodExhausted => _s('mood_exhausted');
  static String get moodGood => _s('mood_good');
  static String get moodEnergetic => _s('mood_energetic');
  static List<String> get moods => [moodExhausted, moodGood, moodEnergetic];

  // ── Circumplex combination labels (valence × arousal) ──────────────────────
  static String get circumplexHH => _s('circumplex_hh');
  static String get circumplexHM => _s('circumplex_hm');
  static String get circumplexHL => _s('circumplex_hl');
  static String get circumplexMH => _s('circumplex_mh');
  static String get circumplexMM => _s('circumplex_mm');
  static String get circumplexML => _s('circumplex_ml');
  static String get circumplexLH => _s('circumplex_lh');
  static String get circumplexLM => _s('circumplex_lm');
  static String get circumplexLL => _s('circumplex_ll');
  static String get circumplexNoData => _s('circumplex_no_data');

  /// Returns the combination label for the given valence/arousal pair.
  /// Uses same snap thresholds as CircumplexButtons: <= -0.34 = low, >= 0.34 = high.
  static String circumplexQuadrant(double valence, double arousal) {
    final v = valence >= 0.34 ? 'h' : (valence <= -0.34 ? 'l' : 'm');
    final a = arousal >= 0.34 ? 'h' : (arousal <= -0.34 ? 'l' : 'm');
    return _s('circumplex_${v}${a}');
  }

  // ── Default habits ────────────────────────────────────────────────────────
  static List<String> get defaultHabits =>
      (_m['habits'] as YamlList? ?? YamlList())
          .map((e) => e as String)
          .toList();

  /// Returns the description for [habit], or empty string if not defined.
  static String habitDescription(String habit) {
    final map = _m['habit_descriptions'];
    if (map == null) return '';
    return (map as Map)[habit] as String? ?? '';
  }
}
