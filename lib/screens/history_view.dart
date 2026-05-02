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
              'Календар',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),

          // ── Calendar ──────────────────────────────────────────────────────
          SizedBox(
            height: 345,
            child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TableCalendar(
              locale: 'uk_UA',
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

          const Divider(color: Colors.black, thickness: 2, height: 2),
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
      final dateLabel = DateFormat('d MMMM yyyy', 'uk_UA').format(date);
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
      final dateLabel = DateFormat('d MMMM yyyy', 'uk_UA').format(date);
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
    final doneHabits = e.habits.entries
        .where((h) => h.value)
        .map((h) => h.key)
        .toList();

    final rows = <_InfoRow>[
      if (e.hasState)
        _InfoRow(S.calendarRowFeel, S.circumplexQuadrant(e.valence!, e.arousal!)),
      if (healthItems.isNotEmpty)
        _InfoRow(S.calendarRowHealth, healthItems.join(', ')),
      if (doneHabits.isNotEmpty)
        _InfoRow(S.calendarRowLeisure, doneHabits.join(', ')),
    ];
    final comment = e.comment;

    final dateLabel = DateFormat('d MMMM yyyy', 'uk_UA').format(date);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // centered date
          Text(
            dateLabel,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),

          // grouped rows
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      '${row.key}:',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (comment != null && comment.isNotEmpty) ...
            [
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      '${S.calendarRowNote}:',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      comment,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],

          const SizedBox(height: 16),

          // edit button full-width below list
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
                S.calendarBtnEdit,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String key;
  final String value;
  const _InfoRow(this.key, this.value);
}
