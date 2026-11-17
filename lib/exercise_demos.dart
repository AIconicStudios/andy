// Generated from a pose prototype. Coordinates are in a 100 x 100 box,
// y pointing down, the floor at y = 92, the figure facing right.

import 'dart:ui';

import 'silhouette.dart';

const demos = <String, Demo>{
  'incline_pushup': Demo(
    arm: 1,
    leg: -1,
    props: [Prop.box(Rect.fromLTRB(70, 64, 86, 92.0))],
    frames: [
      Pose(hip: Offset(43.4, 59.3), torso: -48.0, head: 0, hand: Offset(76, 64), hand2: Offset(76, 64), foot: Offset(14, 92.0), foot2: Offset(14, 92.0)),
      Pose(hip: Offset(51.7, 69.4), torso: -31.0, head: 0, hand: Offset(76, 64), hand2: Offset(76, 64), foot: Offset(14, 92.0), foot2: Offset(14, 92.0)),
    ],
  ),
  'pushup': Demo(
    arm: 1,
    leg: -1,
    props: [],
    frames: [
      Pose(hip: Offset(48.2, 74.2), torso: -23.9, head: 0, hand: Offset(70, 92.0), hand2: Offset(70, 92.0), foot: Offset(8, 92.0), foot2: Offset(8, 92.0)),
      Pose(hip: Offset(51.4, 84.7), torso: -9.6, head: 0, hand: Offset(70, 92.0), hand2: Offset(70, 92.0), foot: Offset(8, 92.0), foot2: Offset(8, 92.0)),
    ],
  ),
  'elevated_pushup': Demo(
    arm: 1,
    leg: -1,
    props: [Prop.box(Rect.fromLTRB(0, 70, 22, 92.0))],
    frames: [
      Pose(hip: Offset(55.8, 66.3), torso: -4.8, head: 0, hand: Offset(76, 92.0), hand2: Offset(76, 92.0), foot: Offset(12, 70), foot2: Offset(12, 70)),
      Pose(hip: Offset(55.4, 77.1), torso: 9.3, head: 0, hand: Offset(76, 92.0), hand2: Offset(76, 92.0), foot: Offset(12, 70), foot2: Offset(12, 70)),
    ],
  ),
  'pike_pushup': Demo(
    arm: -1,
    leg: -1,
    props: [],
    frames: [
      Pose(hip: Offset(36.7, 49.9), torso: 50.0, head: 0, hand: Offset(72, 92.0), hand2: Offset(72, 92.0), foot: Offset(24, 92.0), foot2: Offset(24, 92.0)),
      Pose(hip: Offset(41, 53), torso: 60, head: 0, hand: Offset(72, 92.0), hand2: Offset(72, 92.0), foot: Offset(24, 92.0), foot2: Offset(24, 92.0)),
    ],
  ),
  'pillar_dip': Demo(
    arm: 1,
    leg: -1,
    props: [Prop.box(Rect.fromLTRB(52, 62, 68, 92.0))],
    frames: [
      Pose(hip: Offset(52.7, 58.8), torso: -76, head: 0, hand: Offset(60, 62), hand2: Offset(60, 62), foot: Offset(34, 76), foot2: Offset(36, 77)),
      Pose(hip: Offset(50.4, 71.8), torso: -66, head: 0, hand: Offset(60, 62), hand2: Offset(60, 62), foot: Offset(32, 86), foot2: Offset(34, 87)),
    ],
  ),
  'support_hold': Demo(
    arm: 1,
    leg: -1,
    props: [Prop.box(Rect.fromLTRB(52, 62, 68, 92.0))],
    frames: [
      Pose(hip: Offset(52.7, 58.8), torso: -76, head: 0, hand: Offset(60, 62), hand2: Offset(60, 62), foot: Offset(34, 76), foot2: Offset(36, 77)),
      Pose(hip: Offset(52.7, 59.6), torso: -75, head: 0, hand: Offset(60, 62), hand2: Offset(60, 62), foot: Offset(34, 77), foot2: Offset(36, 78)),
    ],
  ),
  'towel_row': Demo(
    arm: 1,
    leg: -1,
    props: [Prop.box(Rect.fromLTRB(84, 46, 98, 92.0)), Prop.towel(Offset(85, 62))],
    frames: [
      Pose(hip: Offset(46.9, 57.3), torso: -128.0, head: 0, hand: Offset(56.8, 48.9), hand2: Offset(56.8, 48.9), foot: Offset(74, 92.0), foot2: Offset(74, 92.0)),
      Pose(hip: Offset(60.4, 50.2), torso: -108.0, head: 0, hand: Offset(60.4, 33.0), hand2: Offset(60.4, 33.0), foot: Offset(74, 92.0), foot2: Offset(74, 92.0)),
    ],
  ),
  'towel_curl': Demo(
    arm: 1,
    leg: -1,
    props: [Prop.box(Rect.fromLTRB(84, 46, 98, 92.0)), Prop.towel(Offset(85, 62))],
    frames: [
      Pose(hip: Offset(48.1, 56.4), torso: -126.0, head: 0, hand: Offset(58.3, 48.4), hand2: Offset(58.3, 48.4), foot: Offset(74, 92.0), foot2: Offset(74, 92.0)),
      Pose(hip: Offset(56.1, 51.8), torso: -114.0, head: 0, hand: Offset(47.2, 19.2), hand2: Offset(47.2, 19.2), foot: Offset(74, 92.0), foot2: Offset(74, 92.0)),
    ],
  ),
  'table_row': Demo(
    arm: 1,
    leg: -1,
    props: [Prop.table(Rect.fromLTRB(14, 56, 64, 60))],
    frames: [
      Pose(hip: Offset(47.8, 88.2), torso: -5.0, head: 0, hand: Offset(63, 60), hand2: Offset(63, 60), foot: Offset(4, 92.0), foot2: Offset(4, 92.0)),
      Pose(hip: Offset(44.2, 74.1), torso: -24.0, head: 0, hand: Offset(63, 60), hand2: Offset(63, 60), foot: Offset(4, 92.0), foot2: Offset(4, 92.0)),
    ],
  ),
  'squat': Demo(
    arm: -1,
    leg: -1,
    props: [],
    frames: [
      Pose(hip: Offset(50, 48.6), torso: -90, head: 0, hand: Offset(78.5, 26.6), hand2: Offset(78.5, 26.6), foot: Offset(52, 92.0), foot2: Offset(52, 92.0)),
      Pose(hip: Offset(36, 72), torso: -52, head: 0, hand: Offset(80.5, 51.5), hand2: Offset(80.5, 51.5), foot: Offset(54, 92.0), foot2: Offset(54, 92.0)),
    ],
  ),
  'reverse_lunge': Demo(
    arm: 1,
    leg: -1,
    props: [],
    frames: [
      Pose(hip: Offset(50, 48.6), torso: -90, head: 0, hand: Offset(52.0, 51.1), hand2: Offset(52.0, 51.1), foot: Offset(52, 92.0), foot2: Offset(49, 92.0)),
      Pose(hip: Offset(44, 69), torso: -88, head: 0, hand: Offset(46.9, 71.5), hand2: Offset(46.9, 71.5), foot: Offset(64, 92.0), foot2: Offset(20, 92.0)),
    ],
  ),
  'bulgarian_split_squat': Demo(
    arm: 1,
    leg: -1,
    props: [Prop.box(Rect.fromLTRB(2, 70, 22, 92.0))],
    frames: [
      Pose(hip: Offset(55, 50), torso: -88, head: 0, hand: Offset(57.9, 52.5), hand2: Offset(57.9, 52.5), foot: Offset(64, 92.0), foot2: Offset(13, 70)),
      Pose(hip: Offset(46, 69), torso: -80, head: 0, hand: Offset(52.5, 71.9), hand2: Offset(52.5, 71.9), foot: Offset(64, 92.0), foot2: Offset(13, 70)),
    ],
  ),
  'plank': Demo(
    arm: 1,
    leg: -1,
    props: [],
    frames: [
      Pose(hip: Offset(48.9, 82.2), torso: -12.8, head: 0, hand: Offset(86, 92.0), hand2: Offset(86, 92.0), foot: Offset(6, 92.0), foot2: Offset(6, 92.0)),
      Pose(hip: Offset(48.9, 81.2), torso: -13.5, head: 0, hand: Offset(86, 92.0), hand2: Offset(86, 92.0), foot: Offset(6, 92.0), foot2: Offset(6, 92.0)),
    ],
  ),
  'leg_raise': Demo(
    arm: -1,
    leg: 1,
    props: [],
    frames: [
      Pose(hip: Offset(52, 88), torso: 180, head: 0, hand: Offset(58, 90), hand2: Offset(58, 90), foot: Offset(96, 88), foot2: Offset(96, 88)),
      Pose(hip: Offset(52, 88), torso: 180, head: 0, hand: Offset(58, 90), hand2: Offset(58, 90), foot: Offset(86, 60), foot2: Offset(86, 60)),
      Pose(hip: Offset(52, 88), torso: 180, head: 0, hand: Offset(58, 90), hand2: Offset(58, 90), foot: Offset(57, 44), foot2: Offset(57, 44)),
    ],
  ),
};
