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
        includeFrontRaise: true,
      );
    }
  });
  CompanionPainter painter(
    String id,
    double phase, {
    String exercise = 'front_raise',
    Equipment equipment = Equipment.dumbbell,
  }) => CompanionPainter(
    character: id,
    motion: Motion.frontRaise,
    equipment: equipment,
    exerciseId: exercise,
    phase: phase,
    sprites: sheets[id],
  );

  for (final id in companionIds) {
    test(
      '$id has eight dedicated, unclipped forward-dumbbell-front-raise drawings with stable ground',
      () async {
        final sprites = sheets[id]!;
        final atlas = sprites.frontRaise!;
        final bytes = (await atlas.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final sources = <Rect>{};
        final ground = <double>[];
        final handles = <Offset>[];
        final rightFractions = <double>[];
        final footCenters = <double>[];

        final poses = <List<int>>[];
        for (var i = 0; i < 8; i++) {
          final f = painter(id, i / 8).frame!;
          expect(f.image, same(atlas));
          expect(f.clip, 'front_raise');
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
          var handleCount = 0, rightCount = 0;
          var handleX = 0.0, handleY = 0.0;

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
                // Green rubber marks the forward-moving dumbbells, not the
                // fixed body/gills. Peak must be on the forward (screen-right)
                // side, so the bilateral lateral-raise atlas cannot pass.
                final r = bytes[offset],
                    g = bytes[offset + 1],
                    b = bytes[offset + 2];
                if (y > f.source.top + f.source.height * .35 &&
                    y < f.source.top + f.source.height * .85 &&
                    g > r + 12 &&
                    g > b + 8 &&
                    g > 90) {
                  handleCount++;
                  handleX += x - f.source.left;
                  handleY += y - f.source.top;
                  if (x > f.source.center.dx) rightCount++;
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
            reason: 'Complete standing character and dumbbells, not an empty placeholder',
          );
          expect(clear, greaterThan(10000), reason: 'Actual alpha background');
          ground.add(last - f.source.top);
          expect(
            handleCount,
            greaterThan(200),
            reason: 'Visible mint dumbbells',
          );
          handles.add(Offset(handleX / handleCount, handleY / handleCount));
          rightFractions.add(rightCount / handleCount);
          // Check planted-foot x as well as ground y; this catches horizontal
          // atlas drift even though the destination rectangle stays fixed.
          var footX = 0.0, footCount = 0;
          for (var y = last - 7; y <= last; y++) {
            for (
              var x = f.source.left.ceil();
              x < f.source.right.floor();
              x++
            ) {
              if (bytes[(y * atlas.width + x) * 4 + 3] > 200) {
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
        expect(handles[4].dx - handles[0].dx, greaterThan(30));
        expect(handles[0].dy - handles[4].dy, greaterThan(40));
        expect(
          rightFractions[4],
          greaterThan(.9),
          reason: 'Both weights reach forward/right, not spread to both sides',
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
          painter(id, .5, exercise: 'custom:front'),
          painter(id, .5, equipment: Equipment.cable),
          painter(id, .5, equipment: Equipment.machine),
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
            config.$2 == 'tr' ? 'Dambıl öne kaldırış' : 'Dumbbell front raise',
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
            (w) => w is CompanionStage && w.exerciseId == 'front_raise',
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
    'front raise family, equipment and missing atlas never borrow other clips',
    () {
      for (final id in companionIds) {
        final sprites = sheets[id]!;
        final missing = CompanionSprites(sprites.actions, sprites.pet);
        for (final entry in [
          (sprites, Motion.frontRaise, Equipment.machine, 'front_raise'),
          (sprites, Motion.frontRaise, Equipment.cable, 'front_raise'),
          (sprites, Motion.frontRaise, Equipment.dumbbell, 'lateral_machine'),
          (sprites, Motion.frontRaise, Equipment.dumbbell, 'lateral_dumbbell'),
          (sprites, Motion.frontRaise, Equipment.dumbbell, 'custom:front'),
          (sprites, Motion.overhead, Equipment.dumbbell, 'front_raise'),
          (sprites, Motion.read, Equipment.dumbbell, 'front_raise'),
          (sprites, Motion.reverseFly, Equipment.dumbbell, 'front_raise'),
          (missing, Motion.frontRaise, Equipment.dumbbell, 'front_raise'),
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
          hasActivityFrames(
            Motion.frontRaise,
            Equipment.dumbbell,
            'front_raise',
          ),
          isTrue,
        );
        expect(
          hasActivityFrames(
            Motion.frontRaise,
            Equipment.barbell,
            'front_raise',
          ),
          isFalse,
        );
        expect(
          hasActivityFrames(Motion.press, Equipment.machine, 'front_raise'),
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
            motion: Motion.frontRaise,
            equipment: Equipment.dumbbell,
            exerciseId: 'front_raise',
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
    'capture actual front raise renderer start/flexion contact sheet',
    () async {
      if (Platform.environment['RPG_CAPTURE_FRONT_RAISE'] != '1') return;
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
      await File('docs/screenshots/front-raise-frames.png').writeAsBytes(
        (await im.toByteData(format: ui.ImageByteFormat.png))!.buffer
            .asUint8List(),
      );
      im.dispose();
    },
  );
}
