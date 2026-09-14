import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  String _selectedLang = 'en';

  final List<Map<String, dynamic>> _languages = [
    {
      'code': 'en',
      'title': 'English',
      'native': 'English',
      'enabled': true,
      'description': 'UI strings in English with Hindi-Santali translation',
    },
    {
      'code': 'hi',
      'title': 'Hindi (हिन्दी)',
      'native': 'हिन्दी',
      'enabled': true,
      'description': 'UI strings in Devanagari Hindi',
    },
    {
      'code': 'sat',
      'title': 'Santali (ᱥᱟᱱᱛᱟᱲᱤ)',
      'native': ' Ol Chiki',
      'enabled': true,
      'description': 'Primary tribal vernacular of Jharkhand',
    },
    {
      'code': 'ho',
      'title': 'Ho (ᱦᱚ)',
      'native': 'Ho Vernacular',
      'enabled': false,
      'description': 'Community expansion pipeline (Section 23 Roadmap)',
    },
    {
      'code': 'mun',
      'title': 'Mundari (ᱢᱩᱱᱰᱟᱨᱤ)',
      'native': 'Mundari Vernacular',
      'enabled': false,
      'description': 'Community expansion pipeline (Section 23 Roadmap)',
    },
  ];

  void _onComplete() {
    ref.read(appSettingsProvider.notifier).setLanguage(_selectedLang);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Select App Language'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Preferred UI Language',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Translation will target Hindi ⇆ Santali (Ol Chiki) for MTB-MLE schools.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _languages.length,
                  itemBuilder: (context, index) {
                    final lang = _languages[index];
                    final bool isSelected = _selectedLang == lang['code'];
                    final bool isEnabled = lang['enabled'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? (isSelected ? AppTheme.primaryAccentLight : AppTheme.surface)
                            : AppTheme.disabledBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryAccent : AppTheme.surfaceBorder,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        enabled: isEnabled,
                        onTap: isEnabled
                            ? () => setState(() => _selectedLang = lang['code'])
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ho and Mundari support will be unlocked via community correction pipeline (Section 23).'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                        leading: Radio<String>(
                          value: lang['code'],
                          groupValue: isEnabled ? _selectedLang : null,
                          onChanged: isEnabled
                              ? (val) => setState(() => _selectedLang = val!)
                              : null,
                          activeColor: AppTheme.primaryAccent,
                        ),
                        title: Row(
                          children: [
                            Text(
                              lang['title'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isEnabled ? AppTheme.primaryText : AppTheme.disabledColor,
                              ),
                            ),
                            if (!isEnabled) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Coming Soon',
                                  style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ]
                          ],
                        ),
                        subtitle: Text(
                          lang['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: isEnabled ? AppTheme.secondaryText : AppTheme.disabledColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _onComplete,
                child: const Text('Start Palash Setu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
