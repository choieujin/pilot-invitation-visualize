# 청첩장 실물 미리보기 (Invitation Visualize)

청첩장 **시안 PDF**를 업로드하면, 인쇄된 카드가 실제로 어떻게 보일지
여러 연출(목업)로 미리 만들어 주는 Flutter 앱입니다.

> 사진 합성(AI 생성)이 아니라, PDF를 페이지 이미지로 렌더링한 뒤
> 종이 두께·그림자·조명·표면 질감을 입힌 **목업 합성** 방식이라
> 외부 API 키 없이 오프라인으로 즉시 동작합니다.

## 동작 방식

1. **업로드** — 사용자가 청첩장 시안 PDF를 선택합니다.
2. **렌더링** — `printing` 패키지로 각 페이지를 비트맵으로 렌더합니다
   (웹: pdf.js / 네이티브: pdfium).
3. **합성** — `MockupPainter`가 페이지 이미지를 실물 카드 장면에 합성합니다.
   - 3D 원근 기울기 (`Matrix4`)
   - 종이 단면(여러 장이 쌓인 두께)
   - 부드러운 접지 그림자, 조명 그라데이션, 비네팅
   - 리넨/스튜디오 배경, 유칼립투스 소품, 광택 표면 반사
4. **저장** — 결과를 고해상도 PNG로 다운로드(웹)/저장(데스크톱·모바일)합니다.

## 연출 스타일

| 스타일 | 설명 |
| --- | --- |
| 플랫레이 | 리넨 위에 살짝 비스듬히 놓인 카드 |
| 스탠딩 | 광택 표면 위에 세워둔 카드와 반사 |
| 앵글 | 종이 두께가 보이는 3/4 각도 샷 |
| 미니멀 | 깔끔한 스튜디오 그라데이션 정면 샷 |

## 프로젝트 구조

```
lib/
  main.dart                     앱 진입점
  app.dart                      테마 / MaterialApp
  models/mockup_style.dart      목업 스타일 프리셋 정의
  services/
    pdf_rasterizer.dart         PDF → 페이지 이미지
    mockup_exporter.dart        장면 → 고해상도 PNG
    file_saver*.dart            플랫폼별 저장(웹/IO)
  widgets/
    mockup_painter.dart         핵심 합성 로직 (CustomPainter)
    mockup_view.dart            미리보기 위젯
  screens/home_screen.dart      업로드 · 편집 · 저장 UI
```

## 실행

```bash
flutter pub get
flutter run -d chrome   # 웹
flutter run -d linux    # 데스크톱
```

## 테스트

```bash
flutter test
```

`test/visual_preview_test.dart`는 가짜 청첩장을 그려 각 스타일을
`build/preview/<style>.png`로 렌더링합니다(시각 회귀 점검용).
