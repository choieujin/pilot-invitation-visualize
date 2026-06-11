import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invitation_visualize/models/mockup_style.dart';
import 'package:invitation_visualize/services/mockup_exporter.dart';

/// 가짜 청첩장 한 장을 그려 ui.Image로 만든다.
Future<ui.Image> _fakeInvitation() async {
  const w = 600, h = 850;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());

  canvas.drawRect(rect, Paint()..color = const Color(0xFFFBF6EE));
  // 얇은 테두리 프레임
  canvas.drawRect(
    rect.deflate(34),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFB99B6E),
  );

  void text(String s, double y, double size, Color color,
      {FontWeight weight = FontWeight.w400, double spacing = 1}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: w.toDouble() - 100);
    tp.paint(canvas, Offset((w - tp.width) / 2, y));
  }

  text('WEDDING INVITATION', 110, 18, const Color(0xFFB99B6E), spacing: 4);
  text('민준', 250, 56, const Color(0xFF3A332B), weight: FontWeight.w600);
  text('&', 330, 34, const Color(0xFFB99B6E));
  text('서연', 380, 56, const Color(0xFF3A332B), weight: FontWeight.w600);
  text('2026. 09. 12. SAT  PM 1:00', 560, 22, const Color(0xFF5A5249),
      spacing: 1.5);
  text('그랜드볼룸 웨딩홀', 610, 20, const Color(0xFF7A7064));

  final picture = recorder.endRecording();
  return picture.toImage(w, h);
}

void main() {
  testWidgets('각 목업 스타일을 PNG로 렌더링한다', (tester) async {
    final outDir = Directory('build/preview')..createSync(recursive: true);

    // 엔진 비동기(Picture.toImage / Image.toByteData)는 runAsync 안에서만
    // 정상적으로 완료된다. 밖에서 호출하면 두 번째부터 멈춘다.
    await tester.runAsync(() async {
      final page = await _fakeInvitation();
      for (final style in kDefaultStyles) {
        final bytes = await MockupExporter.renderPng(page, style, width: 900);
        expect(bytes.lengthInBytes, greaterThan(1000));
        File('${outDir.path}/${style.id}.png').writeAsBytesSync(bytes);
      }
    });
  });
}
