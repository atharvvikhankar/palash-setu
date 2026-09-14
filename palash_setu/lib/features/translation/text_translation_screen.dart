import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/translation_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/confidence_badge.dart';
import 'widgets/correction_dialog.dart';

class TextTranslationScreen extends ConsumerStatefulWidget {
  const TextTranslationScreen({super.key});

  @override
  ConsumerState<TextTranslationScreen> createState() => _TextTranslationScreenState();
}

class _TextTranslationScreenState extends ConsumerState<TextTranslationScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _direction = 'hi-sat'; // 'hi-sat' or 'sat-hi'
  bool _isTranslating = false;
  TranslationResult? _result;

  final List<String> _samplePhrases = [
    'बच्चों, आपका पाठशाला में स्वागत है!',
    'आओ एक, दो, तीन गिनती सीखें।',
    'पेड़ और पानी हमारे दोस्त हैं।',
    'किताब खोलो और पहला पृष्ठ पढ़ो।',
    'नमस्ते / जोहार',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _performTranslation([String? textToTranslate]) async {
    final text = textToTranslate ?? _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isTranslating = true;
      _result = null;
    });

    final translationService = ref.read(translationServiceProvider);
    final result = await translationService.translate(
      text: text,
      direction: _direction,
      isVoice: false,
    );

    setState(() {
      _isTranslating = false;
      _result = result;
    });
  }

  void _swapDirection() {
    setState(() {
      _direction = _direction == 'hi-sat' ? 'sat-hi' : 'hi-sat';
      _inputController.clear();
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Text Translate'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Direction Selector Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _direction == 'hi-sat' ? 'Hindi (हिन्दी)' : 'Santali (ᱥᱟᱱᱛᱟᱲᱤ)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryAccent, size: 28),
                      onPressed: _swapDirection,
                      tooltip: 'Swap Language Direction',
                    ),
                    Text(
                      _direction == 'hi-sat' ? 'Santali ( Ol Chiki)' : 'Hindi (हिन्दी)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Input Box
              TextField(
                controller: _inputController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _direction == 'hi-sat'
                      ? 'यहाँ हिन्दी वाक्य लिखें...'
                      : ' Ol Chiki text...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryAccent, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () => setState(() {
                      _inputController.clear();
                      _result = null;
                    }),
                  ),
                ),
                style: _direction == 'hi-sat'
                    ? AppTheme.devanagariStyle(fontSize: 16)
                    : AppTheme.olChikiStyle(fontSize: 16),
              ),

              const SizedBox(height: 12),
              // Sample Quick Chips
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _samplePhrases.length,
                  itemBuilder: (context, index) {
                    final phrase = _samplePhrases[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(phrase, style: const TextStyle(fontSize: 12)),
                        onPressed: () {
                          _inputController.text = phrase;
                          _performTranslation(phrase);
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isTranslating ? null : () => _performTranslation(),
                child: _isTranslating
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Translate'),
              ),

              const SizedBox(height: 24),
              // Translation Output Card
              if (_result != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccentLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryAccent.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TRANSLATION RESULT',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondaryText, letterSpacing: 1.1),
                          ),
                          ConfidenceBadge(confidence: _result!.confidence),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        _result!.translatedText,
                        style: AppTheme.olChikiStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      if (_result!.phoneticGuide.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.record_voice_over_outlined, size: 16, color: AppTheme.secondaryText),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Phonetic Guide: ${_result!.phoneticGuide}',
                                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppTheme.secondaryText),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      // Action Row: Listen Audio + Correction
                      Row(
                        children: [
                          if (_result!.audioRef != null) ...[
                            OutlinedButton.icon(
                              onPressed: () {
                                ref.read(translationServiceProvider).playAudio(_result!.audioRef!);
                              },
                              icon: const Icon(Icons.volume_up_rounded, size: 18),
                              label: const Text('Listen Voice'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(130, 40),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => CorrectionDialog(
                                  sourceText: _result!.sourceText,
                                  originalOutput: _result!.translatedText,
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_note_rounded, size: 18, color: AppTheme.secondaryText),
                            label: const Text('Correct', style: TextStyle(color: AppTheme.secondaryText)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Real Measured Latency Display
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Text(
                      '⚡ Measured Latency — MT: ${(_result!.latency['mt']! * 1000).toInt()}ms | Total: ${_result!.latency['total']!.toStringAsFixed(2)}s',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryText),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
