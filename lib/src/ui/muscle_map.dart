import 'package:flutter/material.dart';

import '../domain/fitness.dart';
import '../l10n/strings.dart';

class MuscleRegion {
  const MuscleRegion(this.muscle, this.back, this.bounds);
  final Muscle muscle;
  final bool back;
  final Rect bounds;
  Rect get onMap => bounds.shift(Offset(back ? 200 : 0, 0));
}

const muscleRegions = <MuscleRegion>[
  MuscleRegion(Muscle.chest, false, Rect.fromLTWH(80, 57, 17, 27)),
  MuscleRegion(Muscle.chest, false, Rect.fromLTWH(99, 57, 17, 27)),
  MuscleRegion(Muscle.frontDelts, false, Rect.fromLTWH(68, 54, 10, 23)),
  MuscleRegion(Muscle.frontDelts, false, Rect.fromLTWH(119, 54, 10, 23)),
  MuscleRegion(Muscle.biceps, false, Rect.fromLTWH(60, 80, 11, 24)),
  MuscleRegion(Muscle.biceps, false, Rect.fromLTWH(127, 80, 11, 24)),
  MuscleRegion(Muscle.abs, false, Rect.fromLTWH(88, 87, 17, 40)),
  MuscleRegion(Muscle.obliques, false, Rect.fromLTWH(78, 90, 8, 32)),
  MuscleRegion(Muscle.obliques, false, Rect.fromLTWH(107, 90, 8, 32)),
  MuscleRegion(Muscle.quads, false, Rect.fromLTWH(76, 140, 15, 48)),
  MuscleRegion(Muscle.quads, false, Rect.fromLTWH(106, 140, 12, 48)),
  MuscleRegion(Muscle.adductors, false, Rect.fromLTWH(92, 140, 7, 25)),
  MuscleRegion(Muscle.adductors, false, Rect.fromLTWH(99, 140, 6, 25)),
  MuscleRegion(Muscle.forearms, false, Rect.fromLTWH(47, 108, 10, 19)),
  MuscleRegion(Muscle.forearms, false, Rect.fromLTWH(139, 108, 10, 19)),
  MuscleRegion(Muscle.traps, true, Rect.fromLTWH(86, 49, 23, 16)),
  MuscleRegion(Muscle.upperBack, true, Rect.fromLTWH(85, 67, 26, 22)),
  MuscleRegion(Muscle.rearDelts, true, Rect.fromLTWH(69, 55, 12, 22)),
  MuscleRegion(Muscle.rearDelts, true, Rect.fromLTWH(117, 55, 12, 22)),
  MuscleRegion(Muscle.lats, true, Rect.fromLTWH(78, 84, 12, 28)),
  MuscleRegion(Muscle.lats, true, Rect.fromLTWH(106, 84, 12, 28)),
  MuscleRegion(Muscle.lowerBack, true, Rect.fromLTWH(91, 96, 13, 30)),
  MuscleRegion(Muscle.triceps, true, Rect.fromLTWH(61, 80, 11, 24)),
  MuscleRegion(Muscle.triceps, true, Rect.fromLTWH(127, 80, 11, 24)),
  MuscleRegion(Muscle.glutes, true, Rect.fromLTWH(76, 129, 20, 22)),
  MuscleRegion(Muscle.glutes, true, Rect.fromLTWH(99, 129, 20, 22)),
  MuscleRegion(Muscle.hamstrings, true, Rect.fromLTWH(76, 155, 15, 35)),
  MuscleRegion(Muscle.hamstrings, true, Rect.fromLTWH(105, 155, 14, 35)),
  MuscleRegion(Muscle.sideDelts, false, Rect.fromLTWH(64, 61, 5, 17)),
  MuscleRegion(Muscle.sideDelts, false, Rect.fromLTWH(130, 61, 5, 17)),
  MuscleRegion(Muscle.abductors, false, Rect.fromLTWH(71, 130, 5, 22)),
  MuscleRegion(Muscle.abductors, false, Rect.fromLTWH(119, 130, 5, 22)),
  MuscleRegion(Muscle.calves, false, Rect.fromLTWH(73, 194, 12, 30)),
  MuscleRegion(Muscle.calves, false, Rect.fromLTWH(108, 194, 12, 30)),
  MuscleRegion(Muscle.sideDelts, true, Rect.fromLTWH(64, 61, 5, 17)),
  MuscleRegion(Muscle.sideDelts, true, Rect.fromLTWH(130, 61, 5, 17)),
  MuscleRegion(Muscle.abductors, true, Rect.fromLTWH(71, 130, 5, 22)),
  MuscleRegion(Muscle.abductors, true, Rect.fromLTWH(119, 130, 5, 22)),
  MuscleRegion(Muscle.calves, true, Rect.fromLTWH(73, 194, 12, 30)),
  MuscleRegion(Muscle.calves, true, Rect.fromLTWH(108, 194, 12, 30)),
];
Muscle? muscleAt(Offset local, Size size) {
  final z = (size.width / 400).clamp(0.0, 1.0);
  if (z == 0 || size.height == 0) return null;
  final point = Offset(
    (local.dx - (size.width - 400 * z) / 2) / z,
    local.dy * 260 / size.height,
  );
  final exact = muscleRegions.where((r) => r.onMap.contains(point)).toList();
  final near = exact.isNotEmpty
      ? exact
      : muscleRegions.where((r) => r.onMap.inflate(5).contains(point)).toList();
  if (near.isEmpty) return null;
  near.sort(
    (a, b) => (a.onMap.center - point).distanceSquared.compareTo(
      (b.onMap.center - point).distanceSquared,
    ),
  );
  return near.first.muscle;
}

class MuscleMap extends StatelessWidget {
  const MuscleMap({super.key, required this.exercise, this.onSelect});
  final Exercise exercise;
  final ValueChanged<Muscle>? onSelect;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s(onSelect == null ? 'muscleMap' : 'chooseMuscle'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Semantics(
          image: true,
          label:
              '${s('primary')}: ${exercise.primary.map(s.muscle).join(', ')}. ${s('secondary')}: ${exercise.secondary.map(s.muscle).join(', ')}',
          child: SizedBox(
            height: 260,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, box) => GestureDetector(
                key: onSelect == null ? null : const Key('muscle-selector'),
                behavior: HitTestBehavior.opaque,
                onTapUp: onSelect == null
                    ? null
                    : (event) {
                        final muscle = muscleAt(
                          event.localPosition,
                          box.biggest,
                        );
                        if (muscle != null) onSelect!(muscle);
                      },
                child: CustomPaint(
                  painter: _Muscles(exercise, Theme.of(context).colorScheme),
                ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [Text(s('front')), Text(s('back'))],
        ),
        const SizedBox(height: 12),
        if (onSelect == null) ...[
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
                ? scheme.primary
                : secondary
                ? scheme.tertiaryContainer
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

      for (final region in muscleRegions.where((r) => r.back == back)) {
        zone(region.muscle, region.bounds);
      }
      c.restore();
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_Muscles old) => old.e != e || old.scheme != scheme;
}
