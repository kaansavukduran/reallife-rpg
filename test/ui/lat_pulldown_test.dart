import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/settings.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/domain/fitness.dart';
import 'package:reallife_rpg/src/domain/codec.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';
import 'package:reallife_rpg/src/ui/app.dart';
import 'package:reallife_rpg/src/ui/companion_sprites.dart';
import 'package:reallife_rpg/src/ui/companion_stage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sheets = <String, CompanionSprites>{};
  setUpAll(() async {
    for (final id in companionIds) {
      sheets[id] = await loadCompanionSprites(
        id,
        includeLateralMachine: true,
        includeLateralDumbbell: true,
        includeLatPulldown: true,
      );
    }
  });
  CompanionPainter painter(
    String id,
    double phase, {
    String exercise = 'lat_pulldown',
    Equipment equipment = Equipment.machine,
  }) => CompanionPainter(
    character: id,
    motion: Motion.pulldown,
    equipment: equipment,
    exerciseId: exercise,
    phase: phase,
    sprites: sheets[id],
  );

  for (final id in companionIds) {
    test(
      '$id has eight dedicated, unclipped connected-overhead-lat-pulldown drawings with stable ground',
      () async {
        final sprites = sheets[id]!;
        final atlas = sprites.latPulldown!;
        final bytes = (await atlas.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final sources = <Rect>{};
        final ground = <double>[];
        final handles = <Offset>[];
        final footGround = <double>[];
        final machineGround = <double>[];
        final footCenters = <double>[];

        final poses = <List<int>>[];
        for (var i = 0; i < 8; i++) {
          final f = painter(id, i / 8).frame!;
          expect(f.image, same(atlas));
          expect(f.clip, 'lat_pulldown');
          expect(f.count, 8);
          expect(f.index, i);
          sources.add(f.source);
          final cellTop = (i ~/ 4) * atlas.height / 2;
          expect(f.source.top, greaterThanOrEqualTo(cellTop));
          expect(
            f.source.bottom,
            lessThanOrEqualTo(cellTop + atlas.height / 2),
          );
          expect(
            f.source.left,
            greaterThanOrEqualTo((i % 4) * atlas.width / 4),
          );
          expect(
            f.source.right,
            lessThanOrEqualTo((i % 4 + 1) * atlas.width / 4),
          );
          var last = 0, opaque = 0, clear = 0;
          var left = atlas.width, right = 0, top = atlas.height;
          var handleCount = 0;
          var footLast = 0, machineLast = 0;
          final barRows = <int, int>{};
          var handleX = 0.0, handleY = 0.0;
          var barLeft = atlas.width, barRight = 0;

          final pixels = <int>[];
          for (var y = f.source.top.ceil(); y < f.source.bottom.floor(); y++) {
            pixels.addAll(
              bytes.sublist(
                (y * atlas.width + f.source.left.ceil()) * 4,
                (y * atlas.width + f.source.right.floor()) * 4,
              ),
            );
            for (
              var x = f.source.left.ceil();
              x < f.source.right.floor();
              x++
            ) {
              final offset = (y * atlas.width + x) * 4;
              final a = bytes[offset + 3];
              if (a == 0) clear++;
              if (a > 200) {
                opaque++;
                last = y;
                if (x < left) left = x;
                if (x > right) right = x;
                if (y < top) top = y;
                // Track the green connected lat bar. Machine, seat, cable
                // and thigh pads are gray and cannot mask wrong-direction motion.
                final r = bytes[offset],
                    g = bytes[offset + 1],
                    b = bytes[offset + 2];
                if (y > f.source.top + f.source.height * .75 &&
                    x > f.source.left + f.source.width * .75 &&
                    (r - g).abs() < 25 &&
                    (r - b).abs() < 25 &&
                    (g - b).abs() < 25) {
                  machineLast = y;
                }
                // Character-colored feet are measured separately from the gray
                // fixed machine base, which must not hide body drift.
                if (y > f.source.top + f.source.height * .75 &&
                    x > f.source.left + f.source.width * .20 &&
                    x < f.source.left + f.source.width * .68 &&
                    r > g + 8 &&
                    r > b + 5) {
                  footLast = y;
                }
                if (y > f.source.top + f.source.height * .1 &&
                    y < f.source.top + f.source.height * .75 &&
                    g > r + 12 &&
                    g > b + 8 &&
                    g > 90) {
                  handleCount++;
                  if (x < barLeft) barLeft = x;
                  if (x > barRight) barRight = x;
                  handleX += x - f.source.left;
                  handleY += y - f.source.top;
                  if (x > f.source.left + f.source.width * .35 &&
                      x < f.source.left + f.source.width * .55) {
                    barRows[y] = (barRows[y] ?? 0) + 1;
                  }
                }
              }
            }
          }
          expect(
            left - f.source.left,
            greaterThan(5),
            reason: 'No neighboring cell or clipped hand',
          );
          expect(f.source.right - right, greaterThan(5));
          expect(top - f.source.top, greaterThan(5));
          expect(f.source.bottom - last, greaterThan(5));
          expect(
            opaque,
            greaterThan(7000),
            reason: 'Complete seated character, connected bar and high-pulley machine, not a placeholder',
          );
          expect(clear, greaterThan(10000), reason: 'Actual alpha background');
          ground.add(last - f.source.top);
          expect(
            handleCount,
            greaterThan(200),
            reason: 'Visible green lat bar',
          );
          handles.add(Offset(handleX / handleCount, handleY / handleCount));
          expect(barRight - barLeft, greaterThan(f.source.width * .35));
          expect(barRows, isNotEmpty);
          expect(
            barRows.values.reduce((a, b) => a > b ? a : b) /
                (f.source.width * .20),
            greaterThan(.75),
            reason: 'A connected green bar crosses the center, not two handles or a rope',
          );
          expect(footLast, greaterThan(f.source.top + f.source.height * .75));
          footGround.add(footLast - f.source.top);
          expect(
            machineLast,
            greaterThan(f.source.top + f.source.height * .75),
          );
          machineGround.add(machineLast - f.source.top);
          // Check planted-foot x as well as ground y; this catches horizontal
          // atlas drift even though the destination rectangle stays fixed.
          var footX = 0.0, footCount = 0;
          for (var y = footLast - 7; y <= footLast; y++) {
            for (
              var x = f.source.left.ceil();
              x < f.source.right.floor();
              x++
            ) {
              final o = (y * atlas.width + x) * 4;
              if (x > f.source.left + f.source.width * .20 &&
                  x < f.source.left + f.source.width * .68 &&
                  bytes[o + 3] > 200 &&
                  bytes[o] > bytes[o + 1] + 8 &&
                  bytes[o] > bytes[o + 2] + 5) {
                footX += x - f.source.left;
                footCount++;
              }
            }
          }
          expect(footCount, greaterThan(50));
          footCenters.add(footX / footCount);
          // Registration trims only empty margins, never any opaque anatomy.
          for (
            var y = cellTop.ceil();
            y < (cellTop + atlas.height / 2).floor();
            y++
          ) {
            for (
              var x = ((i % 4) * atlas.width / 4).ceil();
              x < ((i % 4 + 1) * atlas.width / 4).floor();
              x++
            ) {
              if (bytes[(y * atlas.width + x) * 4 + 3] > 200) {
                expect(
                  f.source.contains(Offset(x.toDouble(), y.toDouble())),
                  isTrue,
                );
              }
            }
          }
          poses.add(pixels);
        }
        expect(sources.length, 8);
        expect(
          handles[4].dy - handles[0].dy,
          greaterThan(70),
          reason: 'Bar pulls DOWN from overhead toward upper chest, not upward pressing',
        );
        expect((handles[4].dx - handles[0].dx).abs(), lessThan(12));
        expect(
          footGround.reduce((a, b) => a > b ? a : b) -
              footGround.reduce((a, b) => a < b ? a : b),
          lessThanOrEqualTo(2),
        );
        expect(
          machineGround.reduce((a, b) => a > b ? a : b) -
              machineGround.reduce((a, b) => a < b ? a : b),
          lessThanOrEqualTo(2),
          reason: 'Gray machine base must stay fixed independently of the character feet',
        );
        expect(
          footCenters.reduce((a, b) => a > b ? a : b) -
              footCenters.reduce((a, b) => a < b ? a : b),
          lessThanOrEqualTo(5),
        );
        for (var i = 1; i < 8; i++) {
          expect(listEquals(poses[i - 1], poses[i]), isFalse);
        }
        expect(
          (ground.reduce((a, b) => a > b ? a : b) -
              ground.reduce((a, b) => a < b ? a : b)),
          lessThanOrEqualTo(2),
        );
        expect(
          painter(id, 0).frame!.source,
          isNot(painter(id, .5).frame!.source),
        );
        for (final variant in [
          painter(id, .5, exercise: 'shoulder_press'),
          painter(id, .5, exercise: 'custom:lat'),
          painter(id, .5, equipment: Equipment.cable),
          painter(id, .5, equipment: Equipment.dumbbell),
        ]) {
          expect(variant.frame!.clip, 'idle');
          expect(
            variant.frame!.source.top,
            .5,
            reason: 'Wrong equipment must never show the generic machine row',
          );
          expect(variant.frame!.image, isNot(same(atlas)));
        }
      },
    );
  }

  for (final config in [
    ('aion', 'tr', false),
    ('sheep', 'en', false),
    ('wolf', 'tr', true),
    ('owl', 'en', true),
  ]) {
    testWidgets(
      'eight frame controls, pause, reduced motion and persistence (${config.$1}, ${config.$2}, phone=${config.$3})',
      (t) async {
        t.view.physicalSize = config.$3
            ? const Size(390, 844)
            : const Size(1440, 1100);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final store = MemoryTaskStore()
          ..settings = AppSettings(
            languageCode: config.$2,
            uiScale: config.$3 ? 2 : 1,
            appearance: Appearance(
              font: config.$3 ? 'dyslexic' : 'system',
              reduceMotion: config.$3,
            ),
          );
        final c = TaskController(
          store: store,
          clock: () => DateTime(2026, 11, 9),
        );
        await c.load();
        c.updateLife(c.data.life.copyWith(companion: config.$1));
        await c.saved;
        await t.pumpWidget(
          RealLifeRPGApp(controller: c, initialPage: 'companions'),
        );
        await t.pumpAndSettle();
        Future<void> click(Finder f) async {
          for (var i = 0; i < 25 && f.evaluate().isEmpty; i++) {
            final vertical = find
                .byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                )
                .last;
            final visible = t
                .getRect(vertical)
                .intersect(Offset.zero & t.view.physicalSize);
            await t.dragFrom(visible.center, const Offset(0, -180));
            await t.pumpAndSettle();
          }
          await t.ensureVisible(f);
          await t.pumpAndSettle();
          final visible = t
              .getRect(f)
              .intersect(Offset.zero & t.view.physicalSize);
          expect(visible.isEmpty, isFalse);
          await t.tapAt(visible.center);
          await t.pumpAndSettle();
        }

        await click(
          find.text(
            config.$2 == 'tr' ? 'Lat pulldown · sırt çekiş' : 'Lat pulldown',
          ),
        );
        final slider = find.byKey(const Key('animation-phase'));
        expect(t.widget<Slider>(slider).divisions, 7);
        if (!config.$3) {
          await click(find.byKey(const Key('animation-play')));
          final before = t.widget<Slider>(slider).value;
          await t.pump(const Duration(seconds: 1));
          expect(t.widget<Slider>(slider).value, before);
        } else {
          expect(
            t
                .widget<IconButton>(find.byKey(const Key('animation-play')))
                .onPressed,
            isNull,
          );
        }
        await click(slider);
        await t.sendKeyEvent(LogicalKeyboardKey.end);
        await t.pumpAndSettle();
        expect(t.widget<Slider>(slider).value, 1);
        final stage = t.widget<CompanionStage>(
          find.byWidgetPredicate(
            (w) => w is CompanionStage && w.exerciseId == 'lat_pulldown',
          ),
        );
        expect(stage.character, config.$1);
        await t.sendKeyEvent(LogicalKeyboardKey.home);
        await t.pumpAndSettle();
        expect(t.widget<Slider>(slider).value, 0);
        final snapshot = encodeTaskData(c.data, savedAt: DateTime(2026, 11, 9));
        final reopened = TaskController(
          store: store,
          clock: () => DateTime(2026, 11, 9),
        );
        await reopened.load();
        expect(
          encodeTaskData(reopened.data, savedAt: DateTime(2026, 11, 9)),
          snapshot,
        );
        expect(c.profile.totalXp, 0);
        expect(c.data.tasks, isEmpty);
        expect(c.data.completions, isEmpty);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        reopened.dispose();
        c.dispose();
      },
    );
  }
  test(
    'lat pulldown family, equipment and missing atlas never borrow other clips',
    () {
      for (final id in companionIds) {
        final sprites = sheets[id]!;
        final missing = CompanionSprites(sprites.actions, sprites.pet);
        for (final entry in [
          (sprites, Motion.pulldown, Equipment.dumbbell, 'lat_pulldown'),
          (sprites, Motion.pulldown, Equipment.cable, 'lat_pulldown'),
          (sprites, Motion.pulldown, Equipment.machine, 'lateral_machine'),
          (sprites, Motion.pulldown, Equipment.machine, 'lateral_dumbbell'),
          (sprites, Motion.pulldown, Equipment.machine, 'custom:lat'),
          (sprites, Motion.overhead, Equipment.machine, 'lat_pulldown'),
          (sprites, Motion.read, Equipment.machine, 'lat_pulldown'),
          (sprites, Motion.reverseFly, Equipment.machine, 'lat_pulldown'),
          (missing, Motion.pulldown, Equipment.machine, 'lat_pulldown'),
        ]) {
          final frame = companionFrame(
            sprites: entry.$1,
            motion: entry.$2,
            equipment: entry.$3,
            exerciseId: entry.$4,
            phase: .5,
          );
          expect(frame.clip, 'idle');
          expect(
            frame.image,
            same(id == 'aion' ? sprites.pet : sprites.actions),
          );
          expect(frame.source.top, .5);
        }
        final reading = companionFrame(
          sprites: sprites,
          motion: Motion.read,
          equipment: Equipment.bodyweight,
          exerciseId: 'read',
          phase: 0,
        );
        expect(reading.clip, 'read');
        expect(reading.source.top, greaterThan(.5));
        expect(
          hasActivityFrames(Motion.pulldown, Equipment.machine, 'lat_pulldown'),
          isTrue,
        );
        expect(
          hasActivityFrames(Motion.pulldown, Equipment.barbell, 'lat_pulldown'),
          isFalse,
        );
        expect(
          hasActivityFrames(Motion.press, Equipment.machine, 'lat_pulldown'),
          isFalse,
        );
      }
    },
  );
  testWidgets('play resumes at the frame after the manually selected pose', (
    t,
  ) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CompanionStage(
            character: 'aion',
            motion: Motion.pulldown,
            equipment: Equipment.machine,
            exerciseId: 'lat_pulldown',
            controls: true,
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final slider = find.byKey(const Key('animation-phase'));
    await t.tap(slider);
    await t.pumpAndSettle();
    expect(t.widget<Slider>(slider).value, 4 / 7);
    await t.tap(find.byKey(const Key('animation-play')));
    await t.pump(const Duration(milliseconds: 220));
    expect(
      t.widget<Slider>(slider).value,
      5 / 8,
      reason: 'Play must continue from the selected fifth pose instead of returning to the old timer counter',
    );
    await t.pumpWidget(const SizedBox());
  });
  test(
    'capture actual lat pulldown renderer start/pulldown contact sheet',
    () async {
      if (Platform.environment['RPG_CAPTURE_LAT_PULLDOWN'] != '1') return;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawColor(const Color(0xff251c32), BlendMode.src);
      for (var row = 0; row < 2; row++) {
        for (var col = 0; col < 4; col++) {
          canvas.save();
          canvas.translate(col * 400.0, row * 360.0);
          painter(
            companionIds[col],
            row * .5,
          ).paint(canvas, const Size(400, 360));
          canvas.restore();
        }
      }
      final picture = recorder.endRecording();
      final im = await picture.toImage(1600, 720);
      picture.dispose();
      await File('docs/screenshots/lat-pulldown-frames.png').writeAsBytes(
        (await im.toByteData(format: ui.ImageByteFormat.png))!.buffer
            .asUint8List(),
      );
      im.dispose();
    },
  );
}
