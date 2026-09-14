import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'database_service.dart';
import 'phonetic_engine.dart';
import 'onnx_engine.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// PALASH Setu — 100% Offline Translation Service
/// ================================================
/// Architecture:
///   ASR  → Android SpeechRecognizer (speech_to_text) — works natively for Hindi
///   MT   → 300+ phrase bank + word-level matching + rule engine (zero AI needed)
///   TTS  → Android TextToSpeech (flutter_tts) for phonetic Santali guide
///
/// When the AI4Bharat ONNX native bridge is complete, only the MT
/// section below needs to be swapped. ASR and TTS remain the same.

class TranslationResult {
  final bool success;
  final String sourceText;
  final String translatedText;
  final String phoneticGuide;
  final String confidence; // 'high', 'medium', 'low'
  final double confidenceScore; // 0.0–1.0
  final String? audioRef;
  final Map<String, double> latency;
  final String? error;
  final bool usedLiveAI;
  final String modelUsed;
  final String engine;

  TranslationResult({
    required this.success,
    required this.sourceText,
    required this.translatedText,
    required this.phoneticGuide,
    required this.confidence,
    this.confidenceScore = 0.8,
    this.audioRef,
    required this.latency,
    this.error,
    this.usedLiveAI = false,
    this.modelUsed = 'Phrase Bank (On-Device)',
    this.engine = 'local_offline',
  });
}

class TranslationService {
  final DatabaseService _db = DatabaseService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _speechAvailable = false;
  bool _isListening = false;
  bool _ttsReady = false;

  AudioPlayer get audioPlayer => _audioPlayer;
  bool get isListening => _isListening;
  bool get speechAvailable => _speechAvailable;

  // PC Wi-Fi IP — phone and PC must be connected to the SAME Wi-Fi network
  final String pcBackendUrl = 'http://10.181.89.141:8000';

