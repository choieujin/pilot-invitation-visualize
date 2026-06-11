import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

/// 앱 전역 테마. 테스트/데모에서도 동일한 외형을 쓰기 위해 분리.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFB08968),
    brightness: Brightness.light,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFFAF7F2),
    fontFamily: 'NanumGothic',
    useMaterial3: true,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      ),
    ),
  );
}

class InvitationVisualizeApp extends StatelessWidget {
  const InvitationVisualizeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '청첩장 실물 미리보기',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}
