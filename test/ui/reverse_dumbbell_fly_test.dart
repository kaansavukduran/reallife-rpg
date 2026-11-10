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
        includeChestPress: true,
        includeBenchPress: true,
        includeInclinePress: true,
        includePushUp: true,
        includePecDeck: true,
        includeCableFly: true,
        includeReverseDumbbellFly: true,
      );
    }
  });
  CompanionPainter painter(
    String id,
    double phase, {
    String exercise = 'reverse_dumbbell_fly',
    Equipment equipment = Equipment.dumbbell,
  }) => CompanionPainter(
    character: id,
    motion: Motion.reverseFly,
    equipment: equipment,
    exerciseId: exercise,
    phase: phase,
    sprites: sheets[id],
  );

  for (final id in companionIds) {
    test(
      '$id has eight dedicated, unclipped reverse-dumbbell-fly drawings with stable ground',
      () async {
        final sprites = sheets[id]!;
        final atlas = sprites.reverseDumbbellFly!;
        final bytes = (await atlas.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final sources = <Rect>{};
        final ground = <double>[];
        final poses = <List<int>>[];
        for (var i = 0; i < 8; i++) {
          final f = painter(id, i / 8).frame!;
          expect(f.image, same(atlas));
          expect(f.clip, 'reverse_dumbbell_fly');
          expect(f.count, 8);
          expect(f.index, i);
          sources.add(f.source);
          expect(f.source.top, closeTo((i ~/ 4) * atlas.height / 2 + .5, .001));
          var last = 0, opaque = 0, clear = 0;
          var left = atlas.width, right = 0, top = atlas.height;
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
              final a = bytes[(y * atlas.width + x) * 4 + 3];
              if (a == 0) clear++;
              if (a > 200) {
                opaque++;
                last = y;
                if (x < left) left = x;
                if (x > right) right = x;
                if (y < top) top = y;
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
            reason: 'Complete bent-over character with two dumbbells, not an empty placeholder',
          );
          expect(clear, greaterThan(10000), reason: 'Actual alpha background');
          ground.add(last - f.source.top);
          poses.add(pixels);
        }
        expect(sources.length, 8);
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
          painter(id, .5, exercise: 'bench_press'),
          painter(id, .5, exercise: 'custom:press'),
          painter(id, .5, equipment: Equipment.machine),
          painter(id, .5, equipment: Equipment.barbell),
        ]) {
          expect(variant.frame!.clip, 'idle');
          expect(
            variant.frame!.source.top,
            .5,
            reason: 'Unsupported equipment must use idle row, never the old machine drawing',
          );
          expect(variant.frame!.image, isNot(same(atlas)));
        }
      },
    );
  }

  test('unsupported equipment and an unloaded dedicated sheet render genuine idle, never the machine fly', () async {
    for (final id in companionIds) {
      final base = await loadCompanionSprites(id);
      final idle = companionFrame(
        sprites: base,
        motion: Motion.idle,
        phase: .5,
      );
      for (final pair in [
        (Motion.reverseFly, Equipment.machine, 'reverse_dumbbell_fly'),
        (Motion.reverseFly, Equipment.cable, 'face_pull'),
        (Motion.curl, Equipment.barbell, 'custom:curl'),
        (Motion.curl, Equipment.dumbbell, 'reverse_dumbbell_fly'),
      ]) {
        expect(hasActivityFrames(pair.$1, pair.$2, pair.$3), isFalse);
        final actual = companionFrame(
          sprites: base,
          motion: pair.$1,
          equipment: pair.$2,
          exerciseId: pair.$3,
          phase: .5,
        );
        expect(actual.clip, 'idle');
        expect(actual.image, same(idle.image));
        expect(actual.source, idle.source);
        expect(actual.count, idle.count);
      }
      final unloaded = companionFrame(
        sprites: base,
        motion: Motion.reverseFly,
        equipment: Equipment.dumbbell,
        exerciseId: 'reverse_dumbbell_fly',
        phase: .5,
      );
      expect(unloaded.clip, 'idle');
      expect(unloaded.image, same(idle.image));
      expect(unloaded.source, idle.source);
    }
  });

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
            config.$2 == 'tr' ? 'Dambıl ters açış' : 'Dumbbell reverse fly',
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
            (w) =>
                w is CompanionStage && w.exerciseId == 'reverse_dumbbell_fly',
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
  testWidgets('play resumes at the frame after the manually selected pose', (
    t,
  ) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CompanionStage(
            character: 'aion',
            motion: Motion.reverseFly,
            equipment: Equipment.dumbbell,
            exerciseId: 'reverse_dumbbell_fly',
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
  test('capture actual reverse-dumbbell-fly renderer start/extension contact sheet', () async {
    if (Platform.environment['RPG_CAPTURE_REVERSEDUMBBELL'] != '1') return;
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
    await File('docs/screenshots/reverse-dumbbell-fly-frames.png').writeAsBytes(
      (await im.toByteData(format: ui.ImageByteFormat.png))!.buffer
          .asUint8List(),
    );
    im.dispose();
  });
}
