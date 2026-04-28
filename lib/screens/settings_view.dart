import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../l10n/strings.dart';
import '../providers/app_provider.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late TextEditingController _nameController;
  final _exportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: context.read<AppProvider>().username);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showExportDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          S.settingsExportTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          S.settingsExportMessage,
          style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              S.settingsExportCancel,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _saveCsv(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(S.settingsExportSave),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCsv(BuildContext context) async {
    final csv = context.read<AppProvider>().buildCsv();
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/atensia-user-data-$timestamp.csv');
    await file.writeAsString(csv, flush: true);

    final box = _exportKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 1, 1);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      sharePositionOrigin: origin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.settingsTitle,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 36),

            // ── Username ────────────────────────────────────────────────────
            Text(
              S.settingsNameLabel.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              onChanged: (v) => provider.setUsername(v),
              textCapitalization: TextCapitalization.words,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: S.settingsNameHint,
                hintStyle:
                    const TextStyle(color: Colors.black38, fontSize: 15),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              ),
            ),

            const SizedBox(height: 32),

            // ── Reminders ───────────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.access_time, size: 18),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 48),

            // ── Guide ───────────────────────────────────────────────────────
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.onboardingGuideTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        S.onboardingGuideText,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            S.onboardingGuideBtn,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      S.onboardingGuideTitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),

            // ── Export ───────────────────────────────────────────────────────
            GestureDetector(
              key: _exportKey,
              onTap: () => _showExportDialog(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      S.settingsExportBtn,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Icon(Icons.download_outlined, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),

            // ── App info ────────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Text(
                    S.appTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    S.appTagline,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.settingsVersion,
                    style: const TextStyle(color: Colors.black38, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.settingsPrivacy,
                    style: const TextStyle(color: Colors.black38, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
