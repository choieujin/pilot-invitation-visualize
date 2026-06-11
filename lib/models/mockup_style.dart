import 'package:flutter/material.dart';

/// 목업 장면의 가로:세로 비율(세로형 4:5).
const double kSceneAspect = 4 / 5;

/// 청첩장 실물 목업 장면의 한 가지 연출 스타일.
///
/// 배경(테이블/스튜디오), 카드의 3D 기울기, 그림자, 종이 두께 등
/// "실물처럼 보이게" 만드는 모든 파라미터를 담는다.
@immutable
class MockupStyle {
  const MockupStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.background,
    this.rotateX = 0,
    this.rotateY = 0,
    this.rotateZ = 0,
    this.widthFactor = 0.62,
    this.center = const Offset(0.5, 0.5),
    this.showProps = false,
    this.glossy = false,
  });

  /// 내부 식별자.
  final String id;

  /// 사용자에게 보여줄 이름. (예: 플랫레이)
  final String name;

  /// 짧은 설명.
  final String description;

  /// 배경 장면 묘사.
  final SceneBackground background;

  /// 카드를 위/아래로 눕히는 각도(라디안). 양수면 뒤로 눕는다.
  final double rotateX;

  /// 카드를 좌/우로 트는 각도(라디안).
  final double rotateY;

  /// 화면 평면 안에서 회전(라디안).
  final double rotateZ;

  /// 카드 폭이 장면 폭에서 차지하는 비율.
  final double widthFactor;

  /// 카드 중심 위치(장면 크기 대비 0~1 비율).
  final Offset center;

  /// 유칼립투스/반지 등 소품을 그릴지 여부.
  final bool showProps;

  /// 바닥에 반사(글로시 표면)를 줄지 여부.
  final bool glossy;
}

/// 배경 표면의 종류와 색감.
@immutable
class SceneBackground {
  const SceneBackground({
    required this.topColor,
    required this.bottomColor,
    this.highlight,
    this.vignette = 0.22,
    this.grain = 0.0,
  });

  final Color topColor;
  final Color bottomColor;

  /// 부드러운 스포트라이트 색(없으면 미사용).
  final Color? highlight;

  /// 가장자리 어둡게(0~1).
  final double vignette;

  /// 종이/패브릭 질감 노이즈 강도(0~1).
  final double grain;
}

/// 기본 제공 목업 스타일 프리셋.
const List<MockupStyle> kDefaultStyles = [
  MockupStyle(
    id: 'flatlay',
    name: '플랫레이',
    description: '리넨 위에 살짝 비스듬히 놓인 카드',
    background: SceneBackground(
      topColor: Color(0xFFF3EEE7),
      bottomColor: Color(0xFFE3DACD),
      highlight: Color(0x33FFFFFF),
      vignette: 0.26,
      grain: 0.05,
    ),
    rotateX: 0.06,
    rotateZ: -0.05,
    widthFactor: 0.58,
    center: Offset(0.5, 0.5),
    showProps: true,
  ),
  MockupStyle(
    id: 'standing',
    name: '스탠딩',
    description: '광택 표면 위에 세워둔 카드와 반사',
    background: SceneBackground(
      topColor: Color(0xFFEDE7F0),
      bottomColor: Color(0xFFD8CFE0),
      highlight: Color(0x40FFFFFF),
      vignette: 0.28,
    ),
    rotateX: 0.18,
    rotateY: -0.12,
    widthFactor: 0.5,
    center: Offset(0.5, 0.44),
    glossy: true,
  ),
  MockupStyle(
    id: 'angle',
    name: '앵글',
    description: '종이 두께가 보이는 3/4 각도 샷',
    background: SceneBackground(
      topColor: Color(0xFFF6F1EA),
      bottomColor: Color(0xFFDCD2C4),
      highlight: Color(0x33FFFFFF),
      vignette: 0.24,
      grain: 0.04,
    ),
    rotateX: 0.34,
    rotateY: 0.26,
    rotateZ: 0.02,
    widthFactor: 0.56,
    center: Offset(0.5, 0.46),
  ),
  MockupStyle(
    id: 'studio',
    name: '미니멀',
    description: '깔끔한 스튜디오 그라데이션 정면 샷',
    background: SceneBackground(
      topColor: Color(0xFFFBFAF8),
      bottomColor: Color(0xFFE9E7E3),
      highlight: Color(0x22FFFFFF),
      vignette: 0.18,
    ),
    rotateX: 0.04,
    widthFactor: 0.52,
    center: Offset(0.5, 0.5),
  ),
];
