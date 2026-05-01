import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/daily_entry.dart';
import '../providers/app_provider.dart';
import 'circumplex_buttons.dart';

class EditDayScreen extends StatefulWidget {
  final DateTime date;

  const EditDayScreen({super.key, required this.date});

  @override
  State<EditDayScreen> createState() => _EditDayScreenState();
}

class _EditDayScreenState extends State<EditDayScreen> {
  late double? _valence;
  late double? _arousal;
  late bool _isSick;
  late bool _hasPain;
  late Map<String, bool> _habits;

  @override
  void initState() {
    super.initState();
    final entry =
        context.read<AppProvider>().getOrCreateEntry(widget.date);
    _valence = entry.valence;
    _arousal = entry.arousal;
    _isSick = entry.isSick;
    _hasPain = entry.hasPain;
    _habits = Map<String, bool>.from(entry.habits);
  }

  void _save() {
    HapticFeedback.mediumImpact();
    final entry = DailyEntry(
      date: widget.date,
      valence: _valence,
      arousal: _arousal,
      isSick: _isSick,
      hasPain: _hasPain,
      habits: _habits,
    );
    context.read<AppProvider>().updateEntry(entry);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('d MMMM yyyy', 'uk_UA').format(widget.date);

    // Rebuild _habits keys if provider adds new habits (first open)
    final providerHabits =
        context.read<AppProvider>().getOrCreateEntry(widget.date).habits;
    for (final key in providerHabits.keys) {
      _habits.putIfAbsent(key, () => false);
    }

    final localEntry = DailyEntry(
      date: widget.date,
      valence: _valence,
      arousal: _arousal,
      isSick: _isSick,
      hasPain: _hasPain,
      habits: _habits,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.black),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Text(
                        dateLabel,
                        style:
                            Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),

                ],
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircumplexButtons(
                      title: S.editSubtitle,
                      valence: _valence,
                      arousal: _arousal,
                      onValenceChanged: (v) => setState(() => _valence = v),
                      onArousalChanged: (a) => setState(() => _arousal = a),
                      onValenceCleared: () => setState(() => _valence = null),
                      onArousalCleared: () => setState(() => _arousal = null),
                    ),

                    const SizedBox(height: 28),
                    _SectionLabel(S.editSectionHealth),
                    const SizedBox(height: 10),
                    _HealthToggles(
                      entry: localEntry,
                      onSickChanged: (v) => setState(() => _isSick = v),
                      onPainChanged: (v) => setState(() => _hasPain = v),
                    ),

                    const SizedBox(height: 28),
                    _SectionLabel(S.editSectionLeisure),
                    const SizedBox(height: 10),
                    _HabitList(
                      entry: localEntry,
                      onHabitChanged: (key, val) =>
                          setState(() => _habits[key] = val),
                    ),
                  ],
                ),
              ),
            ),

            // ── Save button ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      S.editBtnSave,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.headlineLarge,
      );
}

// ── Health toggles ────────────────────────────────────────────────────────────

class _HealthToggles extends StatelessWidget {
  final DailyEntry entry;
  final ValueChanged<bool> onSickChanged;
  final ValueChanged<bool> onPainChanged;

  const _HealthToggles({
    required this.entry,
    required this.onSickChanged,
    required this.onPainChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleButton(
            label: S.labelSick,
            isActive: entry.isSick,
            onTap: () {
              HapticFeedback.mediumImpact();
              onSickChanged(!entry.isSick);
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
              onPainChanged(!entry.hasPain);
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
  final void Function(String key, bool val) onHabitChanged;

  const _HabitList(
      {required this.entry, required this.onHabitChanged});

  @override
  State<_HabitList> createState() => _HabitListState();
}

class _HabitListState extends State<_HabitList> {
  String? _expandedHabit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.entry.habits.entries.map((e) {
        final checked = e.value;
        final desc = S.habitDescription(e.key);
        final expanded = _expandedHabit == e.key && desc.isNotEmpty;

        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onHabitChanged(e.key, !checked);
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
