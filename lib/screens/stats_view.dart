import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/daily_entry.dart';
import '../providers/app_provider.dart';
import 'stats_charts.dart';

enum _Period { week, month, year }

class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  _Period _period = _Period.week;

  int get _days => switch (_period) {
        _Period.week => 7,
        _Period.month => 30,
        _Period.year => 365,
      };

  List<DailyEntry> _entriesForPeriod(Map<String, DailyEntry> all) {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: _days - 1));
    return all.values
        .where((e) => !e.date.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entriesForPeriod(context.watch<AppProvider>().entries);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.statsTitle,
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 20),

            // ── Period selector ───────────────────────────────────────────
            _PeriodSelector(
              current: _period,
              onChanged: (p) => setState(() => _period = p),
            ),

            const SizedBox(height: 28),

            if (entries.isEmpty)
              _EmptyCard()
            else ...[
              _FillCard(entries: entries, period: _period, total: _days),
              const SizedBox(height: 16),
              TrendChartCard(entries: entries, totalDays: _days),
              const SizedBox(height: 16),
              _MoodCard(entries: entries, total: _days),
              const SizedBox(height: 16),
              _HealthCard(entries: entries, total: _days),
              const SizedBox(height: 16),
              HabitStreakCard(
                entries: entries,
                totalDays: _days,
                periodLabel: switch (_period) {
                  _Period.week => S.statsPeriodWeek,
                  _Period.month => S.statsPeriodMonth,
                  _Period.year => S.statsPeriodYear,
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Period selector ───────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.current, required this.onChanged});

  final _Period current;
  final ValueChanged<_Period> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (_Period.week, S.statsPeriodWeek),
      (_Period.month, S.statsPeriodMonth),
      (_Period.year, S.statsPeriodYear),
    ];
    return Row(
      children: options.map((opt) {
        final active = current == opt.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(opt.$1),
            child: Container(
              margin: EdgeInsets.only(
                right: opt.$1 != _Period.year ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? Colors.black : Colors.transparent,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                opt.$2,
                style: TextStyle(
                  fontFamily: 'FixelText',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: active ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Shared card shell ─────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Stat bar row ──────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.count, required this.total});

  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: Colors.black12,
                valueColor: const AlwaysStoppedAnimation(Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$count ${S.statsDaysSuffix}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mood card ─────────────────────────────────────────────────────────────────

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.entries, required this.total});

  final List<DailyEntry> entries;
  final int total;

  @override
  Widget build(BuildContext context) {
    final filled = entries.where((e) => e.mood.isNotEmpty).toList();
    final counts = <String, int>{};
    for (final e in filled) {
      counts[e.mood] = (counts[e.mood] ?? 0) + 1;
    }
    final moods = S.moods;

    return _Card(
      title: S.statsSectionMood,
      child: Column(
        children: moods
            .map((m) => _StatRow(
                  label: m,
                  count: counts[m] ?? 0,
                  total: total,
                ))
            .toList(),
      ),
    );
  }
}

// ── Health card ───────────────────────────────────────────────────────────────

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.entries, required this.total});

  final List<DailyEntry> entries;
  final int total;

  @override
  Widget build(BuildContext context) {
    final sick = entries.where((e) => e.isSick).length;
    final pain = entries.where((e) => e.hasPain).length;

    return _Card(
      title: S.statsSectionHealth,
      child: Column(
        children: [
          _StatRow(label: S.statsSickLabel, count: sick, total: total),
          _StatRow(label: S.statsPainLabel, count: pain, total: total),
        ],
      ),
    );
  }
}

// ── Habits card ───────────────────────────────────────────────────────────────

class _HabitsCard extends StatelessWidget {
  const _HabitsCard({required this.entries, required this.total});

  final List<DailyEntry> entries;
  final int total;

  @override
  Widget build(BuildContext context) {
    final habits = DailyEntry.defaultHabits;

    return _Card(
      title: S.statsSectionHabits,
      child: Column(
        children: habits.map((h) {
          final count = entries.where((e) => e.habits[h] == true).length;
          return _StatRow(label: h, count: count, total: total);
        }).toList(),
      ),
    );
  }
}

// ── Fill card (dot grid) ──────────────────────────────────────────────────────

class _FillCard extends StatelessWidget {
  const _FillCard(
      {required this.entries, required this.period, required this.total});

  final List<DailyEntry> entries;
  final _Period period;
  final int total;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final filledKeys = entries.map((e) => AppProvider.dateKey(e.date)).toSet();
    final count = filledKeys.length;

    // Build list of days oldest → newest
    final days = List.generate(
      total,
      (i) => today.subtract(Duration(days: total - 1 - i)),
    );

    // For year: show by week rows; otherwise by day blocks
    final dotSize = period == _Period.year ? 8.0 : 14.0;
    final dotGap = period == _Period.year ? 3.0 : 5.0;

    return _Card(
      title: S.statsSectionFill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary line
          Text(
            '$count / $total ${S.statsDaysSuffix}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          // Dot grid
          Wrap(
            spacing: dotGap,
            runSpacing: dotGap,
            children: days.map((d) {
              final filled = filledKeys.contains(AppProvider.dateKey(d));
              return Tooltip(
                message: DateFormat('d MMM', 'uk').format(d),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: filled ? Colors.black : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        S.statsNoData,
        style: const TextStyle(color: Colors.black38, fontSize: 15),
        textAlign: TextAlign.center,
      ),
    );
  }
}
