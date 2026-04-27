Flutter Implementation Guide: Proso (Просо)

This guide provides a structured prompt and architectural plan to rebuild the React prototype as a high-quality Flutter mobile application named Proso, featuring a Ukrainian interface, a minimalist black-and-white design, and local-only storage.

1. Copilot Prompt

Copy and paste this prompt into Copilot (or a similar tool) to generate the base project structure:

"Act as a Senior Flutter Developer. Create a minimal, single-package mobile app for habit and health tracking named 'Proso' (Просо).

Language Requirements:

The entire interface must be in Ukrainian.

Main question: 'Як ся маєш?' (How do you feel?).

Mood states: 'Виснажено', 'Добре', 'Бадьоро'.

Health toggles: 'Відчуваю хворобу' (Sick), 'Відчуваю біль' (In pain).

Navigation tabs: 'Сьогодні' (Today), 'Календар' (History), 'Налаштування' (Settings).

Habits: 'Прогулянка' (Walking), 'Фізична активність' (Physical activity), 'Читання' (Reading).

Architecture:

Use Provider or flutter_riverpod for state management.

Use shared_preferences or hive for local-only data persistence (no cloud/auth).

Structure: One main screen with a BottomNavigationBar switching between three widgets: TodayView, HistoryView (Calendar), and SettingsView.

Features:

TodayView: A list of habit checkboxes, a selectable grid for mood, and toggle buttons for health status.

HistoryView: Use table_calendar to show a monthly view. Highlight days with dots: Black for 'Sick' and a clean outline or heavy black circle for 'Healthy/Habits completed'.

SettingsView: A simple text field to edit 'Ім'я користувача' and a toggle for 'Нагадування'.

UI Style (Minimalist Black & White):

Theme: Pure high-contrast Black and White.

Colors: Background #FFFFFF, Primary Text #000000, Secondary Accents #F2F2F2.

Typography: Use the Fixel font family by MacPaw (specifically Fixel Display for headers and Fixel Text for body).

Design: Sharp lines or very subtle rounded corners (8dp), no shadows, using heavy borders (2px) instead of depth for cards.

Ensure all data is saved locally on every change."

2. Recommended Package Dependencies

Add these to your pubspec.yaml:

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations: 
    sdk: flutter
  lucide_icons: ^0.3.0
  table_calendar: ^3.1.0
  shared_preferences: ^2.2.2
  provider: ^6.1.2

flutter:
  fonts:
    - family: Fixel
      fonts:
        - asset: assets/fonts/FixelText-Regular.ttf
        - asset: assets/fonts/FixelText-Bold.ttf
          weight: 700


3. Key Implementation Logic

Data Model

Define a simple class to represent a daily entry:

class DailyEntry {
  final DateTime date;
  final Map<String, bool> habits;
  final String mood;
  final bool isSick;
  final bool hasPain;

  DailyEntry({
    required this.date,
    required this.habits,
    required this.mood,
    required this.isSick,
    required this.hasPain,
  });

  // Include toJson and fromJson for local storage
}


Local Storage Strategy

Since you want no cloud data, use shared_preferences for the username and settings, and path_provider + a JSON file (or a library like Hive) to store the Map<String, DailyEntry> where the key is a date string like 2024-05-15.

Calendar Integration (Ukrainian)

To ensure the calendar displays months and days in Ukrainian, wrap your MaterialApp with localizations:

return MaterialApp(
  theme: ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Fixel', // Set Fixel as the default font
    textTheme: TextTheme(
      headlineLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: Colors.black),
    ),
  ),
  localizationsDelegates: [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: [
    Locale('uk', 'UA'),
  ],
  locale: Locale('uk', 'UA'),
  // ...
);


4. UI Layout Tips

B&W Aesthetic: Use Colors.black for active states and Colors.white for the background. For inactive habits, use a thin Border.all(color: Colors.black12).

Typography: Leverage Fixel's excellent readability by using different weights (Bold for headers, Regular for labels) rather than different colors.

Vibration: Add HapticFeedback.mediumImpact() when a status is toggled to reinforce the physical feel of the minimalist UI.

Safe Area: Ensure buttons aren't clipped by the home indicator by using SafeArea and Padding.