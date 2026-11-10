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
        includePullUp: true,
        includeAssistedPullUp: true,
      );
    }
  });
  CompanionPainter painter(
    String id,
    double phase, {
    String exercise = 'assisted_pull_up',
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
      '$id has eight assisted pull-up drawings with rising support/body and fixed machine',
      () async {
        final atlas = sheets[id]!.assistedPullUp!;
        final bytes = (await atlas.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final poses = <List<int>>[];
        final sources = <Rect>{};
        final bars = <Offset>[];
        final leftTips = <Offset>[], rightTips = <Offset>[];
        final rackGround = <double>[];
        final pads = <Offset>[];
        final bodyBottom = <double>[];
        for (var i = 0; i < 8; i++) {
          final f = painter(id, i / 8).frame!;
          expect(f.image, same(atlas));
          expect(f.clip, 'assisted_pull_up');
          expect(f.index, i);
          expect(f.count, 8);
          sources.add(f.source);
          final cell = Rect.fromLTWH(
            (i % 4) * atlas.width / 4,
            (i ~/ 4) * atlas.height / 2,
            atlas.width / 4,
            atlas.height / 2,
          );
          expect(cell.contains(f.source.topLeft), isTrue);
          expect(f.source.right, lessThanOrEqualTo(cell.right));
          expect(f.source.bottom, lessThanOrEqualTo(cell.bottom));
          var clear = 0, opaque = 0;
          var left = atlas.width, right = 0, top = atlas.height, last = 0;
          var barCount = 0, barX = 0.0, barY = 0.0;
          var barLeft = atlas.width, barRight = 0;
          final bodyRows = <int, int>{}, baseRows = <int, int>{};
          final barPixels = <Offset>[];
          final padRows = <int, List<double>>{};
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
              final o = (y * atlas.width + x) * 4;
              final a = bytes[o + 3];
              if (a == 0) clear++;
              if (a <= 200) continue;
              opaque++;
              if (x < left) left = x;
              if (x > right) right = x;
              if (y < top) top = y;
              last = y;
              final r = bytes[o], g = bytes[o + 1], b = bytes[o + 2];
              final dx = x - f.source.left, dy = y - f.source.top;
              final channels = [r, g, b]..sort();
              // Dense neutral rows at machine base corners, independent of the pad/body.
              if (dy > f.source.height * .75 &&
                  (dx < f.source.width * .25 || dx > f.source.width * .75) &&
                  channels.last - channels.first < 45) {
                baseRows[y] = (baseRows[y] ?? 0) + 1;
              }
              // Saturated warm lower-body rows exclude the neutral machine's
              // warm reflections; this is not an anatomical landmark detector.
              if (dy > f.source.height * .3 &&
                  dx > f.source.width * .25 &&
                  dx < f.source.width * .68 &&
                  channels.last - channels.first > 35 &&
                  r > g + 8 &&
                  r > b + 5) {
                bodyRows[y] = (bodyRows[y] ?? 0) + 1;
              }
              // The broad royal-blue support must move with the body. Narrow eye,
              // gill or violet-forearm pixels cannot pass the dense-row threshold.
              if (dy > f.source.height * .42 &&
                  dx > f.source.width * .20 &&
                  dx < f.source.width * .75 &&
                  b > r + 35 &&
                  b > g + 25 &&
                  b > 100) {
                final row = padRows.putIfAbsent(y, () => [0.0, 0.0]);
                row[0]++;
                row[1] += dx;
              }
              if (dy > f.source.height * .05 &&
                  dy < f.source.height * .4 &&
                  g > r + 12 &&
                  g > b + 8 &&
                  g > 90) {
                barCount++;
                barX += dx;
                barY += dy;
                barPixels.add(Offset(dx, dy));
                if (x < barLeft) barLeft = x;
                if (x > barRight) barRight = x;
              }
            }
          }
          expect(left - f.source.left, greaterThan(5));
          expect(f.source.right - right, greaterThan(5));
          expect(top - f.source.top, greaterThan(5));
          expect(f.source.bottom - last, greaterThan(5));
          expect(opaque, greaterThan(7000));
          expect(clear, greaterThan(10000));
          expect(barCount, greaterThan(200));
          bars.add(Offset(barX / barCount, barY / barCount));
          expect(barRight - barLeft, greaterThan(f.source.width * .35));
          // Hands, wing straps and the face can occlude the center in this
          // three-quarter view. Track both visible green ends independently;
          // do not mistake a specular highlight or occlusion for a moving bar.
          Offset tip(bool leftEnd) {
            final end = barPixels
                .where(
                  (p) => leftEnd
                      ? p.dx <= barLeft - f.source.left + 25
                      : p.dx >= barRight - f.source.left - 25,
                )
                .toList();
            expect(end.length, greaterThan(15));
            return end.reduce((a, b) => a + b) / end.length.toDouble();
          }

          leftTips.add(tip(true));
          rightTips.add(tip(false));
          final base = baseRows.entries
              .where((e) => e.value >= 8)
              .map((e) => e.key)
              .toList();
          expect(base, isNotEmpty);
          rackGround.add(base.last - f.source.top);
          final body = bodyRows.entries
              .where((e) => e.value >= 8)
              .map((e) => e.key)
              .toList();
          expect(body, isNotEmpty);
          bodyBottom.add(body.last - f.source.top);
          final pad = padRows.entries
              .where((e) => e.value[0] >= f.source.width * .16)
              .toList();
          expect(
            pad,
            isNotEmpty,
            reason: 'A broad royal-blue assistance pad, not a free pull-up or eye highlight',
          );
          var padCount = 0.0, padX = 0.0, padY = 0.0;
          for (final row in pad) {
            padCount += row.value[0];
            padX += row.value[1];
            padY += (row.key - f.source.top) * row.value[0];
          }
          pads.add(Offset(padX / padCount, padY / padCount));
          expect(
            pads.last.dy - bodyBottom.last,
            inInclusiveRange(0, 25),
            reason: 'Drawn knees/feet remain just above the support, not floating independently',
          );
          // Source registration trims only empty padding, never opaque anatomy.
          for (var y = cell.top.ceil(); y < cell.bottom.floor(); y++) {
            for (var x = cell.left.ceil(); x < cell.right.floor(); x++) {
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
        double span(Iterable<double> xs) =>
            xs.reduce((a, b) => a > b ? a : b) -
            xs.reduce((a, b) => a < b ? a : b);
        expect(sources.length, 8);
        for (final tips in [leftTips, rightTips]) {
          expect(span(tips.map((p) => p.dy)), lessThan(5));
          expect(span(tips.map((p) => p.dx)), lessThan(6));
        }
        expect(
          span(Iterable.generate(8, (i) => rightTips[i].dy - leftTips[i].dy)),
          lessThan(3),
          reason: 'Fixed perspective tilt, not a rotating bar',
        );
        expect(
          span(bars.map((p) => p.dy)),
          lessThan(5),
          reason: 'The bar stays fixed; a moving lat-pulldown bar must fail',
        );
        expect(
          span(bars.map((p) => p.dx)),
          lessThan(6),
          reason: 'Whole machine must not slide horizontally',
        );
        expect(
          span(rackGround),
          lessThanOrEqualTo(2),
          reason: 'Neutral machine base stays fixed independently',
        );
        expect(
          pads[0].dy - pads[4].dy,
          greaterThan(60),
          reason: 'Support rises, not a static stool under a free pull-up',
        );
        expect(
          bodyBottom[0] - bodyBottom[4],
          greaterThan(60),
          reason: 'The whole drawn character rises with the pad',
        );
        expect(
          ((pads[0].dy - pads[4].dy) - (bodyBottom[0] - bodyBottom[4])).abs(),
          lessThan(8),
          reason: 'Body and support ascent agree independently',
        );
        expect(
          pads[7].dy - pads[4].dy,
          greaterThan(60),
          reason: 'Support descends after the highest pose',
        );
        expect(bodyBottom[7] - bodyBottom[4], greaterThan(60));
        expect(
          (bodyBottom.first - bodyBottom.last).abs(),
          lessThanOrEqualTo((bodyBottom[0] - bodyBottom[1]).abs() + 2),
          reason: 'Loop closure has no oversized jump',
        );
        expect(
          span(pads.map((p) => p.dx)),
          lessThan(8),
          reason: 'Support stays on its vertical rail',
        );
        for (var i = 1; i < 8; i++) {
          expect(listEquals(poses[i - 1], poses[i]), isFalse);
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
            config.$2 == 'tr' ? 'Destekli barfiks' : 'Assisted pull-up',
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
            (w) => w is CompanionStage && w.exerciseId == 'assisted_pull_up',
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
  test('assisted pull-up rejects wrong equipment/family and preserves separate free/lat clips', () {
    for (final id in companionIds) {
      final sprites = sheets[id]!;
      final missing = CompanionSprites(sprites.actions, sprites.pet);
      for (final entry in [
        (sprites, Motion.pulldown, Equipment.bodyweight, 'assisted_pull_up'),
        (sprites, Motion.pulldown, Equipment.dumbbell, 'assisted_pull_up'),
        (sprites, Motion.pulldown, Equipment.cable, 'assisted_pull_up'),
        (sprites, Motion.pulldown, Equipment.machine, 'pull_up'),
        (sprites, Motion.pulldown, Equipment.cable, 'lat_pulldown'),
        (sprites, Motion.pulldown, Equipment.machine, 'custom:assisted'),
        (sprites, Motion.overhead, Equipment.machine, 'assisted_pull_up'),
        (sprites, Motion.read, Equipment.machine, 'assisted_pull_up'),
        (sprites, Motion.reverseFly, Equipment.machine, 'assisted_pull_up'),
        (missing, Motion.pulldown, Equipment.machine, 'assisted_pull_up'),
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
      for (final valid in [
        (Equipment.bodyweight, 'pull_up', sprites.pullUp),
        (Equipment.machine, 'lat_pulldown', sprites.latPulldown),
      ]) {
        final frame = companionFrame(
          sprites: sprites,
          motion: Motion.pulldown,
          equipment: valid.$1,
          exerciseId: valid.$2,
          phase: .5,
        );
        expect(frame.clip, valid.$2);
        expect(frame.image, same(valid.$3));
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
          Motion.pulldown,
          Equipment.machine,
          'assisted_pull_up',
        ),
        isTrue,
      );
      expect(
        hasActivityFrames(
          Motion.pulldown,
          Equipment.bodyweight,
          'assisted_pull_up',
        ),
        isFalse,
      );
      expect(
        hasActivityFrames(Motion.press, Equipment.machine, 'assisted_pull_up'),
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
            motion: Motion.pulldown,
            equipment: Equipment.machine,
            exerciseId: 'assisted_pull_up',
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
    'capture actual assisted pull-up renderer low/high support contact sheet',
    () async {
      if (Platform.environment['RPG_CAPTURE_ASSISTED_PULL_UP'] != '1') return;
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
      await File('docs/screenshots/assisted-pull-up-frames.png').writeAsBytes(
        (await im.toByteData(format: ui.ImageByteFormat.png))!.buffer
            .asUint8List(),
      );
      im.dispose();
    },
  );
}
