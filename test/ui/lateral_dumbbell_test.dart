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
        includeShoulderPress: true,
        includeLateralMachine: true,
        includeLateralDumbbell: true,
      );
    }
  });
  CompanionPainter painter(
    String id,
    double phase, {
    String exercise = 'lateral_dumbbell',
    Equipment equipment = Equipment.dumbbell,
  }) => CompanionPainter(
    character: id,
    motion: Motion.lateralRaise,
    equipment: equipment,
    exerciseId: exercise,
    phase: phase,
    sprites: sheets[id],
  );

  for (final id in companionIds) {
    test(
      '$id has eight dedicated, unclipped dumbbell-lateral-raise drawings with stable ground',
      () async {
        final sprites = sheets[id]!;
        final atlas = sprites.lateralDumbbell!;
        final bytes = (await atlas.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final sources = <Rect>{};
        final ground = <double>[];
        final leftWeights = <Offset>[];
        final rightWeights = <Offset>[];
        final poses = <List<int>>[];
        for (var i = 0; i < 8; i++) {
          final f = painter(id, i / 8).frame!;
          expect(f.image, same(atlas));
          expect(f.clip, 'lateral_dumbbell');
          expect(f.count, 8);
          expect(f.index, i);
          sources.add(f.source);
          final cellTop = (i ~/ 4) * atlas.height / 2;
          expect(f.source.top, greaterThanOrEqualTo(cellTop));
          expect(
            f.source.bottom,
            lessThanOrEqualTo(cellTop + atlas.height / 2),
          );
          expect(f.source.height, atlas.height / 2 - 1);
          var last = 0, opaque = 0, clear = 0;
          var left = atlas.width, right = 0, top = atlas.height;
          var leftCount = 0, rightCount = 0;
          var leftX = 0.0, leftY = 0.0, rightX = 0.0, rightY = 0.0;
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
                // Track the two mint dumbbell heads, not the face, fixed seat,
                // or turquoise gills/eyes. Lateral abduction moves each separate weight
                // outward AND up; an overhead-press atlas must not pass.
                final r = bytes[offset],
                    g = bytes[offset + 1],
                    b = bytes[offset + 2];
                if (y > f.source.top + f.source.height * .35 &&
                    y < f.source.top + f.source.height * .85 &&
                    g > r + 12 &&
                    g > b + 8 &&
                    g > 90) {
                  if (x < f.source.center.dx) {
                    leftCount++;
                    leftX += x - f.source.left;
                    leftY += y - f.source.top;
                  } else {
                    rightCount++;
                    rightX += x - f.source.left;
                    rightY += y - f.source.top;
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
            reason: 'Complete standing character and two separate dumbbells, not an empty placeholder',
          );
          expect(clear, greaterThan(10000), reason: 'Actual alpha background');
          ground.add(last - f.source.top);
          expect(leftCount, greaterThan(200), reason: 'Visible left dumbbell');
          expect(
            rightCount,
            greaterThan(200),
            reason: 'Visible right dumbbell',
          );
          leftWeights.add(Offset(leftX / leftCount, leftY / leftCount));
          rightWeights.add(Offset(rightX / rightCount, rightY / rightCount));
          poses.add(pixels);
        }
        expect(sources.length, 8);
        expect(leftWeights[0].dx - leftWeights[4].dx, greaterThan(30));
        expect(rightWeights[4].dx - rightWeights[0].dx, greaterThan(30));
        expect(leftWeights[0].dy - leftWeights[4].dy, greaterThan(40));
        expect(rightWeights[0].dy - rightWeights[4].dy, greaterThan(40));
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
          painter(id, .5, exercise: 'custom:lateral'),
          painter(id, .5, equipment: Equipment.barbell),
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
            config.$2 == 'tr' ? 'Dambıl yana açış' : 'Dumbbell lateral raise',
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
            (w) => w is CompanionStage && w.exerciseId == 'lateral_dumbbell',
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
  test('dumbbell lateral family, equipment and missing atlas never borrow other clips', () {
    for (final id in companionIds) {
      final sprites = sheets[id]!;
      final missing = CompanionSprites(sprites.actions, sprites.pet);
      for (final entry in [
        (sprites, Motion.lateralRaise, Equipment.machine, 'lateral_dumbbell'),
        (sprites, Motion.lateralRaise, Equipment.cable, 'lateral_dumbbell'),
        (sprites, Motion.lateralRaise, Equipment.dumbbell, 'lateral_machine'),
        (sprites, Motion.lateralRaise, Equipment.dumbbell, 'lateral_cable'),
        (sprites, Motion.lateralRaise, Equipment.dumbbell, 'custom:lateral'),
        (sprites, Motion.overhead, Equipment.dumbbell, 'lateral_dumbbell'),
        (sprites, Motion.read, Equipment.dumbbell, 'lateral_dumbbell'),
        (sprites, Motion.reverseFly, Equipment.dumbbell, 'lateral_dumbbell'),
        (missing, Motion.lateralRaise, Equipment.dumbbell, 'lateral_dumbbell'),
      ]) {
        final frame = companionFrame(
          sprites: entry.$1,
          motion: entry.$2,
          equipment: entry.$3,
          exerciseId: entry.$4,
          phase: .5,
        );
        expect(frame.clip, 'idle');
        expect(frame.image, same(id == 'aion' ? sprites.pet : sprites.actions));
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
          Motion.lateralRaise,
          Equipment.dumbbell,
          'lateral_dumbbell',
        ),
        isTrue,
      );
      expect(
        hasActivityFrames(
          Motion.lateralRaise,
          Equipment.barbell,
          'lateral_dumbbell',
        ),
        isFalse,
      );
      expect(
        hasActivityFrames(Motion.press, Equipment.machine, 'lateral_dumbbell'),
        isFalse,
      );
    }
  });
  testWidgets('play resumes at the frame after the manually selected pose', (
    t,
  ) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CompanionStage(
            character: 'aion',
            motion: Motion.lateralRaise,
            equipment: Equipment.dumbbell,
            exerciseId: 'lateral_dumbbell',
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
    'capture actual dumbbell lateral renderer start/abduction contact sheet',
    () async {
      if (Platform.environment['RPG_CAPTURE_LATERALDUMBBELL'] != '1') return;
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
      await File('docs/screenshots/lateral-dumbbell-frames.png').writeAsBytes(
        (await im.toByteData(format: ui.ImageByteFormat.png))!.buffer
            .asUint8List(),
      );
      im.dispose();
    },
  );
}
