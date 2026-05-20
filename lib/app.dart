import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/diagnostics_screen.dart';

class LenkerApp extends StatelessWidget {
  final bool isAuthenticated;

  const LenkerApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lenker',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: isAuthenticated ? '/home' : '/onboarding',
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/home': (_) => const HomeScreen(),
        '/diagnostics': (_) => const DiagnosticsScreen(),
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF6C8EFF),
        surface: const Color(0xFF0F1923),
        error: Colors.red.shade300,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F1923),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF162233),
        elevation: 0,
      ),
      cardTheme: const CardTheme(
        color: Color(0xFF162233),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFF162233),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
