/// PNG 바이트를 플랫폼에 맞게 저장한다.
///
/// 웹은 브라우저 다운로드, 데스크톱/모바일은 파일 저장 다이얼로그를 사용한다.
library;

export 'file_saver_io.dart'
    if (dart.library.js_interop) 'file_saver_web.dart';
