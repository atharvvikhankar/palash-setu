import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/login_screen.dart';
import 'features/onboarding/language_selection_screen.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  final teacherName = prefs.getString('teacher_name') ?? '';
  
  Widget initialScreen;
  if (!onboardingComplete) {
    if (teacherName.isEmpty) {
      initialScreen = const LoginScreen();
    } else {
      initialScreen = const LanguageSelectionScreen();
    }
  } else {
    initialScreen = const HomeScreen();
  }

  runApp(
    ProviderScope(
      child: PalashSetuApp(initialScreen: initialScreen),
    ),
  );
}

class PalashSetuApp extends StatelessWidget {
  final Widget initialScreen;
  
  const PalashSetuApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PALASH SETU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialScreen,
    );
  }
}
