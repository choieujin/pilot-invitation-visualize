import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import '../models/mockup_style.dart';
import '../widgets/mockup_painter.dart';
import 'file_saver.dart';

/// 목업 장면을 화면과 독립적으로 고해상도 PNG로 렌더링하고 저장한다.
class MockupExporter {
  /// [page]를 [style] 장면으로 합성해 PNG 바이트로 반환한다.
  static Future<Uint8List> renderPng(
    ui.Image page,
    MockupStyle style, {
    int width = 1400,
  }) async {
    final height = (width / kSceneAspect).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(width.toDouble(), height.toDouble());
    MockupPainter(page: page, style: style).paint(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  /// PNG로 렌더링한 뒤 플랫폼에 맞게 저장/다운로드한다.
  static Future<void> exportPng(
    ui.Image page,
    MockupStyle style, {
    String? fileName,
  }) async {
    final bytes = await renderPng(page, style);
    await saveBytes(bytes, fileName ?? 'invitation_${style.id}.png');
  }
}
