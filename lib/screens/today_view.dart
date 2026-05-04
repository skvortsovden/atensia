import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/daily_entry.dart';
import '../providers/app_provider.dart';
import 'circumplex_buttons.dart';

class TodayView extends StatefulWidget {
  const TodayView({super.key});

  @override
  State<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends State<TodayView> {
  late final TextEditingController _commentCtrl;
  String? _lastLoadedComment;

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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                        'Вітаю, ${provider.username.isNotEmpty ? provider.username : 'друже'}!',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${S.todayDatePrefix} ${DateFormat('EEEE, d MMMM', 'uk').format(today)}.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                      if (displayN >= 1)
                        Text.rich(
                          TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                            children: [
                              const TextSpan(text: 'Твій '),
                              TextSpan(
                                text: '$displayN-й день',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: streak >= 2 ? ' записів поспіль.' : ' записів.',
                              ),
                            ],
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
              valence: entry.valence,
              arousal: entry.arousal,
              onValenceChanged: (v) => provider.setValence(today, v),
              onArousalChanged: (a) => provider.setArousal(today, a),
              onValenceCleared: () => provider.clearValence(today),
              onArousalCleared: () => provider.clearArousal(today),
            ),

            const SizedBox(height: 28),
            _HealthRow(entry: entry, date: today),

            const SizedBox(height: 28),
            _SectionLabel(S.todaySectionLeisure),
            const SizedBox(height: 10),
            _HabitList(entry: entry, date: today),

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

// ── Health row ────────────────────────────────────────────────────────────────

class _HealthRow extends StatelessWidget {
  final DailyEntry entry;
  final DateTime date;

  const _HealthRow({required this.entry, required this.date});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.todaySectionHealth.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        provider.toggleSick(date);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        color: entry.isSick ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        alignment: Alignment.center,
                        child: Text(
                          S.labelSick,
                          style: TextStyle(
                            color: entry.isSick ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(width: 2, color: Colors.black),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        provider.togglePain(date);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        color: entry.hasPain ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        alignment: Alignment.center,
                        child: Text(
                          S.labelPain,
                          style: TextStyle(
                            color: entry.hasPain ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Habit list ────────────────────────────────────────────────────────────────

class _HabitList extends StatelessWidget {
  final DailyEntry entry;
  final DateTime date;

  const _HabitList({required this.entry, required this.date});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return Column(
      children: entry.habits.entries.map((e) {
        final checked = e.value;

        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            provider.toggleHabit(date, e.key);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: checked ? Colors.black : Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: checked ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: checked ? Colors.transparent : Colors.black,
                      width: 2,
                    ),
                  ),
                  child: checked
                      ? const Icon(Icons.check, size: 14, color: Colors.black)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    e.key,
                    style: TextStyle(
                      color: checked ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
