import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:invitation_visualize/app.dart';

void main() {
  testWidgets('첫 화면에 업로드 안내가 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(const InvitationVisualizeApp());
    await tester.pump();

    expect(find.text('청첩장 시안 PDF를 올려주세요'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'PDF 선택'), findsOneWidget);
  });
}
