import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:printing/printing.dart';

/// 청첩장 PDF 한 페이지의 렌더 결과.
class RenderedPage {
  RenderedPage({required this.index, required this.image});

  /// 0-기반 페이지 번호.
  final int index;

  /// 렌더된 비트맵.
  final ui.Image image;

  double get aspectRatio => image.width / image.height;
}

/// PDF 바이트를 페이지별 [ui.Image]로 렌더링한다.
///
/// 웹에서는 pdf.js, 네이티브에서는 pdfium을 사용한다(printing 패키지).
class PdfRasterizer {
  /// [bytes]의 모든 페이지를 [dpi] 해상도로 렌더링한다.
  static Future<List<RenderedPage>> render(
    Uint8List bytes, {
    double dpi = 160,
    int maxPages = 20,
  }) async {
    final pages = <RenderedPage>[];
    var index = 0;
    await for (final raster in Printing.raster(bytes, dpi: dpi)) {
      final image = await raster.toImage();
      pages.add(RenderedPage(index: index, image: image));
      index++;
      if (index >= maxPages) break;
    }
    return pages;
  }
}
