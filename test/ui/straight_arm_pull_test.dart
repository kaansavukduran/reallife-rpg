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
        includeCableRow: true,
        includeMachineRow: true,
        includeOneArmRow: true,
        includeBarbellRow: true,
        includeBandRow: true,
        includeStraightArmPull: true,
      );
    }
  });
  CompanionPainter painter(
    String id,
    double phase, {
    String exercise = 'straight_arm_pull',
    Equipment equipment = Equipment.cable,
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
      '$id has eight distinct connected high-cable sweeps with stable support',
      () async {
        final atlas = sheets[id]!.straightArmPull!;
        final bytes = (await atlas.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final positions = <Offset>[], sources = <Rect>{}, poses = <List<int>>[];
        final top = <double>[],
            postTop = <double>[],
            postRight = <double>[],
            postBottom = <double>[],
            matLeft = <double>[],
            matBottom = <double>[],
            footBottom = <double>[],
            barWidths = <double>[];
        final destinations = <Size>{};
        for (var i = 0; i < 8; i++) {
          final f = painter(id, i / 8).frame!;
          expect(f.image, same(atlas));
          expect(f.clip, 'straight_arm_pull');
          expect(f.index, i);
          expect(f.count, 8);
          sources.add(f.source);
          final w = (atlas.width / 4).floor(), h = (atlas.height / 2).floor();
          final x0 = ((i % 4) * atlas.width / 4).floor(),
              y0 = ((i ~/ 4) * atlas.height / 2).floor();
          expect(f.source.left, greaterThanOrEqualTo(x0));
          expect(f.source.top, greaterThanOrEqualTo(y0));
          final pose = <int>[], green = <int>{};
          var clear = 0,
              opaque = 0,
              left = w,
              right = 0,
              upper = h,
              bottom = 0,
              headTop = h,
              pt = h,
              pr = 0,
              pb = 0,
              ml = w,
              mb = 0,
              fb = 0;
          for (var y = 0; y < h; y++) {
            for (var x = 0; x < w; x++) {
              final j = ((y0 + y) * atlas.width + x0 + x) * 4;
              final r = bytes[j],
                  g = bytes[j + 1],
                  b = bytes[j + 2],
                  alpha = bytes[j + 3];
              pose.add(alpha);
              if (alpha == 0) clear++;
              if (alpha < 201) continue;
              opaque++;
              left = x < left ? x : left;
              right = x > right ? x : right;
              upper = y < upper ? y : upper;
              bottom = y > bottom ? y : bottom;
              if (x < w * .7 && y < h * .5 && y < headTop) headTop = y;
              final max = r > g ? (r > b ? r : b) : (g > b ? g : b),
                  min = r < g ? (r < b ? r : b) : (g < b ? g : b);
              if (x > w * .8 && max - min < 35) {
                pt = y < pt ? y : pt;
                pr = x > pr ? x : pr;
                pb = y > pb ? y : pb;
              }
              if (y > h * .8 && x < w * .8 && b > r + 40 && b > g + 15) {
                ml = x < ml ? x : ml;
                mb = y > mb ? y : mb;
              }
              if (x > w * .18 &&
                  x < w * .68 &&
                  y > h * .77 &&
                  y < h * .9 &&
                  r > g + 8 &&
                  r > b + 5 &&
                  (id != 'owl' || (r > g + 30 && g > b + 35))) {
                fb = y > fb ? y : fb;
              }
              if (g > r + 35 &&
                  g > b + 30 &&
                  g > 90 &&
                  y > h * .25 &&
                  y < h * .83) {
                green.add(y * w + x);
              }
            }
          }
          expect(clear, greaterThan(10000));
          expect(opaque, greaterThan(15000));
          expect(left, greaterThan(4));
          expect(upper, greaterThan(4));
          expect(w - right, greaterThan(4));
          expect(h - bottom, greaterThan(4));
          for (final previous in poses) {
            expect(
              listEquals(previous, pose),
              isFalse,
              reason: '$id pose $i must be separately drawn',
            );
          }
          poses.add(pose);
          // The central blue cable fitting may split the green paint into two
          // substantial parts. Track both, excluding isolated antialias specks.
          final handle = <int>[];
          while (green.isNotEmpty) {
            final component = <int>[green.first];
            green.remove(component.first);
            for (var q = 0; q < component.length; q++) {
              final n = component[q];
              for (final other in [
                if (n % w > 0) n - 1,
                if (n % w < w - 1) n + 1,
                n - w,
                n + w,
              ]) {
                if (green.remove(other)) component.add(other);
              }
            }
            if (component.length >= 200) handle.addAll(component);
          }
          expect(handle.length, greaterThan(450));
          final xs = handle.map((n) => (n % w).toDouble()).toList(),
              ys = handle.map((n) => (n ~/ w).toDouble()).toList();
          double low(List<double> v) => v.reduce((a, b) => a < b ? a : b);
          double high(List<double> v) => v.reduce((a, b) => a > b ? a : b);
          final center = Offset(
            xs.reduce((a, b) => a + b) / xs.length,
            ys.reduce((a, b) => a + b) / ys.length,
          );
          positions.add(center);
          barWidths.add(high(xs) - low(xs));
          final grips = <int>[0, 0];
          final eye = <Offset>[];
          for (
            var y = (low(ys) - 35).floor();
            y <= (high(ys) + 20).ceil();
            y++
          ) {
            for (
              var x = (low(xs) - 25).floor();
              x <= (high(xs) + 25).ceil();
              x++
            ) {
              if (x < 0 || y < 0 || x >= w || y >= h) continue;
              final j = ((y0 + y) * atlas.width + x0 + x) * 4;
              final r = bytes[j], g = bytes[j + 1], b = bytes[j + 2];
              if (bytes[j + 3] < 201 || b < r + 50 || b < g + 35) continue;
              if ((x - low(xs)).abs() < 25 && (y - center.dy).abs() < 22) {
                grips[0]++;
              }
              if ((x - high(xs)).abs() < 25 && (y - center.dy).abs() < 22) {
                grips[1]++;
              }
              if ((x - center.dx).abs() < 15 && y < low(ys) - 3) {
                eye.add(Offset(x.toDouble(), y.toDouble()));
              }
            }
          }
          expect(
            grips.every((v) => v > 10),
            isTrue,
            reason: 'Two separated blue grip ends remain attached',
          );
          expect(eye.length, greaterThan(8));
          final eyeCenter = eye.reduce((a, b) => a + b) / eye.length.toDouble();
          final pulley = Offset(
            w *
                (id == 'sheep'
                    ? .83
                    : id == 'owl'
                    ? .86
                    : .87),
            h * .10,
          );
          // Read the actual gray cable at nine interior points, allowing antialias/stroke-width tolerance.
          for (var step = 1; step <= 9; step++) {
            final point = Offset.lerp(eyeCenter, pulley, step / 10)!;
            var hits = 0;
            for (var dy = -7; dy <= 7; dy++) {
              for (var dx = -7; dx <= 7; dx++) {
                final x = point.dx.round() + dx, y = point.dy.round() + dy;
                if (x < 0 || y < 0 || x >= w || y >= h) continue;
                final j = ((y0 + y) * atlas.width + x0 + x) * 4;
                final r = bytes[j], g = bytes[j + 1], b = bytes[j + 2];
                final max = r > g ? (r > b ? r : b) : (g > b ? g : b),
                    min = r < g ? (r < b ? r : b) : (g < b ? g : b);
                if (bytes[j + 3] > 200 &&
                    max - min < 45 &&
                    min > 35 &&
                    max < 235) {
                  hits++;
                }
              }
            }
            expect(
              hits,
              greaterThan(2),
              reason: '$id frame $i cable remains connected at sample $step',
            );
          }
          expect(fb, greaterThan(h * .77));
          top.add(headTop.toDouble());
          postTop.add(pt.toDouble());
          postRight.add(pr.toDouble());
          postBottom.add(pb.toDouble());
          matLeft.add(ml.toDouble());
          matBottom.add(mb.toDouble());
          footBottom.add(fb.toDouble());
          destinations.add(f.source.size);
        }
        double span(List<double> v) =>
            v.reduce((a, b) => a > b ? a : b) -
            v.reduce((a, b) => a < b ? a : b);
        expect(sources.length, 8);
        expect(
          destinations.length,
          1,
          reason: 'Complete equal source windows keep renderer fit constant',
        );
        for (var i = 1; i <= 4; i++) {
          expect(positions[i].dy - positions[i - 1].dy, greaterThan(8));
        }
        for (var i = 5; i < 8; i++) {
          expect(positions[i - 1].dy - positions[i].dy, greaterThan(20));
        }
        expect(positions[4].dy - positions[0].dy, greaterThan(130));
        expect(positions[4].dy - positions[7].dy, greaterThan(110));
        expect(positions[0].dx - positions[4].dx, greaterThan(35));
        expect(
          (positions[7].dy - positions[0].dy).abs(),
          lessThanOrEqualTo((positions[1].dy - positions[0].dy).abs() + 3),
        );
        expect(
          span(barWidths),
          lessThan(15),
          reason: 'Joined handle keeps its length',
        );
        expect(
          span(postTop),
          lessThanOrEqualTo(4),
          reason: 'Gray pulley outline varies by at most four source pixels; head/feet/mat stay within three',
        );
        for (final values in [
          top,
          postRight,
          postBottom,
          matLeft,
          matBottom,
          footBottom,
        ]) {
          expect(span(values), lessThanOrEqualTo(3));
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
            config.$2 == 'tr'
                ? 'Düz kol kablo çekiş'
                : 'Straight-arm cable pulldown',
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
            (w) => w is CompanionStage && w.exerciseId == 'straight_arm_pull',
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
  test('straight arm pull rejects wrong pair/missing art and preserves all other rows and vertical clips', () {
    for (final id in companionIds) {
      final sprites = sheets[id]!,
          missing = CompanionSprites(sheets[id]!.actions, sheets[id]!.pet);
      for (final entry in [
        (sprites, Motion.pulldown, Equipment.band, 'straight_arm_pull'),
        (sprites, Motion.pulldown, Equipment.dumbbell, 'straight_arm_pull'),
        (sprites, Motion.pulldown, Equipment.machine, 'straight_arm_pull'),
        (sprites, Motion.row, Equipment.cable, 'straight_arm_pull'),
        (sprites, Motion.read, Equipment.cable, 'straight_arm_pull'),
        (sprites, Motion.curl, Equipment.cable, 'straight_arm_pull'),
        (sprites, Motion.pulldown, Equipment.cable, 'custom:pull'),
        (sprites, Motion.shrug, Equipment.dumbbell, 'shrug'),
        (missing, Motion.pulldown, Equipment.cable, 'straight_arm_pull'),
      ]) {
        final f = companionFrame(
          sprites: entry.$1,
          motion: entry.$2,
          equipment: entry.$3,
          exerciseId: entry.$4,
          phase: .5,
        );
        expect(f.clip, 'idle');
        expect(f.image, same(id == 'aion' ? sprites.pet : sprites.actions));
        expect(f.source.top, .5);
      }
      for (final valid in [
        (Motion.row, Equipment.band, 'band_row', sprites.bandRow),
        (Motion.row, Equipment.barbell, 'barbell_row', sprites.barbellRow),
        (Motion.row, Equipment.dumbbell, 'one_arm_row', sprites.oneArmRow),
        (Motion.row, Equipment.machine, 'machine_row', sprites.machineRow),
        (Motion.row, Equipment.cable, 'cable_row', sprites.cableRow),
        (
          Motion.pulldown,
          Equipment.machine,
          'assisted_pull_up',
          sprites.assistedPullUp,
        ),
        (Motion.pulldown, Equipment.bodyweight, 'pull_up', sprites.pullUp),
        (
          Motion.pulldown,
          Equipment.machine,
          'lat_pulldown',
          sprites.latPulldown,
        ),
      ]) {
        final f = companionFrame(
          sprites: sprites,
          motion: valid.$1,
          equipment: valid.$2,
          exerciseId: valid.$3,
          phase: .5,
        );
        expect(f.clip, valid.$3);
        expect(f.image, same(valid.$4));
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
          Equipment.cable,
          'straight_arm_pull',
        ),
        isTrue,
      );
      expect(
        hasActivityFrames(Motion.read, Equipment.cable, 'straight_arm_pull'),
        isFalse,
      );
      expect(
        hasActivityFrames(Motion.row, Equipment.cable, 'straight_arm_pull'),
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
            equipment: Equipment.cable,
            exerciseId: 'straight_arm_pull',
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
    'capture actual straight arm cable renderer high/low contact sheet',
    () async {
      if (Platform.environment['RPG_CAPTURE_STRAIGHT_ARM_PULL'] != '1') return;
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
      await File('docs/screenshots/straight-arm-pull-frames.png').writeAsBytes(
        (await im.toByteData(format: ui.ImageByteFormat.png))!.buffer
            .asUint8List(),
      );
      im.dispose();
    },
  );
}
