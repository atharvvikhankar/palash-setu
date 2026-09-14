import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/database_service.dart';
import '../services/translation_service.dart';

// Services
final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());

/// TranslationService provider — initializes on-device ASR (SpeechRecognizer)
/// and TTS (TextToSpeech) automatically when first accessed.
final translationServiceProvider = Provider<TranslationService>((ref) {
  final service = TranslationService();
  // Initialize on-device mic + TTS in the background
  service.initialize();
  ref.onDispose(service.dispose);
  return service;
});


// Connectivity State Provider
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  if (initial.isNotEmpty) {
    yield initial.first;
  } else {
    yield ConnectivityResult.none;
  }
  await for (final results in connectivity.onConnectivityChanged) {
    if (results.isNotEmpty) {
      yield results.first;
    } else {
      yield ConnectivityResult.none;
    }
  }
});

// Settings & Preferences State Notifiers
class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  AppSettingsNotifier() : super(AppSettingsState.initial()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final onboarding = prefs.getBool('onboarding_complete') ?? false;
    final name = prefs.getString('teacher_name') ?? '';
    final mobile = prefs.getString('teacher_mobile') ?? '';
    final lang = prefs.getString('ui_language') ?? 'en';
    final direction = prefs.getString('translation_direction') ?? 'hi-sat';
    final textSize = prefs.getDouble('text_size') ?? 16.0;

    state = AppSettingsState(
      onboardingComplete: onboarding,
      teacherName: name,
      teacherMobile: mobile,
      uiLanguage: lang,
      translationDirection: direction,
      textSize: textSize,
    );
  }

  Future<void> saveProfile(String name, String mobile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('teacher_name', name);
    await prefs.setString('teacher_mobile', mobile);
    state = state.copyWith(teacherName: name, teacherMobile: mobile);
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ui_language', lang);
    await prefs.setBool('onboarding_complete', true);
    state = state.copyWith(uiLanguage: lang, onboardingComplete: true);
  }

  Future<void> setTranslationDirection(String direction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('translation_direction', direction);
    state = state.copyWith(translationDirection: direction);
  }

  Future<void> setTextSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('text_size', size);
    state = state.copyWith(textSize: size);
  }
}

class AppSettingsState {
  final bool onboardingComplete;
  final String teacherName;
  final String teacherMobile;
  final String uiLanguage;
  final String translationDirection;
  final double textSize;

  AppSettingsState({
    required this.onboardingComplete,
    required this.teacherName,
    required this.teacherMobile,
    required this.uiLanguage,
    required this.translationDirection,
    required this.textSize,
  });

  factory AppSettingsState.initial() => AppSettingsState(
        onboardingComplete: false,
        teacherName: '',
        teacherMobile: '',
        uiLanguage: 'en',
        translationDirection: 'hi-sat',
        textSize: 16.0,
      );

  AppSettingsState copyWith({
    bool? onboardingComplete,
    String? teacherName,
    String? teacherMobile,
    String? uiLanguage,
    String? translationDirection,
    double? textSize,
  }) {
    return AppSettingsState(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      teacherName: teacherName ?? this.teacherName,
      teacherMobile: teacherMobile ?? this.teacherMobile,
      uiLanguage: uiLanguage ?? this.uiLanguage,
      translationDirection: translationDirection ?? this.translationDirection,
      textSize: textSize ?? this.textSize,
    );
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>(
  (ref) => AppSettingsNotifier(),
);
