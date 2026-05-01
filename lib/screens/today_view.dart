import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/daily_entry.dart';
import '../providers/app_provider.dart';
import 'circumplex_buttons.dart';

class TodayView extends StatelessWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final today = _today();
    final entry = provider.getOrCreateEntry(today);
    final streak = provider.currentStreak;
    final todayFilled = entry.hasState ||
        entry.isSick ||
        entry.hasPain ||
        entry.habits.values.any((v) => v);
    final displayN = provider.totalFilledDays + (todayFilled ? 0 : 1);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Вітаю,',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                Text(
                  provider.username.isNotEmpty ? provider.username : 'друже!',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${S.todayDatePrefix} ${DateFormat('d MMMM', 'uk').format(today)}.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                ),
                if (displayN >= 1)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                          children: [
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
              ],
            ),
            const SizedBox(height: 6),
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
            _SectionLabel(S.todaySectionHealth),
            const SizedBox(height: 10),
            _HealthToggles(entry: entry, date: today),

            const SizedBox(height: 28),
            _SectionLabel(S.todaySectionLeisure),
            const SizedBox(height: 10),
            _HabitList(entry: entry, date: today),
          ],
        ),
      ),
    );
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
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

// ── Health toggles ────────────────────────────────────────────────────────────

class _HealthToggles extends StatelessWidget {
  final DailyEntry entry;
  final DateTime date;

  const _HealthToggles({required this.entry, required this.date});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return Row(
      children: [
        Expanded(
          child: _ToggleButton(
            label: S.labelSick,
            isActive: entry.isSick,
            onTap: () {
              HapticFeedback.mediumImpact();
              provider.toggleSick(date);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToggleButton(
            label: S.labelPain,
            isActive: entry.hasPain,
            onTap: () {
              HapticFeedback.mediumImpact();
              provider.togglePain(date);
            },
          ),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ── Habit list ────────────────────────────────────────────────────────────────

class _HabitList extends StatefulWidget {
  final DailyEntry entry;
  final DateTime date;

  const _HabitList({required this.entry, required this.date});

  @override
  State<_HabitList> createState() => _HabitListState();
}

class _HabitListState extends State<_HabitList> {
  String? _expandedHabit;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return Column(
      children: widget.entry.habits.entries.map((e) {
        final checked = e.value;
        final desc = S.habitDescription(e.key);
        final expanded = _expandedHabit == e.key && desc.isNotEmpty;

        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            provider.toggleHabit(widget.date, e.key);
          },
          onLongPress: desc.isEmpty
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _expandedHabit = expanded ? null : e.key;
                  });
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    if (desc.isNotEmpty)
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16,
                        color: checked ? Colors.white54 : Colors.black38,
                      ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: expanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8, left: 32),
                          child: Text(
                            desc,
                            style: TextStyle(
                              fontSize: 13,
                              color: checked
                                  ? Colors.white70
                                  : Colors.black54,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
