import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/strings.dart';
import 'providers/app_provider.dart';
import 'screens/history_view.dart';
import 'screens/settings_view.dart';
import 'screens/onboarding_screen.dart';
import 'screens/stats_view.dart';
import 'screens/today_view.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await S.load();

  // Force portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Light status bar icons on white background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final appProvider = AppProvider();

  // Never block runApp() — SharedPreferences.getInstance() is a platform
  // channel call that can stall on a fresh iOS install (same root cause as the
  // timezone channel hang). runApp() is called immediately; the app shows a
  // blank white screen until initialization completes (isInitialized = true).
  runApp(
    ChangeNotifierProvider.value(
      value: appProvider,
      child: const AtensiaApp(),
    ),
  );

  // Load persisted data, then initialize notifications — both in the background.
  unawaited(_initAppData(appProvider));
}

/// Loads persisted data and initializes the notification plugin concurrently.
/// Both run after [runApp] so that no platform channel call can prevent
/// the app from rendering.
Future<void> _initAppData(AppProvider appProvider) async {
  // Kick off notification plugin init at the same time as data loading so the
  // plugin is ready (or very nearly so) by the time the UI becomes interactive.
  unawaited(_initNotificationPlugin());
  await appProvider.init();
  // Schedule the daily reminder now that both data and the plugin are ready.
  // NotificationService.schedule() internally waits for plugin init to finish.
  if (appProvider.remindersEnabled) {
    try {
      await NotificationService.instance.schedule(
        appProvider.reminderTime,
        enabled: true,
      );
    } catch (e) {
      debugPrint('NotificationService: failed to schedule on startup ($e).');
    }
  }
}

/// Initializes the notification plugin. Errors are caught so a stalled or
/// failing channel cannot prevent the rest of the app from working.
Future<void> _initNotificationPlugin() async {
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('NotificationService: init failed on startup ($e).');
  }
}

class AtensiaApp extends StatelessWidget {
  const AtensiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return MaterialApp(
      title: S.appTitle,
      debugShowCheckedModeBanner: false,

      // ── Localization ──────────────────────────────────────────────────────
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('uk', 'UA'), Locale('en', 'US')],
      locale: provider.flutterLocale,

      // ── Theme ─────────────────────────────────────────────────────────────
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'FixelText',
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          secondary: Colors.black,
          onSecondary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontFamily: 'FixelDisplay',
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: Colors.black,
            height: 1.2,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'FixelDisplay',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black54,
          ),
          titleMedium: TextStyle(
            fontFamily: 'FixelText',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'FixelText',
            fontSize: 16,
            color: Colors.black,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'FixelText',
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        dividerColor: Colors.black,
        dividerTheme: const DividerThemeData(
          color: Colors.black,
          thickness: 2,
          space: 0,
        ),
      ),

      home: Consumer<AppProvider>(
        builder: (_, provider, __) {
          if (!provider.isInitialized) {
            // Blank white screen that visually continues the native launch
            // screen while SharedPreferences and other platform channels load.
            return const Scaffold(backgroundColor: Colors.white);
          }
          return provider.isFirstLaunch
              ? const OnboardingScreen()
              : const MainScreen();
        },
      ),
    );
  }
}

// ── Main screen with bottom navigation ───────────────────────────────────────

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 1;
  int _historyKey = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>(); // rebuild on locale/data change
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEntry = provider.getOrCreateEntry(today);
    final todayHasEntry = todayEntry.hasState ||
        todayEntry.isSick ||
        todayEntry.hasPain ||
        todayEntry.habits.values.any((v) => v);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HistoryView(key: ValueKey(_historyKey)),
          const TodayView(),
          const StatsView(),
          const SettingsView(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top border line (no shadow, consistent with B&W aesthetic)
          Container(height: 2, color: Colors.black),
          BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() {
              if (i == 0 && _index != 0) _historyKey++;
              _index = i;
            }),
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black,
            unselectedItemColor: const Color(0xFF999999),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontFamily: 'FixelText',
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'FixelText',
              fontSize: 11,
            ),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_month_outlined),
                activeIcon: const Icon(Icons.calendar_month),
                label: S.tabCalendar,
              ),
              BottomNavigationBarItem(
                icon: todayHasEntry
                    ? const _NavDot(Icons.wb_sunny_outlined)
                    : const Icon(Icons.wb_sunny_outlined),
                activeIcon: const Icon(Icons.wb_sunny),
                label: S.tabToday,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.bar_chart_outlined),
                activeIcon: const Icon(Icons.bar_chart),
                label: S.tabStats,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.tune_outlined),
                activeIcon: const Icon(Icons.tune),
                label: S.tabSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Small dot badge overlaid on a bottom-nav icon to signal pending/filled state.
class _NavDot extends StatelessWidget {
  final IconData icon;
  const _NavDot(this.icon);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -3,
          top: -1,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
