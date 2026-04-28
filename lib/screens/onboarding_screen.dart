import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/app_provider.dart';
import '../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;

  void _nextPage() {
    FocusScope.of(context).unfocus();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _finish() {
    final provider = context.read<AppProvider>();
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      provider.setUsername(name);
    }
    provider.markLaunched();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Page indicator dots
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? Colors.black : Colors.black26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _NamePage(
                    controller: _nameController,
                    onContinue: _nextPage,
                  ),
                  _MottoPage(onContinue: _nextPage),
                  _GuidePage(onFinish: _finish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 1: Name input ──────────────────────────────────────────────────────

class _NamePage extends StatelessWidget {
  const _NamePage({required this.controller, required this.onContinue});

  final TextEditingController controller;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 3),
          Text(
            S.onboardingNameTitle,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              hintText: S.onboardingNameHint,
              hintStyle: const TextStyle(color: Colors.black38),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black26, width: 1.5),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            onSubmitted: (_) => onContinue(),
          ),
          const Spacer(flex: 4),
          _PrimaryButton(label: S.onboardingNameBtn, onTap: onContinue),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Page 2: Motto ───────────────────────────────────────────────────────────

class _MottoPage extends StatelessWidget {
  const _MottoPage({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 3),
          Text(
            S.onboardingMottoTitle,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              color: Colors.black,
              height: 1.3,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(flex: 4),
          _PrimaryButton(label: S.onboardingMottoBtn, onTap: onContinue),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Page 3: Guide ───────────────────────────────────────────────────────────

class _GuidePage extends StatelessWidget {
  const _GuidePage({required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          Text(
            S.onboardingGuideTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            S.onboardingGuideText,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          const Spacer(flex: 3),
          _PrimaryButton(label: S.onboardingGuideBtn, onTap: onFinish),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Shared button ───────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
