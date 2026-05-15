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
  late final TextEditingController _commentCtrl;

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
    _commentCtrl = TextEditingController(text: entry.comment ?? '');
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
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
      comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
    );
    context.read<AppProvider>().updateEntry(entry);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('d MMMM yyyy', S.dateLocale).format(widget.date);

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
                    _HealthRow(
                      isSick: _isSick,
                      hasPain: _hasPain,
                      onSickTap: () => setState(() => _isSick = !_isSick),
                      onPainTap: () => setState(() => _hasPain = !_hasPain),
                    ),

                    const SizedBox(height: 28),
                    _SectionLabel(S.editSectionLeisure),
                    const SizedBox(height: 10),
                    _HabitList(
                      entry: localEntry,
                      onHabitChanged: (key, val) =>
                          setState(() => _habits[key] = val),
                    ),

                    const SizedBox(height: 28),
                    _SectionLabel(S.editSectionNote),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _commentCtrl,
                      maxLines: null,
                      maxLength: 140,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: S.editNoteHint,
                        hintStyle: const TextStyle(
                            color: Colors.black38, fontSize: 14),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        counterStyle: const TextStyle(
                            color: Colors.black38, fontSize: 11),
                      ),
                      style: const TextStyle(fontSize: 14),
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

// ── Shared checkbox row ───────────────────────────────────────────────────────

class _CheckboxRow extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTap;

  const _CheckboxRow({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      selected: checked,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: checked ? const Color(0xFFE8E8E8) : Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: checked ? Colors.black : Colors.transparent,
                  border: Border.all(
                    color: checked ? Colors.transparent : Colors.black,
                    width: 2,
                  ),
                ),
                child: checked
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Health row ────────────────────────────────────────────────────────────────

class _HealthRow extends StatelessWidget {
  final bool isSick;
  final bool hasPain;
  final VoidCallback onSickTap;
  final VoidCallback onPainTap;

  const _HealthRow({
    required this.isSick,
    required this.hasPain,
    required this.onSickTap,
    required this.onPainTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.editSectionHealth.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        _CheckboxRow(
          label: S.labelSick,
          checked: isSick,
          onTap: () {
            HapticFeedback.mediumImpact();
            onSickTap();
          },
        ),
        _CheckboxRow(
          label: S.labelPain,
          checked: hasPain,
          onTap: () {
            HapticFeedback.mediumImpact();
            onPainTap();
          },
        ),
      ],
    );
  }
}

// ── Habit list ────────────────────────────────────────────────────────────────

class _HabitList extends StatelessWidget {
  final DailyEntry entry;
  final void Function(String key, bool val) onHabitChanged;

  const _HabitList({required this.entry, required this.onHabitChanged});

  @override
  Widget build(BuildContext context) {
    final displayNames = S.defaultHabits;
    final storedKeys = entry.habits.keys.toList();

    return Column(
      children: List.generate(displayNames.length, (i) {
        final storedKey = i < storedKeys.length ? storedKeys[i] : displayNames[i];
        final checked = entry.habits[storedKey] ?? false;

        return _CheckboxRow(
          label: displayNames[i],
          checked: checked,
          onTap: () {
            HapticFeedback.mediumImpact();
            onHabitChanged(storedKey, !checked);
          },
        );
      }),
    );
  }
}
