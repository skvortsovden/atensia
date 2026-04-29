import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/strings.dart';
import '../models/daily_entry.dart';
import '../providers/app_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

double _moodY(String mood) {
  if (mood == S.moodExhausted) return 0;
  if (mood == S.moodGood) return 1;
  if (mood == S.moodEnergetic) return 2;
  return 1;
}

double _healthY(DailyEntry e) {
  if (e.isSick) return -2;
  if (e.hasPain) return -1;
  return 1;
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

// ── Streak helpers ────────────────────────────────────────────────────────────

int _calcCurrentStreak(List<String> dayKeys, Set<String> filledKeys) {
  if (dayKeys.isEmpty) return 0;
  int streak = 1; // today (last key) always counts, even without an entry yet
  for (int i = dayKeys.length - 2; i >= 0; i--) {
    if (filledKeys.contains(dayKeys[i])) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

int _calcMaxStreak(List<String> dayKeys, Set<String> filledKeys) {
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
                minY: -2.5,
                maxY: 2.5,
                minX: 0,
                maxX: (xCount - 1).toDouble(),
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  checkToShowHorizontalLine: (_) => true,
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
                          -2 => S.statsSickLabel,
                          -1 => S.statsPainLabel,
                          0 => S.moodExhausted,
                          1 => S.moodGood,
                          2 => S.moodEnergetic,
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

class HabitStreakCard extends StatefulWidget {
  const HabitStreakCard({
    super.key,
    required this.entries,
    required this.totalDays,
    required this.periodLabel,
  });

  final List<DailyEntry> entries;
  final int totalDays;
  final String periodLabel;

  @override
  State<HabitStreakCard> createState() => _HabitStreakCardState();
}

class _HabitStreakCardState extends State<HabitStreakCard> {
  final _shareKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final habits = DailyEntry.defaultHabits;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: widget.totalDays - 1));

    final allDays = List.generate(
        widget.totalDays, (i) => start.add(Duration(days: i)));
    final dayKeys = allDays.map(AppProvider.dateKey).toList();
    final entryMap = {
      for (final e in widget.entries) AppProvider.dateKey(e.date): e
    };

    final dotSize = widget.totalDays > 30 ? 7.0 : 12.0;
    final dotGap = widget.totalDays > 30 ? 2.0 : 4.0;

    return _cardShell(
      title: S.statsSectionHabits,
      child: Column(
        children: [
          ...habits.map((habit) {
            final filledKeys = dayKeys
                .where((k) => entryMap[k]?.habits[habit] == true)
                .toSet();
            final currentStreak = _calcCurrentStreak(dayKeys, filledKeys);
            final maxStreak = _calcMaxStreak(dayKeys, filledKeys);

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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_upward,
                                size: 12, color: Colors.black),
                            const SizedBox(width: 2),
                            Text(
                              '$maxStreak ${S.statsDaysSuffix}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: dotGap,
                    runSpacing: dotGap,
                    children: List.generate(dayKeys.length, (i) {
                      final filled = filledKeys.contains(dayKeys[i]);
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
          }),
          const SizedBox(height: 4),
          GestureDetector(
            key: _shareKey,
            onTap: () => _onShare(context, dayKeys, entryMap),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.share_outlined,
                      size: 14, color: Colors.black54),
                  const SizedBox(width: 6),
                  Text(
                    S.statsShareBtn,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onShare(
    BuildContext context,
    List<String> dayKeys,
    Map<String, DailyEntry> entryMap,
  ) {
    final box = _shareKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 400, 1, 1);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _StoryPreviewSheet(
        entries: widget.entries,
        totalDays: widget.totalDays,
        periodLabel: widget.periodLabel,
        shareOrigin: origin,
      ),
    );
  }
}

// ── Story preview sheet ───────────────────────────────────────────────────────

class _StoryPreviewSheet extends StatefulWidget {
  const _StoryPreviewSheet({
    required this.entries,
    required this.totalDays,
    required this.periodLabel,
    required this.shareOrigin,
  });

  final List<DailyEntry> entries;
  final int totalDays;
  final String periodLabel;
  final Rect shareOrigin;

  @override
  State<_StoryPreviewSheet> createState() => _StoryPreviewSheetState();
}

class _StoryPreviewSheetState extends State<_StoryPreviewSheet> {
  final _captureKey = GlobalKey();
  bool _sharing = false;
  Set<String> _excludedHabits = {};

  /// Returns habits that have zero fills in the current period.
  Set<String> _computeEmptyHabits() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: widget.totalDays - 1));
    final dayKeys = List.generate(
        widget.totalDays,
        (i) => AppProvider.dateKey(start.add(Duration(days: i))));
    final entryMap = {
      for (final e in widget.entries) AppProvider.dateKey(e.date): e
    };
    return DailyEntry.defaultHabits.where((habit) {
      return !dayKeys.any((k) => entryMap[k]?.habits[habit] == true);
    }).toSet();
  }

  Future<void> _askFilterEmpty() async {
    final empty = _computeEmptyHabits();
    if (empty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Всі звички мають дані за цей період.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Прибрати пусті дані?'),
        content: Text(
          empty.join(', '),
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ні'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Так',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _excludedHabits = empty);
    } else if (confirmed == false) {
      setState(() => _excludedHabits = {});
    }
  }

  Future<void> _capture() async {
    setState(() => _sharing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 80));
      final boundary = _captureKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List bytes = data!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/atensia_story_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      if (mounted) Navigator.of(context).pop();
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        sharePositionOrigin: widget.shareOrigin,
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: SizedBox(
                height: 520,
                child: AspectRatio(
                  aspectRatio: _HabitStoryWidget.kLogicalWidth /
                      _HabitStoryWidget.kLogicalHeight,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 12,
                            offset: Offset(0, 4))
                      ],
                    ),
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: RepaintBoundary(
                        key: _captureKey,
                        child: _HabitStoryWidget(
                          entries: widget.entries,
                          totalDays: widget.totalDays,
                          periodLabel: widget.periodLabel,
                          excludedHabits: _excludedHabits,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'згенерована картинка, якою можна поділитись в соц.мережах або надіслати друзям',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _sharing ? null : _askFilterEmpty,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _excludedHabits.isEmpty
                        ? Icons.filter_list_outlined
                        : Icons.filter_list,
                    size: 16,
                    color: _excludedHabits.isEmpty
                        ? Colors.black54
                        : Colors.black,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Прибрати пусті дані?',
                    style: TextStyle(
                      fontSize: 15,
                      color: _excludedHabits.isEmpty
                          ? Colors.black54
                          : Colors.black,
                      fontWeight: _excludedHabits.isEmpty
                          ? FontWeight.w500
                          : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _sharing ? null : _capture,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _sharing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        S.statsShareBtn,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Habit story widget – fixed 360×640 logical canvas (→ 1080×1920 @ 3×) ─────

class _HabitStoryWidget extends StatelessWidget {
  const _HabitStoryWidget({
    required this.entries,
    required this.totalDays,
    required this.periodLabel,
    this.excludedHabits = const {},
  });

  final List<DailyEntry> entries;
  final int totalDays;
  final String periodLabel;
  final Set<String> excludedHabits;

  // Capture at pixelRatio 3.0 → 1080 × 1920 px output
  static const double kLogicalWidth = 360.0;
  static const double kLogicalHeight = 640.0;

  @override
  Widget build(BuildContext context) {
    final habits = DailyEntry.defaultHabits
        .where((h) => !excludedHabits.contains(h))
        .toList();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: totalDays - 1));
    final dayKeys = List.generate(
        totalDays, (i) => AppProvider.dateKey(start.add(Duration(days: i))));
    final entryMap = {
      for (final e in entries) AppProvider.dateKey(e.date): e
    };

    return SizedBox(
      width: kLogicalWidth,
      height: kLogicalHeight,
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fixed header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(52, 64, 52, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.statsStoryLeisureTitle,
                          style: const TextStyle(
                            fontFamily: 'FixelDisplay',
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '${S.statsStoryPeriodPrefix} ${periodLabel.toLowerCase()}',
                          style: const TextStyle(
                            fontFamily: 'FixelText',
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/atensia-logo.png',
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(52, 14, 52, 0),
              child: Container(height: 2, color: Colors.black),
            ),
            // ── Flexible middle – each habit row gets equal height ──────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(52, 14, 52, 8),
                child: Column(
                  children: habits.map((habit) {
                    final filledKeys = dayKeys
                        .where((k) => entryMap[k]?.habits[habit] == true)
                        .toSet();
                    return Expanded(
                      child: _HabitStoryRow(
                        habit: habit,
                        dayKeys: dayKeys,
                        filledKeys: filledKeys,
                        currentStreak: _calcCurrentStreak(dayKeys, filledKeys),
                        maxStreak: _calcMaxStreak(dayKeys, filledKeys),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // ── Fixed footer ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(52, 0, 52, 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(height: 1, color: Colors.black12),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Branding block — left
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              S.appTitle,
                              style: const TextStyle(
                                fontFamily: 'FixelDisplay',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              S.appTagline,
                              style: const TextStyle(
                                fontFamily: 'FixelText',
                                fontSize: 9,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Date — right
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('d MMMM', 'uk').format(now),
                            style: const TextStyle(
                              fontFamily: 'FixelText',
                              fontSize: 9,
                              color: Colors.black45,
                            ),
                          ),
                          Text(
                            DateFormat('yyyy', 'uk').format(now),
                            style: const TextStyle(
                              fontFamily: 'FixelText',
                              fontSize: 9,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Habit story row – auto-sizes dots to fill the allotted space ──────────────

class _HabitStoryRow extends StatelessWidget {
  const _HabitStoryRow({
    required this.habit,
    required this.dayKeys,
    required this.filledKeys,
    required this.currentStreak,
    required this.maxStreak,
  });

  final String habit;
  final List<String> dayKeys;
  final Set<String> filledKeys;
  final int currentStreak;
  final int maxStreak;

  static const double _nameH = 16.0;
  static const double _nameGap = 5.0;

  /// Largest dot size where all [count] dots fit within [availW] × [availH].
  double _bestDotSize(double availW, double availH, int count) {
    // For small counts force a single row sized to fill the width
    if (count <= 7) {
      const maxGap = 6.0;
      final s = (availW - (count - 1) * maxGap) / count;
      return s.clamp(4.0, 60.0);
    }
    double best = 4.0;
    for (double s = 4.0; s <= 60.0; s += 0.5) {
      final g = (s * 0.25).clamp(1.5, 6.0);
      final perRow = ((availW + g) / (s + g)).floor();
      if (perRow <= 0) break;
      final rows = ((count + perRow - 1) / perRow).ceil();
      final neededH = rows * s + (rows - 1) * g;
      if (neededH > availH) break;
      best = s;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final availDotsH =
          (constraints.maxHeight - _nameH - _nameGap).clamp(4.0, 300.0);
      final dotSize =
          _bestDotSize(constraints.maxWidth, availDotsH, dayKeys.length);
      final gap = (dotSize * 0.25).clamp(1.5, 6.0);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _nameH,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    habit,
                    style: const TextStyle(
                      fontFamily: 'FixelText',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (currentStreak >= 2) ...[
                  const Icon(Icons.arrow_upward, size: 9, color: Colors.black),
                  const SizedBox(width: 2),
                  Text(
                    '$currentStreak ${S.statsDaysSuffix}',
                    style: const TextStyle(
                      fontFamily: 'FixelText',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ] else if (maxStreak >= 2) ...[
                  const Icon(Icons.arrow_upward,
                      size: 9, color: Colors.black),
                  const SizedBox(width: 2),
                  Text(
                    '$maxStreak ${S.statsDaysSuffix}',
                    style: const TextStyle(
                      fontFamily: 'FixelText',
                      fontSize: 9,
                      color: Colors.black,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: _nameGap),
          if (dayKeys.length <= 7)
            Row(
              children: dayKeys.map((k) {
                final filled = filledKeys.contains(k);
                return Padding(
                  padding: EdgeInsets.only(right: k != dayKeys.last ? gap : 0),
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: filled ? Colors.black : Colors.black12,
                      borderRadius: BorderRadius.circular(dotSize / 2),
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: dayKeys.map((k) {
                final filled = filledKeys.contains(k);
                return Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: filled ? Colors.black : Colors.black12,
                    borderRadius: BorderRadius.circular(dotSize / 2),
                  ),
                );
              }).toList(),
            ),
        ],
      );
    });
  }
}

