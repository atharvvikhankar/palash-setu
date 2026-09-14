import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../translation/text_translation_screen.dart';
import '../voice_translation/voice_translation_screen.dart';
import '../worksheets/worksheet_flashcard_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final connectivityAsync = ref.watch(connectivityProvider);

    final isOffline = connectivityAsync.when(
      data: (result) => result == ConnectivityResult.none,
      loading: () => true,
      error: (_, __) => true,
    );

    final teacherName = settings.teacherName.isNotEmpty ? settings.teacherName : 'Teacher';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(Icons.translate_rounded, color: AppTheme.primaryAccent),
            ),
            const SizedBox(width: 10),
            const Text('PALASH SETU'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 36.0 : 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Banner with Teacher Greeting & Status
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ' ᱡᱚᱦᱟᱨ, $teacherName!',
                              style: AppTheme.olChikiStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryAccent,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isOffline ? Colors.orange.shade50 : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isOffline ? Colors.orange : Colors.green,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                                    size: 14,
                                    color: isOffline ? Colors.orange.shade800 : Colors.green.shade800,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOffline ? 'Offline Ready' : 'Connected',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isOffline ? Colors.orange.shade800 : Colors.green.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.swap_horiz_rounded, size: 18, color: AppTheme.secondaryText),
                            const SizedBox(width: 6),
                            const Text(
                              'Translation Pair: ',
                              style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
                            ),
                            const Text(
                              'Hindi ⇆ Santali (Ol Chiki)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryText),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Primary Classroom Tools',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Responsive Grid / Cards
                  if (isTablet)
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeatureCard(
                            context: context,
                            title: 'Voice Translate',
                            subtitle: 'Speech-to-Speech Hindi ⇆ Santali for live classroom lessons.',
                            icon: Icons.mic_rounded,
                            color: const Color(0xFF1B6FB0),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const VoiceTranslationScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFeatureCard(
                            context: context,
                            title: 'Text Translate',
                            subtitle: 'Instant Devanagari ⇆ Ol Chiki script text & phonetic guide.',
                            icon: Icons.translate_rounded,
                            color: const Color(0xFF2E7D32),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const TextTranslationScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFeatureCard(
                            context: context,
                            title: 'Worksheets & Flashcards',
                            subtitle: 'Generate printable NIPUN Bharat bilingual learning sheets.',
                            icon: Icons.assignment_rounded,
                            color: const Color(0xFF6A1B9A),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const WorksheetFlashcardScreen()),
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildFeatureCard(
                          context: context,
                          title: 'Voice Translate',
                          subtitle: 'Real-time Speech-to-Speech translation for live classroom teaching.',
                          icon: Icons.mic_rounded,
                          color: const Color(0xFF1B6FB0),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const VoiceTranslationScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureCard(
                          context: context,
                          title: 'Text Translate',
                          subtitle: 'Instant Devanagari ⇆ Ol Chiki translation with phonetic guide.',
                          icon: Icons.translate_rounded,
                          color: const Color(0xFF2E7D32),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const TextTranslationScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureCard(
                          context: context,
                          title: 'Worksheets & Flashcards',
                          subtitle: 'NIPUN Bharat bilingual activity sheets & audio flashcards.',
                          icon: Icons.assignment_rounded,
                          color: const Color(0xFF6A1B9A),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const WorksheetFlashcardScreen()),
                            );
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),
                  // NIPUN Bharat MTB-MLE Info Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.school_rounded, color: Color(0xFFF57F17), size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'NIPUN Bharat MTB-MLE Aligned',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF5D4037)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Empowering primary teachers in Jharkhand to bridge Hindi and tribal mother tongues.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF5D4037)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.secondaryText,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.secondaryText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
