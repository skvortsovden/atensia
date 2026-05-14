import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: context.read<AppProvider>().username);
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    }).catchError((Object e) {
      debugPrint('SettingsView: PackageInfo.fromPlatform() failed ($e).');
      if (mounted) setState(() => _appVersion = '—');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showEncodingErrorDialog(BuildContext context) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            S.settingsImportErrorTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: Text(
            S.settingsImportErrorEncoding,
            style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(S.settingsImportErrorBtn),
            ),
          ],
        ),
      );

  Future<void> _showImportDialog(BuildContext context) async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          S.settingsImportTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          S.settingsImportMessage,
          style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop('choose'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(S.settingsImportChoose),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop('template'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(S.settingsImportTemplate),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: Text(
                  S.settingsImportCancel,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (action == null) return;
    if (!context.mounted) return;

    if (action == 'template') {
      await _downloadTemplate(context);
      return;
    }

    // Pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    if (!context.mounted) return;

    final bytes = result.files.first.bytes;
    final path  = result.files.first.path;
    final String csvContent;
    if (bytes != null) {
      try {
        csvContent = utf8.decode(bytes);
      } on FormatException {
        if (!context.mounted) return;
        await _showEncodingErrorDialog(context);
        return;
      }
    } else if (path != null) {
      try {
        csvContent = await File(path).readAsString();
      } on FormatException {
        if (!context.mounted) return;
        await _showEncodingErrorDialog(context);
        return;
      }
    } else {
      if (!context.mounted) return;
      await _showEncodingErrorDialog(context);
      return;
    }
    if (!context.mounted) return;

    final error = context.read<AppProvider>().importCsv(csvContent);
    if (!context.mounted) return;

    if (error != null) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            S.settingsImportErrorTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          content: Text(
            error,
            style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
          ),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(S.settingsImportErrorBtn),
                ),
              ],
            ),
          ],
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          S.settingsImportDoneTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          S.settingsImportDoneMessage,
          style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(S.settingsImportDoneBtn),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _downloadTemplate(BuildContext context) async {
    final csv = context.read<AppProvider>().buildTemplateCsv();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/atensia-import-template.csv');
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

  Future<void> _showClearDataDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          S.settingsClearTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          S.settingsClearMessage,
          style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop('export_erase'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(S.settingsClearExport),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop('erase'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(S.settingsClearErase),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: Text(
                  S.settingsClearCancel,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (result == null) return;
    if (!context.mounted) return;

    if (result == 'export_erase') {
      try {
        await _saveCsv(context);
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.settingsClearExportError),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return; // abort — do not delete data
      }
      if (!context.mounted) return;
    }

    await context.read<AppProvider>().clearAllData();
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          S.settingsClearDoneTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          S.settingsClearDoneMessage,
          style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(S.settingsClearDoneBtn),
          ),
        ],
      ),
    );
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try {
                    await _saveCsv(context);
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(S.settingsClearExportError),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
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
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  S.settingsExportCancel,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ],
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

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        // Dynamic bottom padding: base 80pt + home-indicator / gesture-bar
        // height so the footer is never clipped behind the bottom nav.
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 80),
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
              maxLength: 30,
              style: Theme.of(context).textTheme.bodyLarge,
              // Only show counter as user approaches the limit; hide on empty.
              buildCounter: (
                context, {
                required int currentLength,
                required bool isFocused,
                int? maxLength,
              }) {
                final limit = maxLength ?? 30;
                if (currentLength == 0) return null;
                if (currentLength < limit - 5) return null;
                return Text(
                  '$currentLength/$limit',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 11,
                  ),
                );
              },
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

            // ── Language ────────────────────────────────────────────────────
            Text(
              S.settingsLanguageLabel.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final opt in [('uk', 'Укр'), ('en', 'Eng')])
                  Expanded(
                    child: GestureDetector(
                      onTap: () => provider.setLocale(opt.$1),
                      child: Container(
                        margin: opt.$1 == 'uk'
                            ? const EdgeInsets.only(right: 8)
                            : EdgeInsets.zero,
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                            fontSize: 14,
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

            const SizedBox(height: 32),

            // ── Reminders ───────────────────────────────────────────────────
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  provider.setReminders(!provider.remindersEnabled),
              child: Container(
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
                      activeTrackColor: Colors.black54,
                      inactiveThumbColor: Colors.black54,
                      inactiveTrackColor: Colors.black26,
                    ),
                  ],
                ),
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

            const SizedBox(height: 40),

            // ── Backup (Export + Import) ────────────────────────────────────
            _SectionLabel(S.settingsSectionBackup),
            const SizedBox(height: 8),
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

            const SizedBox(height: 8),

            GestureDetector(
              onTap: () => _showImportDialog(context),
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
                      S.settingsImportBtn,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Icon(Icons.upload_outlined, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Clear data (quietly separated) ───────────────────────────────
            GestureDetector(
              onTap: () => _showClearDataDialog(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      S.settingsClearBtn,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                    ),
                    const Spacer(),
                    const Icon(Icons.delete_outline,
                        size: 18, color: Colors.black87),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
            const Divider(color: Color(0xFFEEEEEE), thickness: 1, height: 1),
            const SizedBox(height: 32),

            // ── App info (footer) ───────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Text(
                    S.appTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold, height: 1.0),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    S.appTagline,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  // Help link — grouped with footer metadata, centered.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            S.onboardingGuideTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.black38,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right,
                              size: 14, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${S.settingsVersion} $_appVersion',
                    style: const TextStyle(color: Colors.black38, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.settingsPrivacy,
                    style: const TextStyle(color: Colors.black38, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2026 Denys Skvortsov',
                    style: const TextStyle(color: Colors.black38, fontSize: 12),
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

// ── Section label (small-caps gray) — shared with name/language labels ──────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: Colors.black54,
      ),
    );
  }
}
