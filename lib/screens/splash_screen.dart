import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/app_provider.dart';
import '../main.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  // Kept so the listener can be removed on dispose if init() outlasts the screen.
  AppProvider? _providerRef;
  VoidCallback? _initListener;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    // Minimum splash display time before we attempt navigation.
    Future.delayed(const Duration(milliseconds: 1400), _onDelayComplete);
  }

  /// Called after the minimum splash duration has elapsed. Navigates
  /// immediately when [AppProvider.isInitialized] is already true, otherwise
  /// waits for the provider to signal completion — avoids the race condition
  /// where [isFirstLaunch] is read before SharedPreferences has loaded.
  void _onDelayComplete() {
    if (!mounted) return;
    final provider = context.read<AppProvider>();
    if (provider.isInitialized) {
      _navigate(provider);
    } else {
      // init() hasn't finished yet — add a one-shot listener.
      _providerRef = provider;
      _initListener = () {
        if (!provider.isInitialized) return;
        _removeInitListener();
        if (!mounted) return;
        _navigate(provider);
      };
      provider.addListener(_initListener!);
    }
  }

  void _removeInitListener() {
    if (_initListener != null) {
      _providerRef?.removeListener(_initListener!);
    }
    _providerRef = null;
    _initListener = null;
  }

  void _navigate(AppProvider provider) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            provider.isFirstLaunch ? const OnboardingScreen() : const MainScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _removeInitListener();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/atensia-logo.png',
                width: 72,
                height: 72,
              ),
              const SizedBox(height: 20),
              Text(
                S.appTitle,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 42,
                      color: Colors.black,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                S.appTagline,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.black,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
