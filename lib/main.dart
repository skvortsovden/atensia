import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'screens/history_view.dart';
import 'screens/settings_view.dart';
import 'screens/splash_screen.dart';
import 'screens/today_view.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  await appProvider.init();

  await NotificationService.instance.init();
  if (appProvider.remindersEnabled) {
    await NotificationService.instance.schedule(
      appProvider.reminderTime,
      enabled: true,
    );
  }

  runApp(
    ChangeNotifierProvider.value(
      value: appProvider,
      child: const AtensiaApp(),
    ),
  );
}

class AtensiaApp extends StatelessWidget {
  const AtensiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Атенція',
      debugShowCheckedModeBanner: false,

      // ── Localization ──────────────────────────────────────────────────────
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('uk', 'UA')],
      locale: const Locale('uk', 'UA'),

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
            fontSize: 30,
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

      home: const SplashScreen(),
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
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HistoryView(key: ValueKey(_historyKey)),
          const TodayView(),
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
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                activeIcon: Icon(Icons.calendar_month),
                label: 'Календар',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.wb_sunny_outlined),
                activeIcon: Icon(Icons.wb_sunny),
                label: 'Сьогодні',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.tune_outlined),
                activeIcon: Icon(Icons.tune),
                label: 'Налаштування',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
