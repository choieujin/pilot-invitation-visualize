import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// 웹: Blob을 만들어 브라우저 다운로드를 트리거한다.
Future<void> saveBytes(Uint8List bytes, String fileName) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor =
      web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
}
