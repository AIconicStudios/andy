import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'theme.dart';

// Body proportions in the 100 x 100 demo box. Must match tool/poses.py.
const _torso = 26.0, _upperArm = 15.0, _forearm = 14.0;
const _thigh = 22.0, _shin = 22.0;
const _headR = 5.8, _neck = 8.5;
const _floor = 92.0;

/// One key position of a demonstration. Joints between hip, shoulder,
/// hands and feet are worked out with two-bone inverse kinematics, so the
/// hands and feet stay planted while the body moves.
class Pose {
  const Pose({
    required this.hip,
    required this.torso,
    this.head = 0,
    required this.hand,
    required this.hand2,
    required this.foot,
    required this.foot2,
  });
  final Offset hip;

  /// Direction from hip to shoulder, degrees, y down (-90 is straight up).
  final double torso;

  /// Extra tilt of the head relative to the torso, degrees.
  final double head;
  final Offset hand, hand2, foot, foot2;

  static Pose lerp(Pose a, Pose b, double t) => Pose(
        hip: Offset.lerp(a.hip, b.hip, t)!,
        torso: _lerpAngle(a.torso, b.torso, t),
        head: a.head + (b.head - a.head) * t,
        hand: Offset.lerp(a.hand, b.hand, t)!,
        hand2: Offset.lerp(a.hand2, b.hand2, t)!,
        foot: Offset.lerp(a.foot, b.foot, t)!,
        foot2: Offset.lerp(a.foot2, b.foot2, t)!,
      );
}

double _lerpAngle(double a, double b, double t) {
  var d = (b - a) % 360;
  if (d > 180) d -= 360;
  if (d < -180) d += 360;
  return a + d * t;
}

enum PropKind { box, table, towel }

/// Furniture in a demo: a pillar, chair or bed (box), a table, or a towel
/// running from the near hand to [anchor].
class Prop {
  const Prop.box(Rect this.rect)
      : kind = PropKind.box,
        anchor = null;
  const Prop.table(Rect this.rect)
      : kind = PropKind.table,
        anchor = null;
  const Prop.towel(Offset this.anchor)
      : kind = PropKind.towel,
        rect = null;
  final PropKind kind;
  final Rect? rect;
  final Offset? anchor;
}

class Demo {
  const Demo({
    required this.frames,
    required this.arm,
    required this.leg,
    this.props = const [],
  });

  /// Played forwards then backwards, on a loop.
  final List<Pose> frames;

  /// Which way elbows and knees bend: 1 or -1.
  final int arm, leg;
  final List<Prop> props;

  /// The pose at [t] in 0..1 across one full rep (there and back).
  Pose at(double t) {
    if (frames.length == 1) return frames.first;
    // 0 -> 1 down the frames, then back up, with a short pause at each end.
    final phase = t < 0.5 ? t * 2 : (1 - t) * 2;
    final eased = Curves.easeInOut.transform(
        ((phase - 0.08) / 0.84).clamp(0.0, 1.0));
    final pos = eased * (frames.length - 1);
    final i = pos.floor().clamp(0, frames.length - 2);
    return Pose.lerp(frames[i], frames[i + 1], pos - i);
  }
}

(Offset, Offset) _ik(Offset root, Offset target, double a, double b, int side) {
  final delta = target - root;
  var d = delta.distance;
  if (d == 0) d = 0.001;
  final u = delta / d;
  final dc = d.clamp((a - b).abs() + 0.01, a + b - 0.01);
  final cosA = (a * a + dc * dc - b * b) / (2 * a * dc);
  final angle = math.acos(cosA.clamp(-1.0, 1.0)) * side;
  final joint = root +
      Offset(u.dx * math.cos(angle) - u.dy * math.sin(angle),
              u.dx * math.sin(angle) + u.dy * math.cos(angle)) *
          a;
  final rest = target - joint;
  final e = rest.distance == 0 ? 0.001 : rest.distance;
  return (joint, joint + rest / e * b);
}

