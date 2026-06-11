import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

class InvitationVisualizeApp extends StatelessWidget {
  const InvitationVisualizeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFB08968),
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: '청첩장 실물 미리보기',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFFAF7F2),
        fontFamily: 'Roboto',
        useMaterial3: true,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
