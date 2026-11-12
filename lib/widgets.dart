import 'dart:math';

import 'package:material_ui/material_ui.dart';

import 'theme.dart';

/// Rounded surface block used for every section.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding, this.color});
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: color ?? cs.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(18),
          child: child,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.titleLarge),
            ),
            ?trailing,
          ],
        ),
      );
}

/// Concentric progress rings, outermost first. Values are 0..1.
class Rings extends StatelessWidget {
  const Rings({
    super.key,
    required this.values,
    required this.colors,
    this.size = 180,
    this.stroke = 14,
    this.gap = 5,
    this.child,
  });
  final List<double> values;
  final List<Color> colors;
  final double size;
  final double stroke;
  final double gap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, t, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingsPainter(
            values.map((v) => v * t).toList(),
            colors,
            stroke,
            gap,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.values, this.colors, this.stroke, this.gap);
  final List<double> values;
  final List<Color> colors;
  final double stroke;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = 0; i < values.length; i++) {
      final r = size.width / 2 - stroke / 2 - i * (stroke + gap);
      final rect = Rect.fromCircle(center: c, radius: r);
      final track = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = colors[i].withValues(alpha: 0.16);
      canvas.drawCircle(c, r, track);
      final v = values[i].clamp(0.0, 1.0);
      if (v > 0) {
        final arc = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = colors[i];
        canvas.drawArc(rect, -pi / 2, 2 * pi * v, false, arc);
      }
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => true;
}

/// Seven small bars with day initials. Optional goal line.
class WeekBars extends StatelessWidget {
  const WeekBars({
    super.key,
    required this.days,
    required this.values,
    required this.color,
    this.goal,
    this.height = 110,
  });
  final List<DateTime> days;
  final List<int> values;
  final Color color;
  final int? goal;
  final double height;

  static const _initials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final peak = max(values.fold(0, max), goal ?? 0);
    final top = peak == 0 ? 1.0 : peak * 1.1;
    return SizedBox(
      height: height + 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    values[i] == 0 ? '' : '${values[i]}',
                    style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: max(4, height * values[i] / top),
                    margin: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: BoxDecoration(
                      color: values[i] == 0
                          ? cs.surfaceContainerHighest
                          : (goal != null && values[i] > goal! * 1.15
                              ? color.withValues(alpha: 0.5)
                              : color),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _initials[days[i].weekday - 1],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          i == days.length - 1 ? FontWeight.w800 : FontWeight.w500,
                      color: i == days.length - 1
                          ? cs.onSurface
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class Stat extends StatelessWidget {
  const Stat(this.value, this.label, {super.key, this.color});
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: t.textTheme.headlineSmall?.copyWith(
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()])),
        Text(label,
            style: t.textTheme.bodySmall
                ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint(this.emoji, this.text, {super.key});
  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Panel(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(height: 8),
          Text(text,
              textAlign: TextAlign.center,
              style: t.textTheme.bodyMedium
                  ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Andy's face: a warm rounded badge used as the app mark.
class AndyMark extends StatelessWidget {
  const AndyMark({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AndyColors.fuel, AndyColors.brand],
          ),
          borderRadius: BorderRadius.circular(size * 0.32),
        ),
        child: Text(
          'A',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.56,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      );
}

/// Wraps bottom-sheet content so it clears the keyboard and safe area.
class SheetBody extends StatelessWidget {
  const SheetBody({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 4, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      );
}

Future<T?> showAndySheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => child,
    );

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

/// "Fri 14 Nov, 09:00"
String whenText(DateTime t) =>
    '${_weekdays[t.weekday - 1]} ${t.day} ${_months[t.month - 1]}, '
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String ago(DateTime t) {
  final d = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
      .difference(DateTime(t.year, t.month, t.day))
      .inDays;
  if (d == 0) return 'Today';
  if (d == 1) return 'Yesterday';
  return '$d days ago';
}
