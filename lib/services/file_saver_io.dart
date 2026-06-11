import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// 데스크톱/모바일: 저장 위치를 묻고 파일로 기록한다.
Future<void> saveBytes(Uint8List bytes, String fileName) async {
  final path = await FilePicker.saveFile(
    dialogTitle: '목업 이미지 저장',
    fileName: fileName,
    type: FileType.image,
    bytes: bytes,
  );
  if (path != null && !File(path).existsSync()) {
    // 일부 플랫폼은 bytes를 직접 기록하지 않으므로 보강한다.
    await File(path).writeAsBytes(bytes);
  }
}
