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

class TrendChartCard extends StatefulWidget {
  const TrendChartCard({
    super.key,
    required this.entries,
    required this.totalDays,
    required this.periodEnd,
  });

  final List<DailyEntry> entries;
  final int totalDays;
  final DateTime periodEnd;

  @override
  State<TrendChartCard> createState() => _TrendChartCardState();
}

class _TrendChartCardState extends State<TrendChartCard> {

  @override
  Widget build(BuildContext context) {
    final start = widget.periodEnd.subtract(Duration(days: widget.totalDays - 1));
    final aggregate = widget.totalDays > 30;
    final entryMap = {
      for (final e in widget.entries) AppProvider.dateKey(e.date): e
    };

    final List<FlSpot> valenceSpots;
    final List<FlSpot> healthSpots;
    final int xCount;
    final String Function(double) xLabel;

    if (!aggregate) {
      final valenceList = <FlSpot>[];
      final healthList = <FlSpot>[];

      for (int i = 0; i < widget.totalDays; i++) {
        final d = start.add(Duration(days: i));
        final e = entryMap[AppProvider.dateKey(d)];
        if (e != null && e.valence != null) {
          valenceList.add(FlSpot(i.toDouble(), e.valence!));
        }
        final h = (e != null && (e.isSick || e.hasPain)) ? -1.0 : 0.0;
        healthList.add(FlSpot(i.toDouble(), h));
      }
      valenceSpots = valenceList;
      healthSpots = healthList;
      xCount = widget.totalDays;

      if (widget.totalDays <= 7) {
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
      for (final e in widget.entries) {
        final wi = e.date.difference(start).inDays ~/ 7;
        weeks.putIfAbsent(wi, () => []).add(e);
      }
      final wCount = (widget.totalDays / 7).ceil();
      final valenceList = <FlSpot>[];
      final healthList = <FlSpot>[];

      for (int wi = 0; wi < wCount; wi++) {
        final we = weeks[wi] ?? [];
        if (we.isNotEmpty) {
          final vEntries = we.where((e) => e.valence != null).toList();
          if (vEntries.isNotEmpty) {
            final avgV = vEntries.map((e) => e.valence!).reduce((a, b) => a + b) / vEntries.length;
            valenceList.add(FlSpot(wi.toDouble(), avgV));
          }
        }
        final sickCount = (weeks[wi] ?? []).where((e) => e.isSick || e.hasPain).length;
        healthList.add(FlSpot(wi.toDouble(), sickCount > 0 ? -1.0 : 0.0));
      }
      valenceSpots = valenceList;
      healthSpots = healthList;
      xCount = wCount;

      xLabel = (v) {
        final wi = v.round();
        final d = start.add(Duration(days: wi * 7));
        if (wi == 0) return DateFormat('MMM', 'uk').format(d);
        final prev = start.add(Duration(days: (wi - 1) * 7));
        if (d.month != prev.month) return DateFormat('MMM', 'uk').format(d);
        return '';
      };
    }

    return _cardShell(
      title: S.statsSectionTrend,
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: -1.4,
                maxY: 1.4,
                minX: 0,
                maxX: (xCount - 1).toDouble(),
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  checkToShowHorizontalLine: (v) => v == -1 || v == 0 || v == 1,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: v == 0 ? Colors.black26 : Colors.black12,
                    strokeWidth: v == 0 ? 1.5 : 1,
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
                      reservedSize: 56,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if ((value - value.round()).abs() > 0.01) {
                          return const SizedBox.shrink();
                        }
                        final v = value.round();
                        final label = switch (v) {
                          -1 => S.todayValenceLow,
                           0 => S.todayValenceMid,
                           1 => S.todayValenceHigh,
                          _ => '',
                        };
                        if (label.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            label.toLowerCase(),
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
                    maxContentWidth: 220,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipColor: (_) => Colors.black87,
                    getTooltipItems: (spots) {
                      return spots.map((s) {
                        if (s.barIndex != 0) return null;
                        final int dayIndex = s.x.round();
                        final DateTime tappedDate = aggregate
                            ? start.add(Duration(days: dayIndex * 7))
                            : start.add(Duration(days: dayIndex));
                        final e = entryMap[AppProvider.dateKey(tappedDate)];
                        final dateLabel =
                            DateFormat('d MMM', 'uk').format(tappedDate);

                        final children = <TextSpan>[];
                        if (e == null) {
                          children.add(TextSpan(
                            text: '\n${S.calendarNoData}',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 11),
                          ));
                        } else {
                          if (e.hasState) {
                            children.add(TextSpan(
                              text:
                                  '\n${S.circumplexQuadrant(e.valence!, e.arousal!)}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ));
                          }
                          final healthItems = [
                            if (e.isSick) S.labelSick,
                            if (e.hasPain) S.labelPain,
                          ];
                          if (healthItems.isNotEmpty) {
                            children.add(TextSpan(
                              text: '\n${healthItems.join(', ')}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11),
                            ));
                          }
                          final doneHabits = e.habits.entries
                              .where((h) => h.value)
                              .map((h) => h.key)
                              .toList();
                          if (doneHabits.isNotEmpty) {
                            children.add(TextSpan(
                              text: '\n${doneHabits.join(', ')}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11),
                            ));
                          }
                          if (e.comment != null && e.comment!.isNotEmpty) {
                            children.add(TextSpan(
                              text: '\n${e.comment}',
                              style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic),
                            ));
                          }
                        }

                        return LineTooltipItem(
                          dateLabel,
                          const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                          children: children,
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  // Valence — dashed black (index 0)
                  LineChartBarData(
                    spots: valenceSpots,
                    color: Colors.black,
                    barWidth: 2,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    dashArray: [6, 4],
                    dotData: FlDotData(
                      show: widget.totalDays <= 30,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3,
                        color: Colors.black,
                        strokeWidth: 0,
                        strokeColor: Colors.transparent,
                      ),
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // Health — solid black (index 1)
                  LineChartBarData(
                    spots: healthSpots,
                    color: Colors.black,
                    barWidth: 1.5,
                    isCurved: false,
                    dotData: const FlDotData(show: false),
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
              _LegendItem(color: Colors.black, dashed: true, label: S.statsSectionMood),
              const SizedBox(width: 16),
              _LegendItem(color: Colors.black, dashed: false, label: S.statsSectionHealth),
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
    required this.periodEnd,
  });

  final List<DailyEntry> entries;
  final int totalDays;
  final String periodLabel;
  final DateTime periodEnd;

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
    final start = widget.periodEnd.subtract(Duration(days: widget.totalDays - 1));

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
                            const Icon(Icons.arrow_upward, size: 12, color: Colors.black),
                            const SizedBox(width: 2),
                            Text(
                              '$currentStreak ${S.statsDaysSuffix} поспіль',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
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
                              '$maxStreak ${S.statsDaysSuffix} поспіль',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black),
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
                      final isFuture = allDays[i].isAfter(today);
                      final Color color;
                      if (isFuture) {
                        color = Colors.black.withValues(alpha: 0.06);
                      } else if (filled) {
                        color = Colors.black;
                      } else {
                        color = Colors.black12;
                      }
                      return Container(
                        width: dotSize,
                        height: dotSize,
                        decoration: BoxDecoration(
                          color: color,
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
        periodEnd: widget.periodEnd,
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
    required this.periodEnd,
    required this.shareOrigin,
  });

  final List<DailyEntry> entries;
  final int totalDays;
  final String periodLabel;
  final DateTime periodEnd;
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
    final start = widget.periodEnd.subtract(Duration(days: widget.totalDays - 1));
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
                          periodEnd: widget.periodEnd,
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
    required this.periodEnd,
    this.excludedHabits = const {},
  });

  final List<DailyEntry> entries;
  final int totalDays;
  final String periodLabel;
  final DateTime periodEnd;
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
    final start = periodEnd.subtract(Duration(days: totalDays - 1));
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
                        today: today,
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
                            DateFormat('d MMMM', 'uk').format(DateTime.now()),
                            style: const TextStyle(
                              fontFamily: 'FixelText',
                              fontSize: 9,
                              color: Colors.black45,
                            ),
                          ),
                          Text(
                            DateFormat('yyyy', 'uk').format(DateTime.now()),
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
    required this.today,
  });

  final String habit;
  final List<String> dayKeys;
  final Set<String> filledKeys;
  final int currentStreak;
  final int maxStreak;
  final DateTime today;

  static const double _nameH = 16.0;
  static const double _nameGap = 5.0;

  /// Largest dot size where all [count] dots fit within [availW] × [availH].
  double _bestDotSize(double availW, double availH, int count) {
    // For small counts force a single row sized to fill the width, but cap at height
    if (count <= 7) {
      const maxGap = 6.0;
      final s = (availW - (count - 1) * maxGap) / count;
      return s.clamp(4.0, availH.clamp(4.0, 60.0));
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
                    '$currentStreak ${S.statsDaysSuffix} поспіль',
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
                    '$maxStreak ${S.statsDaysSuffix} поспіль',
                    style: const TextStyle(
                      fontFamily: 'FixelText',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
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
                final isFuture = DateTime.parse(k).isAfter(today);
                final color = isFuture
                    ? Colors.black.withValues(alpha: 0.06)
                    : filled ? Colors.black : Colors.black12;
                return Padding(
                  padding: EdgeInsets.only(right: k != dayKeys.last ? gap : 0),
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: color,
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
                final isFuture = DateTime.parse(k).isAfter(today);
                final color = isFuture
                    ? Colors.black.withValues(alpha: 0.06)
                    : filled ? Colors.black : Colors.black12;
                return Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: color,
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