Offset _dir(double degrees, double length) {
  final r = degrees * math.pi / 180;
  return Offset(math.cos(r), math.sin(r)) * length;
}

class _DemoPainter extends CustomPainter {
  _DemoPainter({
    required this.demo,
    required this.t,
    required this.body,
    required this.bodyFar,
    required this.background,
    required this.prop,
    required this.floor,
  });
  final Demo demo;
  final double t;
  final Color body, bodyFar, background, prop, floor;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 100;
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);

    final pose = demo.at(t);
    final shoulder = pose.hip + _dir(pose.torso, _torso);
    final head = shoulder + _dir(pose.torso + pose.head, _neck);
    final (elbow, hand) =
        _ik(shoulder, pose.hand, _upperArm, _forearm, demo.arm);
    final (elbow2, hand2) =
        _ik(shoulder, pose.hand2, _upperArm, _forearm, demo.arm);
    final (knee, foot) = _ik(pose.hip, pose.foot, _thigh, _shin, demo.leg);
    final (knee2, foot2) = _ik(pose.hip, pose.foot2, _thigh, _shin, demo.leg);

    canvas.drawLine(const Offset(-2, _floor), const Offset(102, _floor),
        Paint()
          ..color = floor
          ..strokeWidth = 1.2);

    final propPaint = Paint()..color = prop;
    for (final p in demo.props) {
      final r = p.rect;
      if (r == null) continue;
      if (p.kind == PropKind.box) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(1.5)), propPaint);
      } else if (p.kind == PropKind.table) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(1)), propPaint);
        for (final x in [r.left + 2, r.right - 5]) {
          canvas.drawRect(Rect.fromLTRB(x, r.bottom, x + 3, _floor), propPaint);
        }
      }
    }

    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const limb = 8.0, trunk = 11.0, gap = 2.4;

    void chain(List<Offset> pts, Color c, {bool outline = false}) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      final paint = stroke(c, limb)..strokeJoin = StrokeJoin.round;
      if (outline) {
        canvas.drawPath(
            path,
            stroke(background, limb + gap)..strokeJoin = StrokeJoin.round);
      }
      canvas.drawPath(path, paint);
    }

    // Far side first, then the body, then the near limbs with a thin gap
    // around them so they stay readable where they cross the body.
    chain([pose.hip, knee2, foot2], bodyFar);
    chain([shoulder, elbow2, hand2], bodyFar);
    canvas.drawLine(pose.hip, shoulder, stroke(body, trunk));
    chain([pose.hip, knee, foot], body, outline: true);
    for (final p in demo.props) {
      if (p.kind == PropKind.towel) {
        canvas.drawLine(hand, p.anchor!, stroke(AndyColors.fuel, 1.8));
      }
    }
    chain([shoulder, elbow, hand], body, outline: true);
    canvas.drawCircle(head, _headR + gap / 2, Paint()..color = background);
    canvas.drawCircle(head, _headR, Paint()..color = body);
  }

  @override
  bool shouldRepaint(_DemoPainter old) =>
      old.t != t || old.demo != demo || old.body != body;
}

/// A looping silhouette demonstration of one exercise.
class ExerciseDemo extends StatefulWidget {
  const ExerciseDemo({
    super.key,
    required this.demo,
    this.seconds = 2.6,
    this.background,
  });
  final Demo demo;

  /// Length of one rep, down and up.
  final double seconds;

  /// What the figure sits on, for the outline gaps. Defaults to the card
  /// colour.
  final Color? background;

  @override
  State<ExerciseDemo> createState() => _ExerciseDemoState();
}

class _ExerciseDemoState extends State<ExerciseDemo>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (widget.seconds * 1000).round()),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _DemoPainter(
            demo: widget.demo,
            t: _controller.value,
            body: AndyColors.brand,
            bodyFar: AndyColors.brand.withValues(alpha: dark ? 0.55 : 0.45),
            background: widget.background ?? cs.surfaceContainer,
            prop: dark ? const Color(0xFF5A4E44) : const Color(0xFFD9CCBC),
            floor: cs.outline.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
