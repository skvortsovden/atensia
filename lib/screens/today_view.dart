import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/daily_entry.dart';
import '../providers/app_provider.dart';

class TodayView extends StatelessWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final today = _today();
    final entry = provider.getOrCreateEntry(today);
    final greeting = provider.username.isNotEmpty
        ? 'Вітаю, ${provider.username}!'
        : 'Вітаю, друже!';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Як ся маєш?',
              style: Theme.of(context).textTheme.headlineLarge,
            ),

            const SizedBox(height: 10),
            _MoodSelector(entry: entry, date: today),

            const SizedBox(height: 28),
            _SectionLabel('Щось турбує?'),
            const SizedBox(height: 10),
            _HealthToggles(entry: entry, date: today),

            const SizedBox(height: 28),
            _SectionLabel('Дозвілля'),
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

// ── Mood selector ─────────────────────────────────────────────────────────────

class _MoodSelector extends StatelessWidget {
  final DailyEntry entry;
  final DateTime date;

  const _MoodSelector({required this.entry, required this.date});

  static const _moods = [
    'Виснажено',
    'Добре',
    'Бадьоро',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _moods.length,
      itemBuilder: (context, i) {
        final mood = _moods[i];
        final selected = entry.mood == mood;

        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            provider.setMood(date, selected ? '' : mood);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: selected ? Colors.black : Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              mood,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        );
      },
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
            label: 'Хвороба',
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
            label: 'Біль',
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

class _HabitList extends StatelessWidget {
  final DailyEntry entry;
  final DateTime date;

  const _HabitList({required this.entry, required this.date});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();

    return Column(
      children: entry.habits.entries.map((e) {
        final checked = e.value;

        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            provider.toggleHabit(date, e.key);
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
            child: Row(
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
                Text(
                  e.key,
                  style: TextStyle(
                    color: checked ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
