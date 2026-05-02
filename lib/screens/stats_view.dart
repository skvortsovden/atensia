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
  int _offset = 0; // 0 = current, 1 = one period back, etc.

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // First day of the target calendar month (offset months back).
  DateTime _targetMonthStart(int offset) {
    final now = DateTime.now();
    int month = now.month - offset;
    int year = now.year;
    while (month <= 0) {
      month += 12;
      year--;
    }
    return DateTime(year, month, 1);
  }

  // Full period bounds (including future days for month).
  DateTime get _periodStart {
    switch (_period) {
      case _Period.week:
        return _today.subtract(Duration(days: 6 + 7 * _offset));
      case _Period.month:
        return _targetMonthStart(_offset);
      case _Period.year:
        return DateTime(_today.year - _offset, 1, 1);
    }
  }

  DateTime get _periodEnd {
    switch (_period) {
      case _Period.week:
        return _today.subtract(Duration(days: 7 * _offset));
      case _Period.month:
        final start = _targetMonthStart(_offset);
        return DateTime(start.year, start.month + 1, 0); // last day of month
      case _Period.year:
        return DateTime(_today.year - _offset, 12, 31);
    }
  }

  // Total grid days (includes future for month).
  int get _days => _periodEnd.difference(_periodStart).inDays + 1;

  // Data cutoff: never beyond today.
  DateTime get _dataEnd => _periodEnd.isAfter(_today) ? _today : _periodEnd;

  String get _periodLabel {
    final start = _periodStart;
    final end = _periodEnd;
    switch (_period) {
      case _Period.week:
        return 'тиждень ${DateFormat('d MMM', 'uk').format(start)} – ${DateFormat('d MMM', 'uk').format(end)}';
      case _Period.month:
        return DateFormat('LLLL yyyy', 'uk').format(start);
      case _Period.year:
        return DateFormat('yyyy', 'uk').format(end);
    }
  }

  static bool _hasData(DailyEntry e) =>
      e.hasState ||
      e.isSick ||
      e.hasPain ||
      e.habits.values.any((v) => v) ||
      (e.comment?.isNotEmpty ?? false);

  List<DailyEntry> _entriesForPeriod(Map<String, DailyEntry> all) {
    final start = _periodStart;
    final end = _dataEnd;
    return all.values
        .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end) && _hasData(e))
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
              onChanged: (p) => setState(() {
                _period = p;
                _offset = 0;
              }),
            ),

            const SizedBox(height: 12),

            // ── Period navigator ──────────────────────────────────────────
            _PeriodNavigator(
              label: _periodLabel,
              canGoForward: _offset > 0,
              onBack: () => setState(() => _offset++),
              onForward: () => setState(() => _offset--),
            ),

            const SizedBox(height: 20),

            if (entries.isEmpty)
              _EmptyCard()
            else ...[
              _FillCard(entries: entries, period: _period, total: _days, periodStart: _periodStart, periodEnd: _periodEnd),
              const SizedBox(height: 16),
              TrendChartCard(entries: entries, totalDays: _days, periodEnd: _periodEnd),
              const SizedBox(height: 16),
              _CircumplexCard(entries: entries),
              const SizedBox(height: 16),
              _HealthCard(entries: entries, total: _days),
              const SizedBox(height: 16),
              HabitStreakCard(
                entries: entries,
                totalDays: _days,
                periodLabel: _periodLabel,
                periodEnd: _periodEnd,
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

// ── Period navigator ──────────────────────────────────────────────────────────

class _PeriodNavigator extends StatelessWidget {
  const _PeriodNavigator({
    required this.label,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
  });

  final String label;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onBack,
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.chevron_left, size: 22, color: Colors.black),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        GestureDetector(
          onTap: canGoForward ? onForward : null,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.chevron_right,
              size: 22,
              color: canGoForward ? Colors.black : Colors.black26,
            ),
          ),
        ),
      ],
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

// ── Circumplex quadrant distribution card ─────────────────────────────────────

class _CircumplexCard extends StatelessWidget {
  const _CircumplexCard({required this.entries});

  final List<DailyEntry> entries;

  @override
  Widget build(BuildContext context) {
    final withState = entries.where((e) => e.hasState).toList();
    final total = withState.length;

    if (total == 0) {
      return _Card(
        title: S.statsSectionMood,
        child: SizedBox(
          height: 60,
          child: Center(
            child: Text(
              S.circumplexNoData,
              style: const TextStyle(color: Colors.black38, fontSize: 14),
            ),
          ),
        ),
      );
    }

    final counts = <String, int>{};
    for (final e in withState) {
      final label = S.circumplexQuadrant(e.valence!, e.arousal!);
      counts[label] = (counts[label] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _Card(
      title: S.statsSectionMood,
      child: Column(
        children: sorted.map((e) => _StatRow(label: e.key, count: e.value, total: total)).toList(),
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
  const _FillCard({
    required this.entries,
    required this.period,
    required this.total,
    required this.periodStart,
    required this.periodEnd,
  });

  final List<DailyEntry> entries;
  final _Period period;
  final int total;
  final DateTime periodStart;
  final DateTime periodEnd;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final filledKeys = entries.map((e) => AppProvider.dateKey(e.date)).toSet();
    final count = filledKeys.length;

    // Days elapsed in period up to today (for the summary denominator).
    final dataEnd = periodEnd.isAfter(today) ? today : periodEnd;
    final elapsed = dataEnd.difference(periodStart).inDays + 1;

    // Build list of days oldest → newest (full period including future).
    final days = List.generate(total, (i) => periodStart.add(Duration(days: i)));

    // For year: show smaller dots; otherwise standard size.
    final dotSize = period == _Period.year ? 8.0 : 14.0;
    final dotGap = period == _Period.year ? 3.0 : 5.0;

    return _Card(
      title: S.statsSectionFill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count / $elapsed ${S.statsDaysSuffix}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: dotGap,
            runSpacing: dotGap,
            children: days.map((d) {
              final isFuture = d.isAfter(today);
              final filled = filledKeys.contains(AppProvider.dateKey(d));

              final Color dotColor;
              if (isFuture) {
                dotColor = Colors.black.withValues(alpha: 0.06);
              } else if (filled) {
                dotColor = Colors.black;
              } else {
                dotColor = Colors.black12;
              }

              Widget dot = Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: dotColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              );

              return Tooltip(
                message: DateFormat('d MMM', 'uk').format(d),
                child: dot,
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
