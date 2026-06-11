import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/mockup_style.dart';
import 'mockup_painter.dart';

/// 청첩장 페이지를 목업 장면으로 합성해 보여주는 위젯.
class MockupView extends StatelessWidget {
  const MockupView({
    super.key,
    required this.page,
    required this.style,
    this.borderRadius = 16,
  });

  final ui.Image page;
  final MockupStyle style;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AspectRatio(
        aspectRatio: kSceneAspect,
        child: CustomPaint(
          painter: MockupPainter(page: page, style: style),
          size: Size.infinite,
        ),
      ),
    );
  }
}
