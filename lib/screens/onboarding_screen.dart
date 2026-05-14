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
    context.watch<AppProvider>(); // rebuild all pages when locale changes
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
                children: List.generate(5, (i) {
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
                  _LanguagePage(onContinue: _nextPage),
                  _NamePage(
                    controller: _nameController,
                    onContinue: _nextPage,
                  ),
                  _GreetingPage(
                    nameController: _nameController,
                    onContinue: _nextPage,
                  ),
                  _NotificationsPage(onContinue: _nextPage),
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

// ── Page 0: Language selection ──────────────────────────────────────────────

class _LanguagePage extends StatelessWidget {
  const _LanguagePage({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          Center(
            child: Image.asset('assets/atensia-logo.png', height: 56),
          ),
          const SizedBox(height: 40),
          const Text(
            'Мова / Language',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              for (final opt in [('uk', 'Українська'), ('en', 'English')])
                Expanded(
                  child: GestureDetector(
                    onTap: () => provider.setLocale(opt.$1),
                    child: Container(
                      margin: opt.$1 == 'uk'
                          ? const EdgeInsets.only(right: 8)
                          : EdgeInsets.zero,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: provider.locale == opt.$1
                            ? Colors.black
                            : Colors.transparent,
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        opt.$2,
                        style: TextStyle(
                          fontFamily: 'FixelText',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: provider.locale == opt.$1
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(flex: 3),
          _PrimaryButton(label: S.onboardingNameBtn, onTap: onContinue),
          const SizedBox(height: 32),
        ],
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
            maxLength: 30,
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

// ── Page 2: Greeting ────────────────────────────────────────────────────────

class _GreetingPage extends StatelessWidget {
  const _GreetingPage({
    required this.nameController,
    required this.onContinue,
  });

  final TextEditingController nameController;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final name = nameController.text.trim();
    final title = name.isNotEmpty
        ? S.onboardingGreetingTitle(name)
        : S.onboardingGreetingTitleDefault;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            S.onboardingGreetingText,
            style: const TextStyle(
              fontSize: 18,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          const Spacer(flex: 3),
          _PrimaryButton(label: S.onboardingGreetingBtn, onTap: onContinue),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Page 3: Notifications ───────────────────────────────────────────────────

class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Text(
                S.onboardingNotificationsTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                S.onboardingNotificationsDesc,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              // Toggle row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      S.settingsReminders,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Switch(
                      value: provider.remindersEnabled,
                      onChanged: (v) => provider.setReminders(v),
                      activeColor: Colors.black,
                      activeTrackColor: Colors.black26,
                      inactiveThumbColor: Colors.black38,
                      inactiveTrackColor: Colors.black12,
                    ),
                  ],
                ),
              ),
              if (provider.remindersEnabled) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: provider.reminderTime,
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      ),
                    );
                    if (picked != null) provider.setReminderTime(picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          S.settingsReminderTime,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const Spacer(),
                        Text(
                          '${provider.reminderTime.hour.toString().padLeft(2, '0')}:${provider.reminderTime.minute.toString().padLeft(2, '0')}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(flex: 3),
              _PrimaryButton(
                label: provider.remindersEnabled
                    ? S.onboardingNotificationsDone
                    : S.onboardingNotificationsSkip,
                onTap: onContinue,
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

// ── Page 4: Guide ───────────────────────────────────────────────────────────

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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
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
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
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
