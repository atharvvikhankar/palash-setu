import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // User Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryAccentLight,
                    child: Icon(Icons.person_rounded, color: AppTheme.primaryAccent, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.teacherName.isNotEmpty ? settings.teacherName : 'Teacher Profile',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (settings.teacherMobile.isNotEmpty)
                        Text(
                          'Mobile: ${settings.teacherMobile}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.secondaryText),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'APPLICATION PREFERENCES',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondaryText, letterSpacing: 1.1),
            ),
            const SizedBox(height: 8),

            // UI Language Tile
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              leading: const Icon(Icons.language_rounded, color: AppTheme.primaryAccent),
              title: const Text('UI Language'),
              subtitle: Text('Current: ${settings.uiLanguage.toUpperCase()}'),
              trailing: DropdownButton<String>(
                value: settings.uiLanguage,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'hi', child: Text('Hindi (हिन्दी)')),
                  DropdownMenuItem(value: 'sat', child: Text('Santali ( Ol Chiki)')),
                ],
                onChanged: (val) {
                  if (val != null) settingsNotifier.setLanguage(val);
                },
              ),
            ),
            const Divider(),

            // Text Size Scaler Tile
            ListTile(
              leading: const Icon(Icons.format_size_rounded, color: AppTheme.primaryAccent),
              title: const Text('Text Size'),
              subtitle: Text('${settings.textSize.toInt()} sp'),
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: settings.textSize,
                  min: 14.0,
                  max: 20.0,
                  divisions: 3,
                  label: '${settings.textSize.toInt()} sp',
                  onChanged: (val) => settingsNotifier.setTextSize(val),
                ),
              ),
            ),
            const Divider(),

            // Tribal Vernacular Roadmap Tile
            ListTile(
              leading: const Icon(Icons.map_rounded, color: Color(0xFF6A1B9A)),
              title: const Text('Ho & Mundari Vernaculars'),
              subtitle: const Text('Section 23 Community Correction Roadmap'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Tribal Language Roadmap'),
                    content: const Text(
                      'This SIH 2026 prototype covers Santali (Ol Chiki) end-to-end.\n\nHo and Mundari support will be unlocked via the community correction & crowd-sourced dataset pipeline.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),

            const SizedBox(height: 24),
            const Text(
              'ABOUT PALASH SETU',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondaryText, letterSpacing: 1.1),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'PALASH Setu v1.0.0 (SIH 2026 Prototype)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Developed for Jharkhand MTB-MLE primary schools. Empowers teachers with real-time speech translation, phonetic guides, and NIPUN Bharat bilingual learning sheets.',
                    style: TextStyle(fontSize: 12, color: AppTheme.secondaryText, height: 1.4),
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
