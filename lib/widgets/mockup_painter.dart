import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/mockup_style.dart';

/// 렌더링된 청첩장 페이지([page])를 [style]에 맞는 실물 목업 장면으로
/// 합성하는 CustomPainter.
///
/// 배경 → 바닥 그림자 → 종이 두께(스택 엣지) → 카드 이미지 →
/// 조명/광택 오버레이 → 비네팅 순으로 그린다.
class MockupPainter extends CustomPainter {
  MockupPainter({required this.page, required this.style});

  /// 청첩장 한 페이지의 렌더 결과.
  final ui.Image page;

  final MockupStyle style;

  static const double _cornerRadius = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = style.background;
    final fullRect = Offset.zero & size;

    // 1) 배경 그라데이션.
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        [bg.topColor, bg.bottomColor],
      );
    canvas.drawRect(fullRect, bgPaint);

    // 부드러운 스포트라이트.
    if (bg.highlight != null) {
      final hPaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.5, size.height * 0.34),
          size.width * 0.7,
          [bg.highlight!, bg.highlight!.withValues(alpha: 0)],
        );
      canvas.drawRect(fullRect, hPaint);
    }

    if (bg.grain > 0) {
      _paintGrain(canvas, size, bg.grain);
    }

    // 카드 기본 크기(정면 기준).
    final cardWidth = size.width * style.widthFactor;
    final aspect = page.width / page.height;
    final cardHeight = cardWidth / aspect;
    final cardRect = Rect.fromCenter(
      center: Offset.zero,
      width: cardWidth,
      height: cardHeight,
    );
    final rrect = RRect.fromRectAndRadius(
      cardRect,
      const Radius.circular(_cornerRadius),
    );

    final center = Offset(
      size.width * style.center.dx,
      size.height * style.center.dy,
    );

    // 카드의 3D 변환 행렬(중심 기준).
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0011) // 원근
      ..rotateX(style.rotateX)
      ..rotateY(style.rotateY)
      ..rotateZ(style.rotateZ);

    // 2) 바닥 접지 그림자(변환 전, 장면 평면에 그린다).
    _paintGroundShadow(canvas, center, cardRect, transform);

    // 글로시 표면 반사.
    if (style.glossy) {
      _paintReflection(canvas, center, cardRect, bg.bottomColor);
    }

    // 소품(유칼립투스/링)
    if (style.showProps) {
      _paintProps(canvas, center, cardRect);
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.transform(transform.storage);

    // 3) 종이 두께(스택 엣지) — 빛의 반대 방향으로 살짝 깔아 종이 단면을 표현.
    _paintPaperEdge(canvas, cardRect, rrect);

    // 4) 카드 이미지.
    canvas.save();
    canvas.clipRRect(rrect);
    paintImage(
      canvas: canvas,
      rect: cardRect,
      image: page,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
    );

    // 5) 조명 오버레이(좌상단 하이라이트 → 우하단 음영).
    final lightPaint = Paint()
      ..blendMode = BlendMode.softLight
      ..shader = ui.Gradient.linear(
        cardRect.topLeft,
        cardRect.bottomRight,
        [
          const Color(0x4DFFFFFF),
          const Color(0x00FFFFFF),
          const Color(0x1A000000),
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawRect(cardRect, lightPaint);
    canvas.restore();

    // 카드 테두리 하이라이트(종이 가장자리 광택).
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x33FFFFFF);
    canvas.drawRRect(rrect.deflate(0.6), edgePaint);

    canvas.restore();

    // 6) 전체 비네팅.
    if (bg.vignette > 0) {
      final vignettePaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width / 2, size.height / 2),
          size.width * 0.75,
          [
            const Color(0x00000000),
            Color.fromRGBO(0, 0, 0, bg.vignette),
          ],
          [0.6, 1.0],
        );
      canvas.drawRect(fullRect, vignettePaint);
    }
  }

  /// 종이 단면(여러 장이 쌓인 두께)을 카드 뒤에 깔아 입체감을 준다.
  void _paintPaperEdge(Canvas canvas, Rect cardRect, RRect rrect) {
    const layers = 5;
    // 빛이 좌상단에서 오므로 두께는 우하단으로 드러난다.
    const step = Offset(1.1, 1.6);
    for (int i = layers; i >= 1; i--) {
      final t = i / layers;
      final color = Color.lerp(
        const Color(0xFFFFFFFF),
        const Color(0xFFCDBFA8),
        t,
      )!;
      final paint = Paint()..color = color;
      canvas.save();
      canvas.translate(step.dx * i, step.dy * i);
      canvas.drawRRect(rrect, paint);
      canvas.restore();
    }
  }

  /// 카드가 바닥에 드리우는 부드러운 그림자.
  void _paintGroundShadow(
    Canvas canvas,
    Offset center,
    Rect cardRect,
    Matrix4 transform,
  ) {
    // 카드 네 모서리를 변환해 실제 화면상 풋프린트를 구한 뒤,
    // 그 아래로 그림자를 드리운다.
    final corners = [
      cardRect.topLeft,
      cardRect.topRight,
      cardRect.bottomRight,
      cardRect.bottomLeft,
    ].map((c) => center + MatrixUtils.transformPoint(transform, c)).toList();

    final path = Path()..addPolygon(corners, true);
    // 빛 반대 방향(우하단)으로 약간 이동 + 확대.
    final shadow = path.shift(const Offset(10, 16));
    final paint = Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 22);
    canvas.drawPath(shadow, paint);
  }

  /// 글로시 바닥에 비치는 카드의 흐릿한 반사.
  ///
  /// 광택 바닥 느낌을 주는 부드러운 반사 글로우.
  ///
  /// 음수 스케일(`scale(1,-1)`)로 이미지를 뒤집는 진짜 거울 반사는
  /// 소프트웨어 렌더러에서 toImage를 멈추게 하므로 사용하지 않는다.
  /// 대신 카드 하단 색을 표본으로 한 빛 번짐을 바닥에 깔아
  /// 윤기 있는 표면에 카드가 비치는 인상만 준다.
  void _paintReflection(
    Canvas canvas,
    Offset center,
    Rect cardRect,
    Color surfaceColor,
  ) {
    final top = center.dy + cardRect.height * 0.5;
    final glowRect = Rect.fromLTWH(
      center.dx - cardRect.width * 0.5,
      top,
      cardRect.width,
      cardRect.height * 0.42,
    );
    // 카드 바로 아래에서 밝게 시작해 빠르게 표면색으로 사라진다.
    final glow = Paint()
      ..shader = ui.Gradient.linear(
        glowRect.topCenter,
        glowRect.bottomCenter,
        [
          const Color(0x40FFFFFF),
          surfaceColor.withValues(alpha: 0),
        ],
      );
    canvas.drawRect(glowRect, glow);
  }

  /// 유칼립투스 잔가지와 반지 등 분위기 소품.
  void _paintProps(Canvas canvas, Offset center, Rect cardRect) {
    final stemPaint = Paint()
      ..color = const Color(0xFF8FA277)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final leafPaint = Paint()..color = const Color(0xCC9CB07F);

    // 좌상단에서 카드 쪽으로 뻗는 가지.
    final start = center + Offset(-cardRect.width * 0.62, -cardRect.height * 0.5);
    final end = center + Offset(-cardRect.width * 0.28, -cardRect.height * 0.62);
    final stem = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
        (start.dx + end.dx) / 2,
        start.dy - 24,
        end.dx,
        end.dy,
      );
    canvas.drawPath(stem, stemPaint);

    final rnd = math.Random(7);
    for (double t = 0.15; t < 1.0; t += 0.16) {
      final p = _quadAt(start, Offset((start.dx + end.dx) / 2, start.dy - 24), end, t);
      final side = (t * 100).floor().isEven ? 1 : -1;
      final angle = -0.5 * side + (rnd.nextDouble() - 0.5) * 0.3;
      _paintLeaf(canvas, p, angle, 9 + rnd.nextDouble() * 4, leafPaint);
    }
  }

  void _paintLeaf(Canvas canvas, Offset at, double angle, double r, Paint paint) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(r * 0.6, -r * 0.5, r * 1.6, 0)
      ..quadraticBezierTo(r * 0.6, r * 0.5, 0, 0);
    canvas.drawPath(leaf, paint);
    canvas.restore();
  }

  Offset _quadAt(Offset a, Offset c, Offset b, double t) {
    final mt = 1 - t;
    return a * (mt * mt) + c * (2 * mt * t) + b * (t * t);
  }

  /// 미세한 질감 노이즈.
  void _paintGrain(Canvas canvas, Size size, double strength) {
    final rnd = math.Random(42);
    final paint = Paint();
    final count = (size.width * size.height / 900).clamp(0, 4000).toInt();
    for (int i = 0; i < count; i++) {
      final dx = rnd.nextDouble() * size.width;
      final dy = rnd.nextDouble() * size.height;
      final v = (rnd.nextDouble() - 0.5) * strength;
      paint.color = v >= 0
          ? Color.fromRGBO(255, 255, 255, v.abs())
          : Color.fromRGBO(0, 0, 0, v.abs());
      canvas.drawCircle(Offset(dx, dy), 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MockupPainter old) =>
      old.page != page || old.style != style;
}
