import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/domain/fitness.dart';
import 'package:reallife_rpg/src/ui/companion_portrait.dart';
import 'package:reallife_rpg/src/ui/companion_stage.dart';

const moods = ['happy', 'neutral', 'sad'];
Future<ui.Image> render(
  ui.Image atlas,
  String character,
  String mood, {
  Motion motion = Motion.idle,
  double phase = 0,
  Offset look = Offset.zero,
}) async {
  final recorder = ui.PictureRecorder();
  CompanionPainter(
    character: character,
    mood: mood,
    motion: motion,
    equipment: motion == Motion.reverseFly
        ? Equipment.machine
        : Equipment.bodyweight,
    phase: phase,
    atlas: atlas,
    look: look,
  ).paint(Canvas(recorder), const Size(400, 360));
  final picture = recorder.endRecording();
  final result = await picture.toImage(400, 360);
  picture.dispose();
  return result;
}

Future<Uint8List> rgba(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer
        .asUint8List();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ui.Image atlas;
  late Uint8List pixels;
  setUpAll(() async {
    atlas = await loadMoodAtlas();
    pixels = await rgba(atlas);
  });
  tearDownAll(() => atlas.dispose());
  for (final character in companionIds) {
    test(
      '$character expression crops contain their actual chin and eyes, not the next row',
      () {
        for (final mood in moods) {
          final frame = portraitFor(character, mood);
          expect(
            (Offset.zero &
                    Size(atlas.width.toDouble(), atlas.height.toDouble()))
                .contains(frame.source.topLeft),
            true,
          );
          final x = frame.chin.dx.toInt(), y = frame.chin.dy.toInt();
          // This checks pixels in the real asset, not merely repeated metadata.
          for (var dx = -4; dx <= 4; dx++) {
            expect(
              pixels[((y * atlas.width + x + dx) * 4) + 3],
              greaterThan(220),
              reason: '$character/$mood neck attaches to opaque chin',
            );
          }
          for (final eye in frame.eyes) {
            expect(
              frame.source.contains(eye.topLeft) &&
                  frame.source.contains(eye.bottomRight),
              true,
            );
            var dark = 0;
            for (var yy = eye.top.toInt(); yy < eye.bottom.toInt(); yy++) {
              for (var xx = eye.left.toInt(); xx < eye.right.toInt(); xx++) {
                final i = (yy * atlas.width + xx) * 4;
                if (pixels[i + 3] > 128 &&
                    math.max(
                          pixels[i],
                          math.max(pixels[i + 1], pixels[i + 2]),
                        ) <
                        100) {
                  dark++;
                }
              }
            }
            expect(
              dark,
              greaterThan(250),
              reason: 'Eye tracking must cover the actual eye, not wool or empty padding',
            );
          }
          final dest = frame.fittedToSocket();
          expect(dest.top, greaterThanOrEqualTo(0));
          expect(
            dest.width / frame.source.width,
            closeTo(dest.height / frame.source.height, .00001),
            reason: 'Portrait proportions are preserved',
          );
        }
      },
    );
    test(
      '$character keeps an unbroken chin/neck join across expressions and pointer directions',
      () async {
        for (final mood in moods) {
          for (final look in [
            Offset.zero,
            const Offset(-1, -1),
            const Offset(1, 1),
          ]) {
            final image = await render(atlas, character, mood, look: look);
            final bytes = await rgba(image);
            // World x shifts with the body. At the pinned chin the atlas and short
            // neck must form one connected foreground, without pink stage gaps.
            final x = 200 + (look.dx * 3).round();
            for (var y = 168; y <= 194; y++) {
              final i = (y * 400 + x) * 4;
              final background =
                  bytes[i] == 255 && bytes[i + 1] == 240 && bytes[i + 2] == 246;
              expect(
                background,
                false,
                reason: 'Gap at $character/$mood look=$look y=$y',
              );
            }
            final frame = portraitFor(character, mood);
            for (final eye in frame.eyes) {
              final region = frame
                  .mapSourceRect(eye, frame.fittedToSocket())
                  .shift(Offset(look.dx * 3, 0));
              var dark = 0;
              for (
                var yy = region.top.toInt();
                yy < region.bottom.toInt();
                yy++
              ) {
                for (
                  var xx = region.left.toInt();
                  xx < region.right.toInt();
                  xx++
                ) {
                  final i = (yy * 400 + xx) * 4;
                  if (math.max(bytes[i], math.max(bytes[i + 1], bytes[i + 2])) <
                      100) {
                    dark++;
                  }
                }
              }
              expect(
                dark,
                greaterThan(35),
                reason: 'Actual painter must place the eyes with the same fitted head, not the old grid crop',
              );
            }
            image.dispose();
          }
        }
      },
    );
    test(
      '$character reverse pec deck visibly moves while the head remains attached',
      () async {
        final first = await render(
          atlas,
          character,
          'neutral',
          motion: Motion.reverseFly,
          phase: 0,
        );
        final second = await render(
          atlas,
          character,
          'neutral',
          motion: Motion.reverseFly,
          phase: .5,
        );
        final a = await rgba(first), b = await rgba(second);
        var differences = 0;
        for (var y = 188; y < 260; y++) {
          for (var x = 85; x < 315; x++) {
            final i = (y * 400 + x) * 4;
            if (a[i] != b[i] || a[i + 1] != b[i + 1] || a[i + 2] != b[i + 2]) {
              differences++;
            }
          }
        }
        expect(differences, greaterThan(1000));
        // Both phases keep an opaque neck at its fixed body join.
        for (final bytes in [a, b]) {
          final i = (184 * 400 + 200) * 4;
          expect(bytes.sublist(i, i + 3), isNot([255, 240, 246]));
        }
        first.dispose();
        second.dispose();
      },
    );
  }
  test('atlas expressions render as isolated faces without neighbour fragments', () async {
    for (final character in companionIds) {
      for (final mood in moods) {
        final frame = portraitFor(character, mood);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final source = frame.source;
        canvas.drawImageRect(
          atlas,
          source,
          Rect.fromLTWH(0, 0, source.width, source.height),
          Paint(),
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(
          source.width.toInt(),
          source.height.toInt(),
        );
        final bytes = await rgba(image);
        picture.dispose();
        // The two-row cut used to contain an extra disconnected tuft/ear. Every
        // substantial opaque piece must connect to the centre face component.
        final w = image.width, h = image.height, seen = Uint8List(w * h);
        final areas = <int>[];
        for (var y = 0; y < h; y++) {
          for (var x = 0; x < w; x++) {
            final start = y * w + x;
            if (seen[start] != 0 || bytes[start * 4 + 3] < 128) continue;
            var count = 0;
            final stack = <int>[start];
            seen[start] = 1;
            while (stack.isNotEmpty) {
              final p = stack.removeLast();
              count++;
              final xx = p % w, yy = p ~/ w;
              for (final n in [
                if (xx > 0) p - 1,
                if (xx < w - 1) p + 1,
                if (yy > 0) p - w,
                if (yy < h - 1) p + w,
              ]) {
                if (seen[n] == 0 && bytes[n * 4 + 3] >= 128) {
                  seen[n] = 1;
                  stack.add(n);
                }
              }
            }
            if (count > 100) areas.add(count);
          }
        }
        expect(
          areas.length,
          1,
          reason: '$character/$mood includes a neighbouring character',
        );
        image.dispose();
      }
    }
  });
  test('capture actual painter sheets when explicitly requested', () async {
    if (Platform.environment['RPG_CAPTURE_PORTRAITS'] != '1') return;
    final font = FontLoader('PortraitPreview')
      ..addFont(rootBundle.load('assets/fonts/OpenDyslexic-Regular.otf'));
    await font.load();
    for (final scene in [
      ('idle', Motion.idle, 0.0),
      ('read', Motion.read, 0.0),
      ('reverse-closed', Motion.reverseFly, 0.0),
      ('reverse-open', Motion.reverseFly, .5),
    ]) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(const Color(0xFFFFFAFD), BlendMode.src);
      for (var row = 0; row < moods.length; row++) {
        for (var col = 0; col < companionIds.length; col++) {
          canvas.save();
          canvas.translate(col * 400, row * 400);
          CompanionPainter(
            character: companionIds[col],
            mood: moods[row],
            motion: scene.$2,
            equipment: scene.$2 == Motion.reverseFly
                ? Equipment.machine
                : Equipment.bodyweight,
            phase: scene.$3,
            atlas: atlas,
          ).paint(canvas, const Size(400, 360));
          final label = TextPainter(
            text: TextSpan(
              text: '${companionIds[col]} · ${moods[row]}',
              style: const TextStyle(
                color: Color(0xFF553146),
                fontSize: 16,
                fontFamily: 'PortraitPreview',
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          label.paint(canvas, const Offset(110, 365));
          canvas.restore();
        }
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(1600, 1200);
      picture.dispose();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('docs/screenshots/companions-${scene.$1}.png');
      file.parent.createSync(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    }
  });
}
