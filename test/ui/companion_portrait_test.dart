import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/domain/fitness.dart';
import 'package:reallife_rpg/src/ui/companion_sprites.dart';
import 'package:reallife_rpg/src/ui/companion_stage.dart';

Future<ui.Image> render(
  CompanionSprites sprites,
  String id,
  Motion motion,
  double phase, {
  Offset look = Offset.zero,
}) async {
  final recorder = ui.PictureRecorder();
  CompanionPainter(
    character: id,
    motion: motion,
    equipment: motion == Motion.curl
        ? Equipment.dumbbell
        : motion == Motion.reverseFly
        ? Equipment.machine
        : Equipment.bodyweight,
    sprites: sprites,
    phase: phase,
    look: look,
  ).paint(Canvas(recorder), const Size(400, 360));
  final picture = recorder.endRecording();
  final image = await picture.toImage(400, 360);
  picture.dispose();
  return image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sheets = <String, CompanionSprites>{};
  setUpAll(() async {
    for (final id in companionIds) {
      sheets[id] = await loadCompanionSprites(id);
    }
  });
  for (final id in companionIds) {
    test(
      '$id uses complete transparent cartoon cells for all available activities',
      () async {
        final sprites = sheets[id]!;
        for (final motion in [
          Motion.idle,
          Motion.read,
          Motion.eat,
          Motion.curl,
          Motion.reverseFly,
        ]) {
          final a = companionFrame(sprites: sprites, motion: motion, phase: 0);
          final b = companionFrame(sprites: sprites, motion: motion, phase: .5);
          expect(a.source, isNot(b.source));
          for (final frame in [a, b]) {
            expect(frame.source.left, greaterThanOrEqualTo(0));
            expect(frame.source.bottom, lessThanOrEqualTo(frame.image.height));
            final bytes = (await frame.image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!.buffer.asUint8List();
            var body = 0, transparent = 0, total = 0;
            for (
              var y = frame.source.top.ceil();
              y < frame.source.bottom.floor();
              y++
            ) {
              for (
                var x = frame.source.left.ceil();
                x < frame.source.right.floor();
                x++
              ) {
                final alpha = bytes[(y * frame.image.width + x) * 4 + 3];
                total++;
                if (alpha == 0) transparent++;
                if (y > frame.source.top + frame.source.height * .55 &&
                    alpha > 180) {
                  body++;
                }
              }
            }
            expect(
              transparent / total,
              greaterThan(.025),
              reason: 'No opaque paper rectangle behind the sprite',
            );
            expect(
              body / total,
              greaterThan(.10),
              reason: 'The real source has a substantial lower body, not a portrait with stick limbs',
            );
          }
          final first = await render(sprites, id, motion, 0),
              second = await render(sprites, id, motion, .5);
          final p = (await first.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!.buffer.asUint8List();
          final q = (await second.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!.buffer.asUint8List();
          expect(
            listEquals(p, q),
            isFalse,
            reason: 'The renderer must display different actual drawings',
          );
          first.dispose();
          second.dispose();
        }
      },
    );
    test(
      '$id pointer directions select whole pre-drawn cells with one fixed destination',
      () async {
        final sprites = sheets[id]!;
        final left = companionFrame(
          sprites: sprites,
          motion: Motion.idle,
          phase: 0,
          look: const Offset(-1, 0),
        );
        final right = companionFrame(
          sprites: sprites,
          motion: Motion.idle,
          phase: 0,
          look: const Offset(1, 0),
        );
        expect(left.clip, 'look');
        expect(right.clip, 'look');
        expect(left.source, isNot(right.source));
        expect(left.source.size, right.source.size);
        final first = await render(
          sprites,
          id,
          Motion.idle,
          0,
          look: const Offset(-1, 0),
        );
        final second = await render(
          sprites,
          id,
          Motion.idle,
          0,
          look: const Offset(1, 0),
        );
        expect(
          listEquals(
            (await first.toByteData())!.buffer.asUint8List(),
            (await second.toByteData())!.buffer.asUint8List(),
          ),
          isFalse,
        );
        first.dispose();
        second.dispose();
        expect(
          hasActivityFrames(Motion.legPress),
          isFalse,
          reason: 'Never present a curl as a leg press demonstration',
        );
      },
    );
  }
  test('capture full-body activity contact sheet when requested', () async {
    if (Platform.environment['RPG_CAPTURE_SPRITES'] != '1') return;
    final motions = [
      Motion.idle,
      Motion.read,
      Motion.eat,
      Motion.curl,
      Motion.reverseFly,
    ];
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(const Color(0xFF251C32), BlendMode.src);
    for (var row = 0; row < motions.length; row++) {
      for (var col = 0; col < companionIds.length; col++) {
        canvas.save();
        canvas.translate(col * 400.0, row * 360.0);
        CompanionPainter(
          character: companionIds[col],
          motion: motions[row],
          equipment: Equipment.bodyweight,
          phase: .5,
          sprites: sheets[companionIds[col]],
        ).paint(canvas, const Size(400, 360));
        canvas.restore();
      }
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(1600, 1800);
    picture.dispose();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('docs/screenshots/full-body-activities.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
