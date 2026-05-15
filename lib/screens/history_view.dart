import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../l10n/strings.dart';
import '../models/daily_entry.dart';
import '../providers/app_provider.dart';
import 'edit_day_screen.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _focusedDay = today;
    _selectedDay = today;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              S.calendarTitle,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),

          // ── Calendar ──────────────────────────────────────────────────────
          SizedBox(
            height: 345,
            child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TableCalendar(
              key: ValueKey(S.dateLocale),
              locale: S.dateLocale,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              startingDayOfWeek: StartingDayOfWeek.monday,
              rowHeight: 44,
              daysOfWeekHeight: 22,
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              onPageChanged: (focused) {
                setState(() => _focusedDay = focused);
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, _) {
                  final entry = provider.entries[AppProvider.dateKey(day)];
                  if (entry == null) return const SizedBox.shrink();
                  return Positioned(
                    bottom: 3,
                    child: _DayMarker(entry: entry),
                  );
                },
                // Custom header: "Травень 2026" — capitalized standalone
                // month name, no "р." abbreviation.
                headerTitleBuilder: (context, day) {
                  final monthRaw =
                      DateFormat('LLLL', S.dateLocale).format(day);
                  final month = monthRaw.isEmpty
                      ? monthRaw
                      : '${monthRaw[0].toUpperCase()}${monthRaw.substring(1)}';
                  return Center(
                    child: Text(
                      '$month ${day.year}',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                    ),
                  );
                },
              ),
              calendarStyle: CalendarStyle(
                // Today: outlined circle
                todayDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                todayTextStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                // Selected: filled circle
                selectedDecoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                defaultTextStyle:
                    const TextStyle(color: Colors.black, fontSize: 16),
                weekendTextStyle:
                    const TextStyle(color: Colors.black54, fontSize: 16),
                outsideTextStyle:
                    const TextStyle(color: Colors.black26, fontSize: 16),
                markersMaxCount: 1,
                markerDecoration: const BoxDecoration(),
                cellMargin: const EdgeInsets.all(1),
              ),
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                leftChevronIcon:
                    const Icon(Icons.chevron_left, color: Colors.black, size: 20),
                rightChevronIcon:
                    const Icon(Icons.chevron_right, color: Colors.black, size: 20),
                headerPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                headerMargin: EdgeInsets.zero,
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
                weekendStyle: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
          ),
          ),

          const Divider(color: Color(0xFFE5E5E5), thickness: 1, height: 1),
          const SizedBox(height: 12),

          // ── Day detail ────────────────────────────────────────────────────
          Expanded(
            child: _DayDetail(
              date: _selectedDay,
              entry: provider.entries[AppProvider.dateKey(_selectedDay)],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Calendar day marker ───────────────────────────────────────────────────────

class _DayMarker extends StatelessWidget {
  final DailyEntry entry;
  const _DayMarker({required this.entry});

  @override
  Widget build(BuildContext context) {
    // Black filled dot = sick
    if (entry.isSick) {
      return Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
      );
    }

    final habitsCompleted = entry.habits.values.where((v) => v).length;
    final total = entry.habits.length;

    if (habitsCompleted == total && total > 0) {
      // All habits done: heavy filled circle
      return Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
      );
    }

    if (habitsCompleted > 0 || entry.hasState) {
      // Some activity: outline circle
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 1.5),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ── Selected day detail ───────────────────────────────────────────────────────

class _DayDetail extends StatelessWidget {
  final DateTime date;
  final DailyEntry? entry;

  const _DayDetail({required this.date, required this.entry});

  bool _hasData(DailyEntry? entry) {
    if (entry == null) return false;
    return entry.hasState ||
        entry.isSick ||
        entry.hasPain ||
        entry.habits.values.any((v) => v);
  }

  void _openEdit(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditDayScreen(date: date),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final dateMidnight = DateTime(date.year, date.month, date.day);
    final isFuture = dateMidnight.isAfter(todayMidnight);

    if (isFuture) {
      final dateLabel = DateFormat('d MMMM yyyy', S.dateLocale).format(date);
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              dateLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            Text(
              S.calendarFutureDay,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black38),
            ),
          ],
        ),
      );
    }

    final hasData = _hasData(entry);

    if (!hasData) {
      final dateLabel = DateFormat('d MMMM yyyy', S.dateLocale).format(date);
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              dateLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            Text(
              S.calendarNoData,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black38),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _openEdit(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  S.calendarBtnAdd,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final e = entry!;

    final healthItems = [
      if (e.isSick) S.labelSick,
      if (e.hasPain) S.labelPain,
    ];
    final storedKeys = e.habits.keys.toList();
    final displayNames = S.defaultHabits;
    final doneHabits = <String>[
      for (int i = 0; i < storedKeys.length && i < displayNames.length; i++)
        if (e.habits[storedKeys[i]] == true) displayNames[i],
    ];

    final comment = e.comment;
    final dateLabel = DateFormat('d MMMM yyyy', S.dateLocale).format(date);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date + edit link ────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              GestureDetector(
                onTap: () => _openEdit(context),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 4),
                  child: Text(
                    S.calendarBtnEdit,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── State heading (derived from valence/arousal) ─────────────────
          if (e.hasState) ...[
            const SizedBox(height: 12),
            Text(
              S.circumplexQuadrant(e.valence!, e.arousal!),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],

          // ── Concerns ─────────────────────────────────────────────────────
          if (healthItems.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SummaryLabel(S.calendarRowHealth),
            const SizedBox(height: 4),
            Text(healthItems.join(', '), style: _kSummaryValueStyle),
          ],

          // ── Leisure ──────────────────────────────────────────────────────
          if (doneHabits.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SummaryLabel(S.calendarRowLeisure),
            const SizedBox(height: 4),
            Text(doneHabits.join(', '), style: _kSummaryValueStyle),
          ],

          // ── Note ─────────────────────────────────────────────────────────
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SummaryLabel(S.calendarRowNote),
            const SizedBox(height: 4),
            Text(
              comment,
              style: _kSummaryValueStyle.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Summary section helpers ──────────────────────────────────────────────────

const _kSummaryValueStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w500,
  color: Colors.black,
  height: 1.35,
);

class _SummaryLabel extends StatelessWidget {
  final String text;
  const _SummaryLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Colors.black54,
      ),
    );
  }
}
