import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/translation_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/confidence_badge.dart';
import '../translation/widgets/correction_dialog.dart';
import '../ocr/ocr_capture_screen.dart';

enum VoiceState { idle, listening, processingASR, translatingMT, generatingTTS, ready }

class VoiceTranslationScreen extends ConsumerStatefulWidget {
  const VoiceTranslationScreen({super.key});

  @override
  ConsumerState<VoiceTranslationScreen> createState() => _VoiceTranslationScreenState();
}

class _VoiceTranslationScreenState extends ConsumerState<VoiceTranslationScreen> with SingleTickerProviderStateMixin {
  VoiceState _state = VoiceState.idle;
  TranslationResult? _result;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Partial speech recognized so far (for live display while speaking)
  String _partialSpeech = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startVoiceCapture() async {
    if (_state != VoiceState.idle && _state != VoiceState.ready) return;

    final translationService = ref.read(translationServiceProvider);

    if (!translationService.speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone not available on this device')),
      );
      return;
    }

    // 1. Start listening
    setState(() {
      _state = VoiceState.listening;
      _partialSpeech = '';
      _result = null;
    });

    // 2. Voice input → translate (on-device, no backend)
    setState(() => _state = VoiceState.translatingMT);

    final result = await translationService.translateFromVoice(
      direction: 'hi-sat',
      onPartialResult: (partial) {
        setState(() {
          _partialSpeech = partial;
          _state = VoiceState.processingASR;
        });
      },
    );

    // 3. Speak result aloud via on-device TTS
    setState(() => _state = VoiceState.generatingTTS);
    if (result.success && result.translatedText.isNotEmpty) {
      await translationService.synthesizeTextToSpeech(
        result.translatedText,
        lang: 'sat_Olck',
      );
    } else if (result.audioRef != null) {
      await translationService.playAudio(result.audioRef!);
    }

    // 4. Done
    setState(() {
      _state = VoiceState.ready;
      _result = result;
    });
  }

  String _getStateMessage() {
    switch (_state) {
      case VoiceState.listening:
        return _partialSpeech.isNotEmpty
            ? '"$_partialSpeech"'
            : 'Listening... speak in Hindi 🎙️';
      case VoiceState.processingASR:
        return _partialSpeech.isNotEmpty
            ? 'Heard: "$_partialSpeech" — recognizing...🧠'
            : 'Recognizing speech (on-device)... 🧠';
      case VoiceState.translatingMT:
        return 'Translating to Santali (offline dictionary)... 🔄';
      case VoiceState.generatingTTS:
        return 'Speaking Santali phonetic guide... 🔊';
      case VoiceState.ready:
        return 'Done! Tap mic to speak again.';
      case VoiceState.idle:
        return 'Tap microphone and speak in Hindi';

    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = _state == VoiceState.listening ||
        _state == VoiceState.processingASR ||
        _state == VoiceState.translatingMT ||
        _state == VoiceState.generatingTTS;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Real-Time Voice Translate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded),
            tooltip: 'Textbook OCR Scanner',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OcrCaptureScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Direction Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Hindi (हिन्दी) ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryAccent, size: 20),
                    Text(' Santali (ᱥᱟᱱᱛᱟᱲᱤ)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              const SizedBox(height: 36),
              // Mic Button with Pulse Ring
              GestureDetector(
                onTap: isBusy ? null : _startVoiceCapture,
                child: ScaleTransition(
                  scale: isBusy ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: isBusy ? Colors.red : AppTheme.primaryAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isBusy ? Colors.red : AppTheme.primaryAccent).withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      isBusy ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              // State Message Chip
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _getStateMessage(),
                  key: ValueKey(_state),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isBusy ? AppTheme.primaryAccent : AppTheme.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 36),
              // Result Display Section
              if (_result != null) ...[
                // Captured Transcript
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CAPTURED SPEECH (HINDI ASR)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryText),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _result!.sourceText,
                        style: AppTheme.devanagariStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                // Santali Voice Translation Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccentLight.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryAccent, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'SANTALI VOICE TRANSLATION',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryAccent, letterSpacing: 1.1),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConfidenceBadge(confidence: _result!.confidence),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        _result!.translatedText,
                        style: AppTheme.olChikiStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      if (_result!.phoneticGuide.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Phonetic: ${_result!.phoneticGuide}',
                          style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppTheme.secondaryText),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              final svc = ref.read(translationServiceProvider);
                              if (_result!.audioRef != null) {
                                svc.playAudio(_result!.audioRef!);
                              } else {
                                // Replay via on-device TTS
                                svc.synthesizeTextToSpeech(
                                  _result!.translatedText,
                                  lang: 'sat_Olck',
                                );
                              }
                            },
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Replay Voice'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(140, 42),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                            icon: const Icon(Icons.edit_note_rounded, color: AppTheme.secondaryText),
                            label: const Text('Correct', style: TextStyle(color: AppTheme.secondaryText)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                // AI Source + Measured Latency Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Column(
                    children: [
                      // AI source chip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _result!.usedLiveAI
                                ? Icons.auto_awesome_rounded
                                : Icons.storage_rounded,
                            size: 14,
                            color: _result!.usedLiveAI
                                ? const Color(0xFF00C853)
                                : AppTheme.secondaryText,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _result!.modelUsed,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _result!.usedLiveAI
                                  ? const Color(0xFF00C853)
                                  : AppTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Latency readout
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.speed_rounded, size: 16, color: AppTheme.primaryAccent),
                          const SizedBox(width: 6),
                          Text(
                            'ASR: ${(_result!.latency['asr']! * 1000).toInt()}ms  │  '
                            'MT: ${(_result!.latency['mt']! * 1000).toInt()}ms  │  '
                            'Total: ${_result!.latency['total']!.toStringAsFixed(2)}s',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
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
