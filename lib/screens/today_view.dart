import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/daily_entry.dart';
import '../providers/app_provider.dart';
import 'circumplex_buttons.dart';

// Shared corner radius for habit rows and health cells.
const _kRowRadius = BorderRadius.all(Radius.circular(14));

class TodayView extends StatefulWidget {
  const TodayView({super.key});

  @override
  State<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends State<TodayView> {
  late final TextEditingController _commentCtrl;
  String? _lastLoadedComment;
  String? _lastCircumplex;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    final today = _today();
    final entry = context.read<AppProvider>().getOrCreateEntry(today);
    _lastLoadedComment = entry.comment;
    _commentCtrl = TextEditingController(text: entry.comment ?? '');
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _showGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.onboardingGuideTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Text(
              S.onboardingGuideText,
              style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: _kRowRadius),
                  elevation: 0,
                ),
                child: Text(
                  S.onboardingGuideBtn,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final today = _today();
    final entry = provider.getOrCreateEntry(today);

    // Sync controller if comment was changed externally (e.g. from calendar edit)
    if (entry.comment != _lastLoadedComment) {
      _lastLoadedComment = entry.comment;
      final newText = entry.comment ?? '';
      if (_commentCtrl.text != newText) {
        _commentCtrl.text = newText;
      }
    }
    final streak = provider.currentStreak;
    final todayFilled = entry.hasState ||
        entry.isSick ||
        entry.hasPain ||
        entry.habits.values.any((v) => v);
    final displayN = provider.totalFilledDays + (todayFilled ? 0 : 1);

    final circumplex = entry.hasState
        ? S.circumplexQuadrant(entry.valence!, entry.arousal!)
        : null;
    if (circumplex != null) _lastCircumplex = circumplex;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.username.isNotEmpty
                              ? S.greetingNamed(provider.username)
                              : S.greetingDefault,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${S.todayDatePrefix} ${DateFormat('EEEE, d MMMM', S.dateLocale).format(today)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF595959),
                          ),
                        ),
                        if (displayN >= 1)
                          Text.rich(
                            TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF595959),
                              ),
                              children: [
                                TextSpan(text: S.todayStreakBefore),
                                TextSpan(
                                  text: S.todayStreakDay(displayN),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: streak >= 2
                                      ? S.todayStreakAfterStreak
                                      : S.todayStreakAfter,
                                ),
                              ],
                            ),
                          ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: circumplex != null ? 1.0 : 0.0,
                          child: Text.rich(
                            TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF595959),
                              ),
                              children: [
                                TextSpan(text: S.todayStatePrefix),
                                TextSpan(
                                  text: (_lastCircumplex ?? '').toLowerCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showGuide(context),
                    child: Image.asset(
                      'assets/atensia-logo.png',
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CircumplexButtons(
                title: S.todaySubtitle,
                showStateLabel: false,
                valence: entry.valence,
                arousal: entry.arousal,
                onValenceChanged: (v) => provider.setValence(today, v),
                onArousalChanged: (a) => provider.setArousal(today, a),
                onValenceCleared: () => provider.clearValence(today),
                onArousalCleared: () => provider.clearArousal(today),
              ),

              const SizedBox(height: 28),
              _SectionLabel(S.todaySectionHealth),
              const SizedBox(height: 10),
              _HealthRow(
                entry: entry,
                date: today,
              ),

              const SizedBox(height: 28),
              _SectionLabel(S.todaySectionLeisure),
              const SizedBox(height: 10),
              _HabitList(
                entry: entry,
                date: today,
              ),

              const SizedBox(height: 28),
              _SectionLabel(S.editSectionNote),
              const SizedBox(height: 10),
              TextField(
                controller: _commentCtrl,
                maxLines: null,
                maxLength: 140,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (val) => provider.setComment(today, val),
                decoration: InputDecoration(
                  hintText: S.editNoteHint,
                  hintStyle:
                      const TextStyle(color: Colors.black38, fontSize: 14),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  counterStyle:
                      const TextStyle(color: Colors.black38, fontSize: 11),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineLarge,
    );
  }
}

// ── Shared checkbox row (used by both _HealthRow and _HabitList) ──────────────

class _CheckboxRow extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTap;

  const _CheckboxRow({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      selected: checked,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: checked ? const Color(0xFFE8E8E8) : Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: checked ? Colors.black : Colors.transparent,
                  border: Border.all(
                    color: checked ? Colors.transparent : Colors.black,
                    width: 2,
                  ),
                ),
                child: checked
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Health row ────────────────────────────────────────────────────────────────

class _HealthRow extends StatelessWidget {
  final DailyEntry entry;
  final DateTime date;
  final VoidCallback? onChanged;

  const _HealthRow({
    required this.entry,
    required this.date,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CheckboxRow(
          label: S.labelSick,
          checked: entry.isSick,
          onTap: () {
            HapticFeedback.mediumImpact();
            provider.toggleSick(date);
            onChanged?.call();
          },
        ),
        _CheckboxRow(
          label: S.labelPain,
          checked: entry.hasPain,
          onTap: () {
            HapticFeedback.mediumImpact();
            provider.togglePain(date);
            onChanged?.call();
          },
        ),
      ],
    );
  }
}

// ── Habit list ────────────────────────────────────────────────────────────────

class _HabitList extends StatelessWidget {
  final DailyEntry entry;
  final DateTime date;
  final VoidCallback? onChanged;

  const _HabitList({
    required this.entry,
    required this.date,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final displayNames = S.defaultHabits;
    final storedKeys = entry.habits.keys.toList();

    return Column(
      children: List.generate(displayNames.length, (i) {
        final storedKey = i < storedKeys.length ? storedKeys[i] : displayNames[i];
        final checked = entry.habits[storedKey] ?? false;

        return _CheckboxRow(
          label: displayNames[i],
          checked: checked,
          onTap: () {
            HapticFeedback.mediumImpact();
            provider.toggleHabit(date, storedKey);
            onChanged?.call();
          },
        );
      }),
    );
  }
}
