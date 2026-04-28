import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/strings.dart';
import '../models/daily_entry.dart';
import '../providers/app_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

double _moodY(String mood) {
  if (mood == S.moodExhausted) return -1;
  if (mood == S.moodEnergetic) return 1;
  return 0;
}

double _healthY(DailyEntry e) {
  if (e.isSick) return -3;
  if (e.hasPain) return -2;
  return 0;
}

Widget _cardShell({required String title, required Widget child}) {
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

// ── Trend chart (mood + health lines) ────────────────────────────────────────

class TrendChartCard extends StatelessWidget {
  const TrendChartCard({
    super.key,
    required this.entries,
    required this.totalDays,
  });

  final List<DailyEntry> entries;
  final int totalDays;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: totalDays - 1));
    final aggregate = totalDays > 30;

    final List<FlSpot> moodSpots;
    final List<FlSpot> healthSpots;
    final int xCount;
    final String Function(double) xLabel;

    if (!aggregate) {
      final entryMap = {
        for (final e in entries) AppProvider.dateKey(e.date): e
      };
      final moodList = <FlSpot>[];
      final healthList = <FlSpot>[];

      for (int i = 0; i < totalDays; i++) {
        final d = start.add(Duration(days: i));
        final e = entryMap[AppProvider.dateKey(d)];
        if (e != null) {
          if (e.mood.isNotEmpty) {
            moodList.add(FlSpot(i.toDouble(), _moodY(e.mood)));
          }
          healthList.add(FlSpot(i.toDouble(), _healthY(e)));
        }
      }
      moodSpots = moodList;
      healthSpots = healthList;
      xCount = totalDays;

      if (totalDays <= 7) {
        xLabel = (v) =>
            DateFormat('E', 'uk').format(start.add(Duration(days: v.round())));
      } else {
        xLabel = (v) {
          final i = v.round();
          if (i % 5 != 0) return '';
          return DateFormat('d', 'uk').format(start.add(Duration(days: i)));
        };
      }
    } else {
      // Weekly aggregation for year
      final weeks = <int, List<DailyEntry>>{};
      for (final e in entries) {
        final wi = e.date.difference(start).inDays ~/ 7;
        weeks.putIfAbsent(wi, () => []).add(e);
      }
      final wCount = (totalDays / 7).ceil();
      final moodList = <FlSpot>[];
      final healthList = <FlSpot>[];

      for (int wi = 0; wi < wCount; wi++) {
        final we = weeks[wi] ?? [];
        final moodE = we.where((e) => e.mood.isNotEmpty).toList();
        if (moodE.isNotEmpty) {
          final avg =
              moodE.map((e) => _moodY(e.mood)).reduce((a, b) => a + b) /
                  moodE.length;
          moodList.add(FlSpot(wi.toDouble(), avg));
        }
        if (we.isNotEmpty) {
          final minH = we.map(_healthY).reduce((a, b) => a < b ? a : b);
          healthList.add(FlSpot(wi.toDouble(), minH));
        }
      }
      moodSpots = moodList;
      healthSpots = healthList;
      xCount = wCount;

      xLabel = (v) {
        final wi = v.round();
        final d = start.add(Duration(days: wi * 7));
        // Show month name only at month boundary
        if (wi == 0) return DateFormat('MMM', 'uk').format(d);
        final prev = start.add(Duration(days: (wi - 1) * 7));
        if (d.month != prev.month) return DateFormat('MMM', 'uk').format(d);
        return '';
      };
    }

    if (moodSpots.isEmpty && healthSpots.isEmpty) {
      return _cardShell(
        title: S.statsSectionTrend,
        child: const SizedBox(
          height: 100,
          child: Center(
            child: Text('—',
                style: TextStyle(fontSize: 24, color: Colors.black26)),
          ),
        ),
      );
    }

    return _cardShell(
      title: S.statsSectionTrend,
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: -3.5,
                maxY: 1.5,
                minX: 0,
                maxX: (xCount - 1).toDouble(),
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Colors.black12,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 70,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final v = value.round();
                        final label = switch (v) {
                          -3 => S.statsSickLabel,
                          -2 => S.statsPainLabel,
                          -1 => S.moodExhausted,
                          0 => S.moodGood,
                          1 => S.moodEnergetic,
                          _ => '',
                        };
                        if (label.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            label,
                            style: const TextStyle(
                                fontSize: 9, color: Colors.black45),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (value, meta) {
                        final label = xLabel(value);
                        if (label.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(label,
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.black45)),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.black87,
                    getTooltipItems: (spots) => spots.map((s) {
                      final label = s.barIndex == 0
                          ? S.statsSectionMood
                          : S.statsSectionHealth;
                      return LineTooltipItem(
                        '$label: ${s.y.toStringAsFixed(1)}',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  // Mood — solid black
                  LineChartBarData(
                    spots: moodSpots,
                    color: Colors.black,
                    barWidth: 2.5,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    dotData: FlDotData(
                      show: totalDays <= 30,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3,
                        color: Colors.black,
                        strokeWidth: 0,
                        strokeColor: Colors.transparent,
                      ),
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Health — dashed grey
                  LineChartBarData(
                    spots: healthSpots,
                    color: Colors.black54,
                    barWidth: 1.5,
                    isCurved: false,
                    dashArray: [5, 4],
                    dotData: FlDotData(
                      show: totalDays <= 30,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 2,
                        color: Colors.black54,
                        strokeWidth: 0,
                        strokeColor: Colors.transparent,
                      ),
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                  color: Colors.black,
                  dashed: false,
                  label: S.statsSectionMood),
              const SizedBox(width: 24),
              _LegendItem(
                  color: Colors.black54,
                  dashed: true,
                  label: S.statsSectionHealth),
            ],
          ),
          const SizedBox(height: 6),
          // Y-axis key
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _YKeyChip(label: S.moodEnergetic, value: '+1'),
              const SizedBox(width: 8),
              _YKeyChip(label: S.moodGood, value: '0'),
              const SizedBox(width: 8),
              _YKeyChip(label: S.moodExhausted, value: '−1'),
              const SizedBox(width: 8),
              _YKeyChip(label: S.statsPainLabel, value: '−2'),
              const SizedBox(width: 8),
              _YKeyChip(label: S.statsSickLabel, value: '−3'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem(
      {required this.color, required this.dashed, required this.label});

  final Color color;
  final bool dashed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(22, 10),
          painter: _LinePainter(color: color, dashed: dashed),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _YKeyChip extends StatelessWidget {
  const _YKeyChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.black45)),
        const SizedBox(width: 2),
        Text(label,
            style: const TextStyle(fontSize: 9, color: Colors.black45)),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.color, required this.dashed});
  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = dashed ? 1.5 : 2.5
      ..style = PaintingStyle.stroke;
    final y = size.height / 2;
    if (dashed) {
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(
            Offset(x, y), Offset((x + 5).clamp(0, size.width), y), paint);
        x += 9;
      }
    } else {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => false;
}

// ── Habit streak card ─────────────────────────────────────────────────────────

class HabitStreakCard extends StatelessWidget {
  const HabitStreakCard({
    super.key,
    required this.entries,
    required this.totalDays,
  });

  final List<DailyEntry> entries;
  final int totalDays;

  static int _currentStreak(List<String> dayKeys, Set<String> filledKeys) {
    int streak = 0;
    for (int i = dayKeys.length - 1; i >= 0; i--) {
      if (filledKeys.contains(dayKeys[i])) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static int _maxStreak(List<String> dayKeys, Set<String> filledKeys) {
    int max = 0, cur = 0;
    for (final k in dayKeys) {
      if (filledKeys.contains(k)) {
        cur++;
        if (cur > max) max = cur;
      } else {
        cur = 0;
      }
    }
    return max;
  }

  /// Returns list of streak run [start, end] indices (runs of 2+ consecutive days)
  static List<(int, int)> _streakRuns(
      List<String> dayKeys, Set<String> filledKeys) {
    final runs = <(int, int)>[];
    int? runStart;
    for (int i = 0; i < dayKeys.length; i++) {
      if (filledKeys.contains(dayKeys[i])) {
        runStart ??= i;
      } else {
        if (runStart != null) {
          if (i - runStart >= 2) runs.add((runStart, i - 1));
          runStart = null;
        }
      }
    }
    if (runStart != null && dayKeys.length - runStart >= 2) {
      runs.add((runStart, dayKeys.length - 1));
    }
    return runs;
  }

  @override
  Widget build(BuildContext context) {
    final habits = DailyEntry.defaultHabits;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: totalDays - 1));

    final allDays = List.generate(
        totalDays, (i) => start.add(Duration(days: i)));
    final dayKeys = allDays.map(AppProvider.dateKey).toList();
    final entryMap = {
      for (final e in entries) AppProvider.dateKey(e.date): e
    };

    final dotSize = totalDays > 30 ? 7.0 : 12.0;
    final dotGap = totalDays > 30 ? 2.0 : 4.0;

    return _cardShell(
      title: S.statsSectionHabits,
      child: Column(
        children: habits.map((habit) {
          final filledKeys = dayKeys
              .where((k) => entryMap[k]?.habits[habit] == true)
              .toSet();
          final currentStreak = _currentStreak(dayKeys, filledKeys);
          final maxStreak = _maxStreak(dayKeys, filledKeys);
          final runs = _streakRuns(dayKeys, filledKeys);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        habit,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (currentStreak >= 2)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_upward, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '$currentStreak ${S.statsDaysSuffix}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      )
                    else if (maxStreak >= 2)
                      Text(
                        '${S.statsMaxStreak} $maxStreak ${S.statsDaysSuffix}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black45),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: dotGap,
                  runSpacing: dotGap,
                  children: List.generate(dayKeys.length, (i) {
                    final filled = filledKeys.contains(dayKeys[i]);
                    final inStreak = runs.any((r) => i >= r.$1 && i <= r.$2);
                    return Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        color: filled ? Colors.black : Colors.black12,
                        borderRadius: BorderRadius.circular(dotSize / 2),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
