import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invitation_visualize/app.dart';
import 'package:invitation_visualize/screens/home_screen.dart';
import 'package:invitation_visualize/services/pdf_rasterizer.dart';

/// 청첩장 한 장을 NanumGothic으로 그려 실제 시안처럼 만든다.
Future<ui.Image> _invitation() async {
  const w = 620, h = 880;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final full = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());

  // 종이 + 이중 골드 프레임.
  canvas.drawRect(full, Paint()..color = const Color(0xFFFCF8F1));
  final frame = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xFFC2A36B);
  canvas.drawRect(full.deflate(30), frame..strokeWidth = 2.4);
  canvas.drawRect(full.deflate(38), frame..strokeWidth = 0.8);

  void center(String s, double y, double size, Color color,
      {FontWeight weight = FontWeight.w400, double spacing = 1}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: 'NanumGothic',
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((w - tp.width) / 2, y));
  }

  center('W E D D I N G   I N V I T A T I O N', 96, 15,
      const Color(0xFFB08F58), spacing: 1.5);
  // 장식 라인
  canvas.drawLine(const Offset(250, 132), const Offset(370, 132),
      Paint()..color = const Color(0xFFC2A36B)..strokeWidth = 1);

  center('김민준', 250, 52, const Color(0xFF36302A), weight: FontWeight.w700);
  center('그리고', 330, 22, const Color(0xFFB08F58));
  center('이서연', 380, 52, const Color(0xFF36302A), weight: FontWeight.w700);

  center('2026년 9월 12일 토요일 오후 1시', 540, 21, const Color(0xFF5A5249));
  center('그랜드볼룸 웨딩홀 3층 그레이스홀', 580, 19, const Color(0xFF7A7064));

  center('저희 두 사람이 사랑으로 만나', 690, 17, const Color(0xFF8A8174));
  center('한 가정을 이루게 되었습니다.', 716, 17, const Color(0xFF8A8174));

  return recorder.endRecording().toImage(w, h);
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    final bytes = File(p).readAsBytesSync();
    loader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
  }
  await loader.load();
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('build/screenshots')..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(
      data!.buffer.asUint8List(),
    );
    image.dispose();
  });
}

void main() {
  testWidgets('실제 앱 편집 화면을 스크린샷으로 저장한다', (tester) async {
    tester.view.physicalSize = const Size(1280, 880);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late List<RenderedPage> pages;
    await tester.runAsync(() async {
      await _loadFont('NanumGothic', [
        'assets/fonts/NanumGothic-Regular.ttf',
        'assets/fonts/NanumGothic-Bold.ttf',
      ]);
      final img = await _invitation();
      pages = [RenderedPage(index: 0, image: img)];
    });

    final rootKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: rootKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: HomeScreen(
            initialPages: pages,
            initialFileName: 'mina-junho-invitation.pdf',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 기본(플랫레이) 화면.
    await _capture(tester, rootKey, '01_flatlay');

    // '앵글' 스타일 선택 후.
    await tester.tap(find.text('앵글'));
    await tester.pumpAndSettle();
    await _capture(tester, rootKey, '02_angle');

    // '스탠딩' 스타일 선택 후.
    await tester.tap(find.text('스탠딩'));
    await tester.pumpAndSettle();
    await _capture(tester, rootKey, '03_standing');
  });
}