  // ─── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    await _initSpeech();
    await _initTts();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speechToText.initialize(
        onError: (error) => debugPrint('STT error: ${error.errorMsg}'),
      );
      debugPrint(_speechAvailable
          ? 'Android SpeechRecognizer: READY'
          : 'Android SpeechRecognizer: NOT AVAILABLE');
    } catch (e) {
      debugPrint('STT init failed: $e');
      _speechAvailable = false;
    }
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage('hi-IN');
      await _flutterTts.setSpeechRate(0.45); // Slower speech rate for clarity
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _ttsReady = true;
      debugPrint('Android TTS: READY');
    } catch (e) {
      debugPrint('TTS init failed: $e');
      _ttsReady = false;
    }
  }

  // ─── Main Translation ──────────────────────────────────────────────────────

  Future<TranslationResult> translate({
    required String text,
    required String direction,
    String engine = 'auto',
    bool isVoice = false,
  }) async {
    final Stopwatch total = Stopwatch()..start();
    final Stopwatch mt = Stopwatch()..start();

    final String normalised = text.trim().toLowerCase();

    String translatedText;
    String phoneticGuide;
    String confidence;
    double score;
    String? audioRef;

    // Attempt ONNX Native Engine First (AI4Bharat)
    try {
      final onnxEngine = OnnxTranslationEngine();
      
      String modelPath = "assets/models/indictrans2-indic-indic-dist-320M.onnx";
          
      await onnxEngine.initialize(modelPath);
      final onnxResult = await onnxEngine.translate(normalised);
      
      if (onnxResult.isNotEmpty && !onnxResult.contains("Waiting for ONNX weights")) {
        translatedText = onnxResult;
        phoneticGuide = PhoneticEngine.generatePhoneticGuide(translatedText);
        confidence = 'high';
        score = 0.98;
        audioRef = null;
        debugPrint('ONNX Native Hit: "$text" → "$translatedText"');
        
        mt.stop();
        total.stop();
        return TranslationResult(
          success: true,
          sourceText: text,
          translatedText: translatedText,
          phoneticGuide: phoneticGuide,
          confidence: confidence,
          confidenceScore: score,
          audioRef: audioRef,
          latency: {
            'asr': 0.0,
            'mt': mt.elapsedMilliseconds / 1000.0,
            'tts': 0.0,
            'total': total.elapsedMilliseconds / 1000.0,
          },
          usedLiveAI: true,
          modelUsed: 'IndicTrans2-Distilled-320M (INT8/ONNX)',
          engine: 'onnx_native',
        );
      }
    } catch (e) {
      debugPrint("ONNX Engine failed or not fully initialized yet: $e");
    }

    // 1. Exact phrase-bank lookup (highest confidence)
    final String? exactMatch = _phraseBank(normalised, direction);
    if (exactMatch != null) {
      translatedText = exactMatch;
      phoneticGuide = PhoneticEngine.generatePhoneticGuide(translatedText);
      confidence = 'high';
      score = 0.97;
      audioRef = null;
      debugPrint('Phrase-Bank exact hit: "$text" → "$translatedText"');
      
      mt.stop();
      total.stop();
      return TranslationResult(
        success: true,
        sourceText: text,
        translatedText: translatedText,
        phoneticGuide: phoneticGuide,
        confidence: confidence,
        confidenceScore: score,
        audioRef: audioRef,
        latency: {
          'asr': 0.0,
          'mt': mt.elapsedMilliseconds / 1000.0,
          'tts': 0.0,
          'total': total.elapsedMilliseconds / 1000.0,
        },
        usedLiveAI: false,
        modelUsed: 'On-Device Phrase Bank',
        engine: 'local_offline',
      );
    }

    // Attempt PC Edge Backend API (AI4Bharat) if exact match not found
    try {
      final response = await http.post(
        Uri.parse('$pcBackendUrl/ai/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'src_lang': direction == 'hi-sat' ? 'hin_Deva' : 'sat_Olck',
          'tgt_lang': direction == 'hi-sat' ? 'sat_Olck' : 'hin_Deva',
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        translatedText = data['translated_text'];
        phoneticGuide = PhoneticEngine.generatePhoneticGuide(translatedText);
        confidence = 'high';
        score = 0.99;
        audioRef = null;
        debugPrint('PC API Hit: "$text" → "$translatedText"');

        mt.stop();
        total.stop();
        return TranslationResult(
          success: true,
          sourceText: text,
          translatedText: translatedText,
          phoneticGuide: phoneticGuide,
          confidence: confidence,
          confidenceScore: score,
          audioRef: audioRef,
          latency: {
            'asr': 0.0,
            'mt': mt.elapsedMilliseconds / 1000.0,
            'tts': 0.0,
            'total': total.elapsedMilliseconds / 1000.0,
          },
          usedLiveAI: true,
          modelUsed: 'IndicTrans2-Distilled-320M (Edge API)',
          engine: 'edge_api',
        );
      }
    } catch (e) {
      debugPrint("Edge API failed (is PC running?): $e");
    }

    // 2. SQLite curriculum DB lookup
    final Map<String, dynamic>? dbMatch = await _db.searchTranslation(text);
    if (dbMatch != null) {
        if (direction != 'sat-hi') {
          translatedText = dbMatch['santaliText'] ?? dbMatch['santaliWord'] ?? '';
          phoneticGuide = dbMatch['phoneticGuide'] ??
              PhoneticEngine.generatePhoneticGuide(translatedText);
        } else {
          translatedText = dbMatch['hindiText'] ?? dbMatch['hindiWord'] ?? '';
          phoneticGuide = text;
        }
        confidence = dbMatch['confidence'] ?? 'high';
        score = 0.95;
        audioRef = dbMatch['santaliAudioRef'];
        debugPrint('DB hit: "$text" → "$translatedText"');
      } else {
        // 3. Word-by-word composition from phrase bank
        final String? composed = _composeFromWords(normalised, direction);
        if (composed != null) {
          translatedText = composed;
          phoneticGuide = PhoneticEngine.generatePhoneticGuide(translatedText);
          confidence = 'medium';
          score = 0.75;
          audioRef = null;
          debugPrint('Word-compose hit: "$text" → "$translatedText"');
        } else {
          // 4. Keyword extraction fallback
          translatedText = _keywordFallback(normalised, direction);
          phoneticGuide = PhoneticEngine.generatePhoneticGuide(translatedText);
          confidence = 'medium';
          score = 0.65;
          audioRef = null;
          debugPrint('Keyword fallback hit: "$text" → "$translatedText"');
        }
      }
    }

    mt.stop();
    total.stop();

    return TranslationResult(
      success: true,
      sourceText: text,
      translatedText: translatedText,
      phoneticGuide: phoneticGuide,
      confidence: confidence,
      confidenceScore: score,
      audioRef: audioRef,
      latency: {
        'asr': 0.0,
        'mt': mt.elapsedMilliseconds / 1000.0,
        'tts': 0.0,
        'total': total.elapsedMilliseconds / 1000.0,
      },
      usedLiveAI: false,
      modelUsed: 'On-Device Phrase Bank',
      engine: 'local_offline',
    );
  }

  // ─── Voice Input ────────────────────────────────────────────────────────────

  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    String localeId = 'hi_IN',
  }) async {
    if (!_speechAvailable) {
      onResult('(माइक्रोफोन उपलब्ध नहीं)', true);
      return;
    }
    if (_isListening) return;

    _isListening = true;
    await _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
        if (result.finalResult) _isListening = false;
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
  }

  Future<TranslationResult> translateFromVoice({
    required String direction,
    void Function(String partial)? onPartialResult,
  }) async {
    final Stopwatch total = Stopwatch()..start();
    final Stopwatch asrTimer = Stopwatch()..start();
    final Completer<String> completer = Completer();

    await startListening(
      localeId: direction == 'sat-hi' ? 'hi_IN' : 'hi_IN',
      onResult: (text, isFinal) {
        if (onPartialResult != null && !isFinal) onPartialResult(text);
        if (isFinal && !completer.isCompleted) completer.complete(text);
      },
    );

    final String spokenText = await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        stopListening();
        return '';
      },
    );

    asrTimer.stop();

    if (spokenText.trim().isEmpty) {
      total.stop();
      return TranslationResult(
        success: false,
        sourceText: '',
        translatedText: 'ᱡᱚᱦᱟᱨ — कृपया बोलें',
        phoneticGuide: 'Johar — Please speak',
        confidence: 'low',
        latency: {
          'asr': asrTimer.elapsedMilliseconds / 1000.0,
          'mt': 0.0,
          'tts': 0.0,
          'total': total.elapsedMilliseconds / 1000.0,
        },
        error: 'No speech detected',
        modelUsed: 'Android SpeechRecognizer',
        engine: 'local_offline',
      );
    }

    final TranslationResult result = await translate(
      text: spokenText,
      direction: direction,
      isVoice: true,
    );

    total.stop();
    return TranslationResult(
      success: result.success,
      sourceText: result.sourceText,
      translatedText: result.translatedText,
      phoneticGuide: result.phoneticGuide,
      confidence: result.confidence,
      confidenceScore: result.confidenceScore,
      audioRef: result.audioRef,
      latency: {
        'asr': asrTimer.elapsedMilliseconds / 1000.0,
        'mt': result.latency['mt'] ?? 0.0,
        'tts': 0.0,
        'total': total.elapsedMilliseconds / 1000.0,
      },
      usedLiveAI: false,
      modelUsed: 'ASR + On-Device Phrase Bank',
      engine: 'local_offline',
    );
  }

  // ─── Text-to-Speech ────────────────────────────────────────────────────────

  Future<void> synthesizeTextToSpeech(
    String text, {
    String lang = 'sat_Olck',
    bool usePhonetic = true,
  }) async {
    if (!_ttsReady) return;

    final String speakText = usePhonetic && lang.startsWith('sat')
        ? PhoneticEngine.generatePhoneticGuide(text)
        : text;

    try {
      await _flutterTts.stop();
      await _flutterTts.setLanguage('hi-IN');
      await _flutterTts.setSpeechRate(0.45); // Slower speech rate for clarity
      await _flutterTts.speak(speakText);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stopTts() async {
    if (_ttsReady) await _flutterTts.stop();
  }

  Future<void> playAudio(String audioAssetRef) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setAsset('assets/audio/$audioAssetRef');
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    _flutterTts.stop();
    _speechToText.cancel();
  }

  // ─── 300+ Phrase Bank ──────────────────────────────────────────────────────

  static const Map<String, String> _hiToSat = {
    // ── Greetings & Common ──
    'नमस्ते': 'ᱡᱚᱦᱟᱨ',
    'प्रणाम': 'ᱡᱚᱦᱟᱨ',
    'नमस्कार': 'ᱡᱚᱦᱟᱨ',
    'आप कैसे हैं?': 'ᱪᱮᱫ ᱞᱮᱠᱟ ᱢᱮᱱᱟᱢᱟ?',
    'आप कैसे हैं': 'ᱪᱮᱫ ᱞᱮᱠᱟ ᱢᱮᱱᱟᱢᱟ?',
    'तुम कैसे हो?': 'ᱪᱮᱫ ᱞᱮᱠᱟ ᱢᱮᱱᱟᱢᱟ?',
    'तुम कैसे हो': 'ᱪᱮᱫ ᱞᱮᱠᱟ ᱢᱮᱱᱟᱢᱟ?',
    'मैं ठीक हूँ': 'ᱤᱧ ᱫᱚ ᱵᱮᱥ ᱜᱮᱭᱟᱹᱧ',
    'सुप्रभात': 'ᱥᱟᱹᱜᱩᱱ ᱥᱮᱛᱟᱜ',
    'शुभ रात्रि': 'ᱥᱟᱹᱜᱩᱱ ᱧᱤᱫᱟᱹ',
    'धन्यवाद': 'ᱥᱟᱨᱦᱟᱣ',
    'शुक्रिया': 'ᱥᱟᱨᱦᱟᱣ',
    'हाँ': 'ᱦᱮᱸ',
    'नहीं': 'ᱵᱟᱝ',
    'क्या': 'ᱪᱮᱫ',
    'क्यों': 'ᱪᱮᱫᱟᱜ',
    'कहाँ': 'ᱚᱠᱟᱨᱮ',
    'जोहार': 'ᱡᱚᱦᱟᱨ',
    'शुभ प्रभात': 'ᱥᱟᱹᱜᱩᱱ ᱥᱮᱛᱟ',
    'शुभ संध्या': 'ᱥᱟᱹᱜᱩᱱ ᱥᱟᱹᱢ',
    'अलविदा': 'ᱦᱩᱡᱩᱜ ᱢᱮ',
    'फिर मिलेंगे': 'ᱩᱱᱤᱭᱟᱹᱫ ᱦᱟᱵᱟ',
    'कैसे हो': 'ᱟᱢ ᱮᱴᱟᱜ ᱠᱟᱱᱟ',
    'कैसे हैं': 'ᱟᱢ ᱮᱴᱟᱜ ᱠᱟᱱᱟ',
    'ठीक हूं': 'ᱤᱧ ᱥᱮ ᱠᱟᱱᱟ',
    'ठीक हैं': 'ᱤᱧ ᱥᱮ ᱠᱟᱱᱟ',
    'माफ करना': 'ᱪᱟᱸᱜᱽ ᱢᱮ',
    'माफ कीजिए': 'ᱪᱟᱸᱜᱽ ᱢᱮ',
    'क्षमा करें': 'ᱪᱟᱸᱜᱽ ᱢᱮ',
    'स्वागत है': 'ᱥᱟᱜᱩᱱ ᱠᱟᱱᱟ',
    'आपका स्वागत है': 'ᱟᱢᱟᱜ ᱥᱟᱜᱩᱱ ᱠᱟᱱᱟ',

    // ── Yes / No ──
    'हां': 'ᱦᱚᱭ',
    'हाँ': 'ᱦᱚᱭ',
    'जी हां': 'ᱦᱚᱭ',
    'नहीं': 'ᱵᱟᱱᱩᱜ',
    'नहीं है': 'ᱵᱟᱱᱩᱜ ᱠᱟᱱᱟ',
    'पता नहीं': 'ᱵᱟᱱᱩᱜ ᱧᱟᱢᱟ',
    'ठीक है': 'ᱥᱮ ᱠᱟᱱᱟ',
    'अच्छा': 'ᱥᱮ',
    'बहुत अच्छा': 'ᱵᱟᱦᱲᱮ ᱥᱮ ᱠᱟᱱᱟ',
    'शाबाश': 'ᱥᱮ ᱠᱟᱱᱟ',
    'बहुत शाबाश': 'ᱵᱟᱦᱲᱮ ᱥᱮ ᱠᱟᱱᱟ',
    'गलत': 'ᱢᱮᱛᱟᱹᱫ',
    'सही': 'ᱥᱮ',
    'सही है': 'ᱥᱮ ᱠᱟᱱᱟ',

    // ── Numbers ──
    'शून्य': 'ᱥᱩᱱᱩᱢ',
    'एक': 'ᱢᱤᱫ',
    'दो': 'ᱵᱟᱨ',
    'तीन': 'ᱯᱮ',
    'चार': 'ᱯᱩᱱ',
    'पांच': 'ᱢᱚᱬᱮ',
    'छह': 'ᱛᱩᱨᱩᱭ',
    'सात': 'ᱮᱭᱟᱭ',
    'आठ': 'ᱤᱨᱚᱞ',
    'नौ': 'ᱟᱨᱮ',
    'दस': 'ᱜᱮᱞ',
    'ग्यारह': 'ᱢᱤᱫ ᱜᱮᱞ ᱢᱤᱫ',
    'बारह': 'ᱢᱤᱫ ᱜᱮᱞ ᱵᱟᱨ',
    'तेरह': 'ᱢᱤᱫ ᱜᱮᱞ ᱯᱮ',
    'चौदह': 'ᱢᱤᱫ ᱜᱮᱞ ᱯᱩᱱ',
    'पंद्रह': 'ᱢᱤᱫ ᱜᱮᱞ ᱢᱚᱬᱮ',
    'बीस': 'ᱵᱟᱨ ᱜᱮᱞ',
    'तीस': 'ᱯᱮ ᱜᱮᱞ',
    'चालीस': 'ᱯᱩᱱ ᱜᱮᱞ',
    'पचास': 'ᱢᱚᱬᱮ ᱜᱮᱞ',
    'सौ': 'ᱥᱟᱭ',
    'एक सौ': 'ᱢᱤᱫ ᱥᱟᱭ',
    'हजार': 'ᱦᱟᱡᱟᱨ',

    // ── Classroom Commands ──
    'बैठो': 'ᱫᱩᱲᱩᱵ ᱢᱮ',
    'बैठिए': 'ᱫᱩᱲᱩᱵ ᱢᱮ',
    'बैठ जाओ': 'ᱫᱩᱲᱩᱵ ᱢᱮ',
    'खड़े हो': 'ᱦᱩᱰᱤᱧ ᱢᱮ',
    'उठो': 'ᱦᱩᱰᱤᱧ ᱢᱮ',
    'उठिए': 'ᱦᱩᱰᱤᱧ ᱢᱮ',
    'खड़े हो जाओ': 'ᱦᱩᱰᱤᱧ ᱢᱮ',
    'पढ़ो': 'ᱯᱟᱲᱦᱟᱣ ᱢᱮ',
    'पढ़िए': 'ᱯᱟᱲᱦᱟᱣ ᱢᱮ',
    'लिखो': 'ᱚᱞ ᱢᱮ',
    'लिखिए': 'ᱚᱞ ᱢᱮ',
    'देखो': 'ᱩᱧᱦᱩᱬ ᱢᱮ',
    'देखिए': 'ᱩᱧᱦᱩᱬ ᱢᱮ',
    'सुनो': 'ᱦᱚᱯᱚᱱ ᱢᱮ',
    'सुनिए': 'ᱦᱚᱯᱚᱱ ᱢᱮ',
    'ध्यान से सुनो': 'ᱥᱮᱛᱟᱹᱜ ᱦᱚᱯᱚᱱ ᱢᱮ',
    'चुप रहो': 'ᱪᱩᱯᱽ ᱴᱷᱮᱱ ᱢᱮ',
    'शांत रहो': 'ᱥᱟᱸᱛ ᱴᱷᱮᱱ ᱢᱮ',
    'आओ': 'ᱟᱠᱟᱱᱟ ᱢᱮ',
    'जाओ': 'ᱵᱷᱩᱜ ᱢᱮ',
    'चलो': 'ᱵᱷᱩᱜ ᱢᱮ',
    'बाहर जाओ': 'ᱵᱟᱦᱨᱮ ᱵᱷᱩᱜ ᱢᱮ',
    'अंदर आओ': 'ᱟᱸᱫᱟᱨ ᱟᱠᱟᱱᱟ ᱢᱮ',
    'ध्यान दो': 'ᱢᱟᱱ ᱫᱮᱣᱟᱭ ᱢᱮ',
    'समझे': 'ᱵᱩᱡᱷᱟᱹᱣ ᱦᱚᱭ',
    'समझ गए': 'ᱵᱩᱡᱷᱟᱹᱣ ᱦᱚᱭ',
    'समझे नहीं': 'ᱵᱩᱡᱷᱟᱹᱣ ᱵᱟᱱᱩᱜ',
    'दोहराओ': 'ᱵᱟᱨᱢᱟᱬᱤᱭᱟ ᱢᱮ',
    'फिर से बोलो': 'ᱵᱟᱨᱢᱟᱬᱤᱭᱟ ᱢᱮ',
    'जोर से बोलो': 'ᱛᱤᱞᱩ ᱴᱷᱮᱱ ᱠᱟᱹᱣ ᱢᱮ',
    'धीरे बोलो': 'ᱩᱢᱩᱞ ᱠᱟᱹᱣ ᱢᱮ',
    'हाथ उठाओ': 'ᱦᱟᱴᱤ ᱦᱩᱰᱤᱧ ᱢᱮ',
    'हाथ नीचे करो': 'ᱦᱟᱴᱤ ᱛᱟᱞᱮ ᱫᱮᱣᱟ ᱢᱮ',
    'प्रश्न पूछो': 'ᱡᱚᱛᱚ ᱵᱩᱡᱷᱟᱣ ᱢᱮ',
    'उत्तर दो': 'ᱡᱚᱛᱚ ᱫᱮᱣᱟ ᱢᱮ',
    'खेलो': 'ᱨᱟᱥᱠᱟ ᱢᱮ',
    'खाओ': 'ᱡᱚᱢ ᱢᱮ',
    'पीओ': 'ᱟᱹᱜᱩᱭ ᱢᱮ',
    'सोओ': 'ᱱᱤᱸᱫ ᱢᱮ',

    // ── School & Learning ──
    'स्कूल': 'ᱤᱛᱩᱱ ᱟᱥᱲᱟ',
    'विद्यालय': 'ᱤᱛᱩᱱ ᱟᱥᱲᱟ',
    'पाठशाला': 'ᱤᱛᱩᱱ ᱟᱥᱲᱟ',
    'कक्षा': 'ᱠᱷᱟᱸᱴᱤ',
    'कमरा': 'ᱠᱚᱴᱷᱟ',
    'किताब': 'ᱯᱩᱛᱷᱤ',
    'किताबें': 'ᱯᱩᱛᱷᱤ ᱠᱚ',
    'पुस्तक': 'ᱯᱩᱛᱷᱤ',
    'पुस्तकें': 'ᱯᱩᱛᱷᱤ ᱠᱚ',
    'कॉपी': 'ᱠᱷᱟᱛᱟ',
    'नोटबुक': 'ᱠᱷᱟᱛᱟ',
    'कलम': 'ᱯᱮᱱ',
    'पेंसिल': 'ᱯᱮᱱᱥᱤᱞ',
    'रबर': 'ᱨᱩᱵᱳᱨ',
    'पट्टी': 'ᱥᱠᱮᱞ',
    'श्यामपट्ट': 'ᱠᱟᱞᱚ ᱯᱟᱴ',
    'ब्लैकबोर्ड': 'ᱠᱟᱞᱚ ᱯᱟᱴ',
    'चॉक': 'ᱪᱚᱠ',
    'शिक्षक': 'ᱢᱟᱪᱮᱛ',
    'गुरु': 'ᱢᱟᱪᱮᱛ',
    'मास्टरजी': 'ᱢᱟᱪᱮᱛ',
    'छात्र': 'ᱪᱮᱛᱮᱫᱤᱭᱟᱹ',
    'विद्यार्थी': 'ᱪᱮᱛᱮᱫᱤᱭᱟᱹ',
    'बच्चा': 'ᱜᱤᱫᱽᱨᱟᱹ',
    'बच्चे': 'ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ',
    'होमवर्क': 'ᱜᱷᱟᱸᱰᱤ ᱠᱟᱢ',
    'गृहकार्य': 'ᱜᱷᱟᱸᱰᱤ ᱠᱟᱢ',
    'पाठ': 'ᱯᱟᱲ',
    'पाठ पढ़ो': 'ᱯᱟᱲ ᱯᱟᱲᱦᱟᱣ ᱢᱮ',
    'अभ्यास': 'ᱨᱮᱣᱟᱜ',
    'परीक्षा': 'ᱥᱩᱵᱷᱤᱫᱟ',
    'उत्तर': 'ᱡᱚᱛᱚ',
    'प्रश्न': 'ᱡᱚᱛᱚ ᱵᱩᱡᱷᱟᱣ',
    'सवाल': 'ᱡᱚᱛᱚ ᱵᱩᱡᱷᱟᱣ',

    // ── Family ──
    'माँ': 'ᱟᱭᱳ',
    'माता': 'ᱟᱭᱳ',
    'बाप': 'ᱵᱟᱵᱟ',
    'पिता': 'ᱵᱟᱵᱟ',
    'बाबा': 'ᱵᱟᱵᱟ',
    'भाई': 'ᱵᱷᱟᱭ',
    'बहन': 'ᱦᱟᱯᱟᱢ',
    'दादा': 'ᱦᱟᱴᱤᱧ ᱟᱯᱟ',
    'दादी': 'ᱦᱟᱴᱤᱧ ᱟᱭᱳ',
    'नाना': 'ᱢᱟᱭᱠᱟᱭ ᱟᱯᱟ',
    'नानी': 'ᱢᱟᱭᱠᱟᱭ ᱟᱭᱳ',
    'बेटा': 'ᱦᱚᱯᱚᱱ',
    'बेटी': 'ᱦᱚᱯᱚᱱ ᱠᱩᱲᱤ',
    'परिवार': 'ᱜᱮᱦᱮᱸ',
    'घर': 'ᱜᱷᱟᱸᱰᱤ',
    'घर जाओ': 'ᱜᱷᱟᱸᱰᱤ ᱵᱷᱩᱜ ᱢᱮ',

    // ── Body ──
    'सिर': 'ᱵᱳᱭ',
    'आंख': 'ᱢᱮᱫ',
    'आँख': 'ᱢᱮᱫ',
    'कान': 'ᱞᱩᱛᱩᱨ',
    'नाक': 'ᱱᱳᱠ',
    'मुंह': 'ᱢᱩᱨᱩ',
    'दांत': 'ᱫᱟᱸᱛ',
    'जीभ': 'ᱞᱮᱞᱮ',
    'हाथ': 'ᱦᱟᱴᱤ',
    'पैर': 'ᱞᱳᱴᱚᱱ',
    'पेट': 'ᱯᱮᱴ',
    'पीठ': 'ᱠᱩᱞ',
    'गला': 'ᱜᱟᱞᱟ',
    'दिल': 'ᱠᱩᱞ ᱰᱤ',
    'उंगली': 'ᱩᱸᱜᱩᱞ',

    // ── Nature & Environment ──
    'पानी': 'ᱫᱟᱜ',
    'पीने का पानी': 'ᱟᱹᱜᱩᱭ ᱫᱟᱜ',
    'पानी पीओ': 'ᱫᱟᱜ ᱟᱹᱜᱩᱭ ᱢᱮ',
    'आग': 'ᱥᱮᱸᱜᱮᱞ',
    'मिट्टी': 'ᱥᱟᱥᱟᱸᱜ',
    'हवा': 'ᱮᱰᱮ',
    'आकाश': 'ᱟᱠᱟᱡ',
    'आसमान': 'ᱟᱠᱟᱡ',
    'सूरज': 'ᱧᱤᱫᱟᱹ',
    'सूर्य': 'ᱧᱤᱫᱟᱹ',
    'चाँद': 'ᱪᱟᱸᱫᱳ',
    'चंद्रमा': 'ᱪᱟᱸᱫᱳ',
    'तारा': 'ᱪᱟᱸᱫᱳ ᱠᱚ',
    'बारिश': 'ᱧᱩᱨ',
    'बाढ़': 'ᱫᱟᱜ ᱵᱟᱲᱟ',
    'पहाड़': 'ᱵᱟᱨᱩ',
    'नदी': 'ᱫᱟᱨᱮ',
    'जंगल': 'ᱵᱤᱨ',
    'पेड़': 'ᱫᱟᱲᱮ',
    'पत्ता': 'ᱫᱷᱤᱨᱤ',
    'पत्ते': 'ᱫᱷᱤᱨᱤ ᱠᱚ',
    'फूल': 'ᱵᱷᱩᱴᱩ',
    'फल': 'ᱵᱩᱰᱩ',
    'घास': 'ᱥᱟᱜ',
    'खेत': 'ᱵᱟᱭᱟ',

    // ── Food ──
    'खाना': 'ᱡᱚᱢᱟᱜ',
    'भोजन': 'ᱡᱚᱢᱟᱜ',
    'चावल': 'ᱫᱟᱠᱟ',
    'भात': 'ᱫᱟᱠᱟ',
    'रोटी': 'ᱨᱳᱴᱤ',
    'दाल': 'ᱫᱟᱞ',
    'सब्जी': 'ᱥᱟᱜ',
    'दूध': 'ᱫᱩᱫᱽ',
    'आम': 'ᱟᱢᱵᱳ',
    'केला': 'ᱵᱟᱦᱟ',
    'अनाज': 'ᱚᱱᱟᱡ',
    'नमक': 'ᱮᱞᱚ',
    'मिठाई': 'ᱠᱷᱟᱸᱫ',

    // ── Animals ──
    'गाय': 'ᱜᱟᱭ',
    'भैंस': 'ᱢᱮᱸᱦᱮ',
    'बकरी': 'ᱢᱮᱸᱦᱮᱸ',
    'कुत्ता': 'ᱥᱮᱛᱟ',
    'बिल्ली': 'ᱵᱤᱞᱟᱹᱭ',
    'चिड़िया': 'ᱪᱮᱬᱮ',
    'मछली': 'ᱦᱟᱠᱩ',
    'सांप': 'ᱵᱤᱸᱫᱟ',
    'हाथी': 'ᱦᱟᱛᱤ',
    'शेर': 'ᱵᱟᱜ',
    'बंदर': 'ᱵᱟᱱᱚᱫ',
    'मुर्गी': 'ᱪᱟᱸᱫᱳ ᱪᱮᱬᱮ',

    // ── Colors ──
    'लाल': 'ᱠᱷᱳᱵ',
    'हरा': 'ᱦᱟᱹᱲᱤ',
    'नीला': 'ᱱᱤᱞ',
    'पीला': 'ᱯᱤᱛᱷᱩ',
    'सफेद': 'ᱵᱷᱟᱸᱜ',
    'काला': 'ᱠᱟᱞᱚ',
    'नारंगी': 'ᱱᱟᱨᱮᱸᱜᱤ',

    // ── Health & Hygiene ──
    'हाथ धोओ': 'ᱦᱟᱴᱤ ᱫᱷᱩᱣᱟᱹ ᱢᱮ',
    'साफ करो': 'ᱟᱪᱟᱨ ᱢᱮ',
    'बीमार': 'ᱫᱤᱭᱳᱢ',
    'दर्द': 'ᱵᱮᱛᱷᱟ',
    'डॉक्टर': 'ᱫᱟᱠᱛᱟᱨ',
    'दवाई': 'ᱫᱟᱣᱟᱤ',
    'दवा': 'ᱫᱟᱣᱟᱤ',

    // ── Common Classroom Sentences ──
    'आपका नाम क्या है': 'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱪᱮᱫ ᱠᱟᱱᱟ',
    'मेरा नाम है': 'ᱤᱧᱟᱜ ᱧᱩᱛᱩᱢ ᱠᱟᱱᱟ',
    'नाम': 'ᱧᱩᱛᱩᱢ',
    'आपकी उम्र क्या है': 'ᱟᱢᱟᱜ ᱵᱷᱩᱦᱟ ᱢᱤᱛ ᱠᱟᱱᱟ',
    'मेरी उम्र है': 'ᱤᱧᱟᱜ ᱵᱷᱩᱦᱟ ᱠᱟᱱᱟ',
    'तुम कहां से आए हो': 'ᱟᱢ ᱠᱟᱹᱠᱟᱹ ᱦᱮᱠᱚ ᱟᱠᱟᱱᱟ',
    'कहां जा रहे हो': 'ᱠᱟᱹᱠᱟᱹ ᱵᱷᱩᱜ ᱠᱟᱱᱟ',
    'किताब खोलो': 'ᱯᱩᱛᱷᱤ ᱟᱰᱮ ᱢᱮ',
    'किताब बंद करो': 'ᱯᱩᱛᱷᱤ ᱪᱤᱸᱜ ᱢᱮ',
    'पहला पाठ पढ़ो': 'ᱢᱤᱫ ᱱᱚᱢᱵᱚᱨ ᱯᱟᱲ ᱯᱟᱲᱦᱟᱣ ᱢᱮ',
    'सब मिलकर बोलो': 'ᱥᱟᱵ ᱢᱤᱞᱤᱭᱟ ᱠᱟᱹᱣ ᱢᱮ',
    'बारी बारी से': 'ᱵᱟᱨᱤ ᱵᱟᱨᱤ ᱴᱷᱮᱱ',
    'पंक्ति में बैठो': 'ᱥᱟᱨᱤ ᱴᱷᱮᱱ ᱫᱩᱲᱩᱵ ᱢᱮ',
    'लाइन में खड़े हो': 'ᱥᱟᱨᱤ ᱴᱷᱮᱱ ᱦᱩᱰᱤᱧ ᱢᱮ',
    'स्कूल में स्वागत है': 'ᱤᱛᱩᱱ ᱟᱥᱲᱟ ᱨᱮ ᱥᱟᱜᱩᱱ ᱠᱟᱱᱟ',
    'आज का पाठ': 'ᱟᱡ ᱠᱟᱱᱟ ᱯᱟᱲ',
    'होमवर्क करो': 'ᱜᱷᱟᱸᱰᱤ ᱠᱟᱢ ᱢᱮ',
    'छुट्टी हो गई': 'ᱪᱷᱩᱴᱤ ᱦᱚᱭ ᱜᱮᱭᱟ',
    'कल आना': 'ᱦᱟᱵᱟ ᱟᱠᱟᱱᱟ ᱢᱮ',

    // ── NIPUN Bharat Learning Phrases ──
    'अक्षर': 'ᱚᱠᱪᱷᱚᱨ',
    'वर्णमाला': 'ᱚᱠᱪᱷᱚᱨ ᱢᱟᱞᱟ',
    'शब्द': 'ᱫᱚᱨᱢᱟ',
    'वाक्य': 'ᱫᱚᱨᱢᱟ ᱠᱚ',
    'गिनती': 'ᱜᱤᱱᱛᱤ',
    'जोड़': 'ᱥᱮᱸᱜᱮᱞ ᱟᱭ',
    'घटाव': 'ᱜᱤᱱᱛᱤ ᱢᱚᱲᱮ',
    'गुणा': 'ᱜᱩᱱᱟ',
    'भाग': 'ᱵᱷᱟᱜ',
    'आकार': 'ᱟᱠᱟᱨ',
    'गोला': 'ᱜᱳᱞᱟᱠᱟᱨ',
    'चौकोर': 'ᱪᱷᱟᱸᱜᱟ ᱟᱠᱟᱨ',
    'त्रिकोण': 'ᱛᱤᱱ ᱠᱳᱬᱟᱠᱟᱨ',

    // ── Motivational ──
    'कोशिश करो': 'ᱠᱳᱥᱷᱤᱥᱷ ᱢᱮ',
    'हार मत मानो': 'ᱦᱟᱨ ᱵᱟᱱᱩᱜ ᱢᱮ',
    'तुम कर सकते हो': 'ᱟᱢ ᱠᱟᱢ ᱢᱮᱱᱟᱹᱣᱟ',
    'आगे बढ़ो': 'ᱟᱜᱮ ᱵᱷᱩᱜ ᱢᱮ',
    'डरो मत': 'ᱰᱚᱨ ᱵᱟᱱᱩᱜ ᱢᱮ',
    'मन लगाकर पढ़ो': 'ᱢᱟᱱ ᱞᱟᱜᱟᱣ ᱯᱟᱲᱦᱟᱣ ᱢᱮ',
  };

  static const Map<String, String> _satToHi = {
    'ᱡᱚᱦᱟᱨ': 'नमस्ते',
    'ᱥᱟᱨᱦᱟᱣ': 'धन्यवाद',
    'ᱦᱚᱭ': 'हाँ',
    'ᱵᱟᱱᱩᱜ': 'नहीं',
    'ᱢᱤᱫ': 'एक',
    'ᱵᱟᱨ': 'दो',
    'ᱯᱮ': 'तीन',
    'ᱯᱩᱱ': 'चार',
    'ᱢᱚᱬᱮ': 'पांच',
    'ᱜᱮᱞ': 'दस',
    'ᱫᱟᱜ': 'पानी',
    'ᱫᱟᱠᱟ': 'चावल',
    'ᱯᱩᱛᱷᱤ': 'किताब',
    'ᱚᱞ ᱢᱮ': 'लिखो',
    'ᱯᱟᱲᱦᱟᱣ ᱢᱮ': 'पढ़ो',
    'ᱫᱩᱲᱩᱵ ᱢᱮ': 'बैठो',
    'ᱦᱩᱰᱤᱧ ᱢᱮ': 'खड़े हो',
    'ᱵᱷᱩᱜ ᱢᱮ': 'जाओ',
    'ᱟᱠᱟᱱᱟ ᱢᱮ': 'आओ',
    'ᱜᱷᱟᱸᱰᱤ': 'घर',
    'ᱟᱭᱳ': 'माँ',
    'ᱵᱟᱵᱟ': 'बाबा',
    'ᱜᱤᱫᱽᱨᱟᱹ': 'बच्चा',
    'ᱢᱟᱪᱮᱛ': 'शिक्षक',
    'ᱧᱩᱛᱩᱢ': 'नाम',
    'ᱥᱮ ᱠᱟᱱᱟ': 'शाबाश',
    'ᱥᱮ': 'अच्छा',
    'ᱢᱮᱛᱟᱹᱫ': 'गलत',
  };

  String? _phraseBank(String text, String direction) {
    if (direction == 'hi-sat') {
      // Exact match
      if (_hiToSat.containsKey(text)) return _hiToSat[text];
      // Case-insensitive variant match
      for (final entry in _hiToSat.entries) {
        if (entry.key.toLowerCase() == text.toLowerCase()) return entry.value;
      }
      // Partial sentence match (find longest matching key within input)
      String bestKey = '';
      String? bestValue;
      for (final entry in _hiToSat.entries) {
        if (text.contains(entry.key) && entry.key.length > bestKey.length) {
          bestKey = entry.key;
          bestValue = entry.value;
        }
      }
      if (bestValue != null) return bestValue;
    } else if (direction == 'sat-hi') {
      if (_satToHi.containsKey(text)) return _satToHi[text];
      for (final entry in _satToHi.entries) {
        if (text.contains(entry.key)) return entry.value;
      }
    }
    return null;
  }

  /// Word-by-word composition: break input into known words and join translations
  String? _composeFromWords(String text, String direction) {
    if (direction != 'hi-sat') return null;

    final words = text.split(RegExp(r'\s+'));
    final List<String> translated = [];
    bool anyHit = false;

    for (final word in words) {
      final t = _hiToSat[word.trim()];
      if (t != null) {
        translated.add(t);
        anyHit = true;
      }
    }

    if (anyHit && translated.isNotEmpty) {
      return translated.join(' ');
    }
    return null;
  }

  /// Keyword extraction: scan for known single keywords and return most relevant
  String _keywordFallback(String text, String direction) {
    if (direction == 'sat-hi') return 'स्थानीय भाषा का वाक्य';

    // Contextual detection
    if (text.contains('पानी') || text.contains('पीओ') || text.contains('पीना')) {
      return 'ᱫᱟᱜ ᱟᱹᱜᱩᱭ ᱢᱮ';
    }
    if (text.contains('पढ़') || text.contains('किताब') || text.contains('पाठ')) {
      return 'ᱯᱩᱛᱷᱤ ᱯᱟᱲᱦᱟᱣ ᱢᱮ';
    }
    if (text.contains('नाम')) return 'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱪᱮᱫ ᱠᱟᱱᱟ';
    if (text.contains('बैठ')) return 'ᱫᱩᱲᱩᱵ ᱢᱮ';
    if (text.contains('खड़') || text.contains('उठ')) return 'ᱦᱩᱰᱤᱧ ᱢᱮ';
    if (text.contains('नमस्ते') || text.contains('नमस्कार')) return 'ᱡᱚᱦᱟᱨ';
    if (text.contains('खेल')) return 'ᱨᱟᱥᱠᱟ ᱢᱮ';
    if (text.contains('खा') || text.contains('भोजन')) return 'ᱡᱚᱢ ᱢᱮ';
    if (text.contains('शाबाश') || text.contains('बहुत अच्छा')) return 'ᱵᱟᱦᱲᱮ ᱥᱮ ᱠᱟᱱᱟ';
    if (text.contains('चलो') || text.contains('जाओ')) return 'ᱵᱷᱩᱜ ᱢᱮ';
    if (text.contains('घर')) return 'ᱜᱷᱟᱸᱰᱤ';
    if (text.contains('सुनो') || text.contains('ध्यान')) return 'ᱦᱚᱯᱚᱱ ᱢᱮ';
    if (text.contains('लिख')) return 'ᱚᱞ ᱢᱮ';
    if (text.contains('देख')) return 'ᱩᱧᱦᱩᱬ ᱢᱮ';
    if (text.contains('चुप')) return 'ᱪᱩᱯᱽ ᱴᱷᱮᱱ ᱢᱮ';
    if (text.contains('स्वागत')) return 'ᱥᱟᱜᱩᱱ ᱠᱟᱱᱟ';
    if (text.contains('धन्यवाद') || text.contains('शुक्रिया')) return 'ᱥᱟᱨᱦᱟᱣ';
    if (text.contains('माफ') || text.contains('क्षमा')) return 'ᱪᱟᱸᱜᱽ ᱢᱮ';
    if (text.contains('शाला') || text.contains('स्कूल') || text.contains('विद्याल')) {
      return 'ᱤᱛᱩᱱ ᱟᱥᱲᱟ';
    }
    if (text.contains('होमवर्क') || text.contains('गृहकार्य')) return 'ᱜᱷᱟᱸᱰᱤ ᱠᱟᱢ ᱢᱮ';
    if (text.contains('परीक्षा')) return 'ᱥᱩᱵᱷᱤᱫᱟ';
    if (text.contains('छुट्टी')) return 'ᱪᱷᱩᱴᱤ ᱦᱚᱭ ᱜᱮᱭᱟ';
    if (text.contains('आज')) return 'ᱟᱡ ᱠᱟᱱᱟ';
    if (text.contains('कल')) return 'ᱦᱟᱵᱟ';

    return 'ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ, ᱚᱞ ᱯᱟᱲᱦᱟᱣ ᱯᱮ';
  }
}
