import 'package:flutter/material.dart';

import '../domain/fitness.dart';
import '../l10n/strings.dart';

class MuscleMap extends StatelessWidget {
  const MuscleMap({super.key, required this.exercise});
  final Exercise exercise;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s('muscleMap'), style: Theme.of(context).textTheme.titleMedium),
        Semantics(
          image: true,
          label:
              '${s('primary')}: ${exercise.primary.map(s.muscle).join(', ')}. ${s('secondary')}: ${exercise.secondary.map(s.muscle).join(', ')}',
          child: SizedBox(
            height: 260,
            width: double.infinity,
            child: CustomPaint(
              painter: _Muscles(exercise, Theme.of(context).colorScheme),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [Text(s('front')), Text(s('back'))],
        ),
        const SizedBox(height: 12),
        Text(
          '${s('primary')} ●',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Wrap(
          spacing: 6,
          children: [
            for (final m in exercise.primary)
              Chip(
                avatar: const Icon(
                  Icons.circle,
                  size: 12,
                  color: Color(0xFFB34C33),
                ),
                label: Text(s.muscle(m)),
              ),
          ],
        ),
        Text('${s('secondary')} ◇'),
        Wrap(
          spacing: 6,
          children: [
            for (final m in exercise.secondary)
              Chip(
                avatar: const Icon(
                  Icons.diamond_outlined,
                  size: 12,
                  color: Color(0xFF786229),
                ),
                label: Text(s.muscle(m)),
              ),
          ],
        ),
      ],
    );
  }
}

class _Muscles extends CustomPainter {
  const _Muscles(this.e, this.scheme);
  final Exercise e;
  final ColorScheme scheme;
  @override
  void paint(Canvas c, Size size) {
    final z = (size.width / 400).clamp(0.0, 1.0);
    c.save();
    c.translate((size.width - 400 * z) / 2, 0);
    c.scale(z, size.height / 260);
    for (final back in [false, true]) {
      c.save();
      c.translate(back ? 200 : 0, 0);
      final body = Path()
        ..moveTo(88, 44)
        ..lineTo(71, 54)
        ..lineTo(56, 97)
        ..lineTo(40, 126)
        ..lineTo(49, 133)
        ..lineTo(69, 105)
        ..lineTo(76, 86)
        ..lineTo(77, 132)
        ..lineTo(72, 180)
        ..lineTo(68, 235)
        ..lineTo(84, 235)
        ..lineTo(97, 169)
        ..lineTo(104, 235)
        ..lineTo(121, 235)
        ..lineTo(119, 179)
        ..lineTo(114, 132)
        ..lineTo(115, 86)
        ..lineTo(126, 107)
        ..lineTo(145, 133)
        ..lineTo(155, 126)
        ..lineTo(138, 96)
        ..lineTo(126, 54)
        ..lineTo(107, 44)
        ..close();
      c.drawPath(body, Paint()..color = scheme.surfaceContainerHighest);
      c.drawPath(
        body,
        Paint()
          ..color = scheme.outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      c.drawOval(
        const Rect.fromLTWH(82, 8, 31, 34),
        Paint()..color = scheme.surfaceContainerHighest,
      );
      void zone(Muscle m, Rect r) {
        final primary = e.primary.contains(m),
            secondary = e.secondary.contains(m);
        c.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(5)),
          Paint()
            ..color = primary
                ? const Color(0xFFB34C33)
                : secondary
                ? const Color(0xFFE3BF68)
                : scheme.outlineVariant.withValues(alpha: .35),
        );
        if (primary || secondary) {
          c.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(5)),
            Paint()
              ..color = scheme.onSurface
              ..style = PaintingStyle.stroke
              ..strokeWidth = primary ? 1.6 : .7,
          );
        }
      }

      if (!back) {
        zone(Muscle.chest, const Rect.fromLTWH(80, 57, 17, 27));
        zone(Muscle.chest, const Rect.fromLTWH(99, 57, 17, 27));
        zone(Muscle.frontDelts, const Rect.fromLTWH(68, 54, 10, 23));
        zone(Muscle.frontDelts, const Rect.fromLTWH(119, 54, 10, 23));
        zone(Muscle.biceps, const Rect.fromLTWH(60, 80, 11, 24));
        zone(Muscle.biceps, const Rect.fromLTWH(127, 80, 11, 24));
        zone(Muscle.abs, const Rect.fromLTWH(88, 87, 17, 40));
        zone(Muscle.obliques, const Rect.fromLTWH(78, 90, 8, 32));
        zone(Muscle.obliques, const Rect.fromLTWH(107, 90, 8, 32));
        zone(Muscle.quads, const Rect.fromLTWH(76, 140, 15, 48));
        zone(Muscle.quads, const Rect.fromLTWH(106, 140, 12, 48));
        zone(Muscle.adductors, const Rect.fromLTWH(92, 140, 7, 25));
        zone(Muscle.adductors, const Rect.fromLTWH(99, 140, 6, 25));
        zone(Muscle.forearms, const Rect.fromLTWH(47, 108, 10, 19));
        zone(Muscle.forearms, const Rect.fromLTWH(139, 108, 10, 19));
      } else {
        zone(Muscle.traps, const Rect.fromLTWH(86, 49, 23, 16));
        zone(Muscle.upperBack, const Rect.fromLTWH(85, 67, 26, 22));
        zone(Muscle.rearDelts, const Rect.fromLTWH(69, 55, 12, 22));
        zone(Muscle.rearDelts, const Rect.fromLTWH(117, 55, 12, 22));
        zone(Muscle.lats, const Rect.fromLTWH(78, 84, 12, 28));
        zone(Muscle.lats, const Rect.fromLTWH(106, 84, 12, 28));
        zone(Muscle.lowerBack, const Rect.fromLTWH(91, 96, 13, 30));
        zone(Muscle.triceps, const Rect.fromLTWH(61, 80, 11, 24));
        zone(Muscle.triceps, const Rect.fromLTWH(127, 80, 11, 24));
        zone(Muscle.glutes, const Rect.fromLTWH(76, 129, 20, 22));
        zone(Muscle.glutes, const Rect.fromLTWH(99, 129, 20, 22));
        zone(Muscle.hamstrings, const Rect.fromLTWH(76, 155, 15, 35));
        zone(Muscle.hamstrings, const Rect.fromLTWH(105, 155, 14, 35));
      }
      zone(Muscle.sideDelts, const Rect.fromLTWH(64, 61, 5, 17));
      zone(Muscle.sideDelts, const Rect.fromLTWH(130, 61, 5, 17));
      zone(Muscle.abductors, const Rect.fromLTWH(71, 130, 5, 22));
      zone(Muscle.abductors, const Rect.fromLTWH(119, 130, 5, 22));
      zone(Muscle.calves, const Rect.fromLTWH(73, 194, 12, 30));
      zone(Muscle.calves, const Rect.fromLTWH(108, 194, 12, 30));
      c.restore();
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_Muscles old) => old.e != e || old.scheme != scheme;
}
