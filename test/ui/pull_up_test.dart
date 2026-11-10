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
      );
    }
  });
  CompanionPainter painter(
    String id,
    double phase, {
    String exercise = 'pull_up',
    Equipment equipment = Equipment.bodyweight,
  }) => CompanionPainter(
    character: id,
    motion: Motion.pulldown,
    equipment: equipment,
    exerciseId: exercise,
    phase: phase,
    sprites: sheets[id],
  );

  for (final id in companionIds) {
    test('$id has eight whole-body pull-up drawings, fixed rack and rising body', () async {
      final atlas = sheets[id]!.pullUp!;
      final bytes = (await atlas.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
      final poses = <List<int>>[];
      final sources = <Rect>{};
      final bars = <Offset>[];
      final rackGround = <double>[];
      final bodyBottom = <double>[];
      final count = activityFrameCount(
        id,
        Motion.pulldown,
        Equipment.bodyweight,
        'pull_up',
      );
      for (var i = 0; i < count; i++) {
        final f = painter(id, i / count).frame!;
        expect(f.image, same(atlas));
        expect(f.clip, 'pull_up');
        expect(f.index, i);
        expect(f.count, count);
        sources.add(f.source);
        final drawing = i == 8 ? 1 : i;
        final cell = Rect.fromLTWH(
          (drawing % 4) * atlas.width / 4,
          (drawing ~/ 4) * atlas.height / 2,
          atlas.width / 4,
          atlas.height / 2,
        );
        expect(cell.contains(f.source.topLeft), isTrue);
        expect(f.source.right, lessThanOrEqualTo(cell.right));
        expect(f.source.bottom, lessThanOrEqualTo(cell.bottom));
        var clear = 0, opaque = 0;
        var left = atlas.width, right = 0, top = atlas.height, last = 0;
        var barCount = 0, barX = 0.0, barY = 0.0;
        var barLeft = atlas.width, barRight = 0, rackLast = 0;
        final barRows = <int, int>{}, bodyRows = <int, int>{};
        final pixels = <int>[];
        for (var y = f.source.top.ceil(); y < f.source.bottom.floor(); y++) {
          pixels.addAll(
            bytes.sublist(
              (y * atlas.width + f.source.left.ceil()) * 4,
              (y * atlas.width + f.source.right.floor()) * 4,
            ),
          );
          for (var x = f.source.left.ceil(); x < f.source.right.floor(); x++) {
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
            if (dy > f.source.height * .75 &&
                dx > f.source.width * .75 &&
                (r - g).abs() < 25 &&
                (r - b).abs() < 25 &&
                (g - b).abs() < 25) {
              rackLast = y;
            }
            // Dense warm-colored lower-body rows, independent of the gray rack.
            // Owl includes its hanging tail; this is not an anatomical landmark detector.
            if (dy > f.source.height * .4 &&
                dx > f.source.width * .36 &&
                dx < f.source.width * .60 &&
                r > g + 8 &&
                r > b + 5) {
              bodyRows[y] = (bodyRows[y] ?? 0) + 1;
            }
            if (dy > f.source.height * .1 &&
                dy < f.source.height * .5 &&
                g > r + 12 &&
                g > b + 8 &&
                g > 90) {
              barCount++;
              barX += dx;
              barY += dy;
              if (x < barLeft) barLeft = x;
              if (x > barRight) barRight = x;
              if (dx > f.source.width * .35 && dx < f.source.width * .55) {
                barRows[y] = (barRows[y] ?? 0) + 1;
              }
            }
          }
        }
        expect(left - f.source.left, greaterThan(5));
        expect(f.source.right - right, greaterThan(5));
        expect(top - f.source.top, greaterThan(5));
        expect(f.source.bottom - last, greaterThan(5));
        expect(opaque, greaterThan(7000));
        expect(
          clear,
          greaterThan(10000),
          reason: 'Actual alpha, not an opaque rectangle',
        );
        expect(barCount, greaterThan(200));
        bars.add(Offset(barX / barCount, barY / barCount));
        expect(barRight - barLeft, greaterThan(f.source.width * .35));
        expect(barRows, isNotEmpty);
        expect(
          barRows.values.reduce((a, b) => a > b ? a : b) /
              (f.source.width * .20),
          greaterThan(.75),
          reason: 'One connected bar crosses the middle',
        );
        expect(rackLast, greaterThan(f.source.top + f.source.height * .75));
        rackGround.add(rackLast - f.source.top);
        final denseBody = bodyRows.entries
            .where((e) => e.value >= 8)
            .map((e) => e.key)
            .toList();
        expect(denseBody, isNotEmpty);
        bodyBottom.add(denseBody.last - f.source.top);
        // Source registration may trim empty padding only, never opaque anatomy.
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
      expect(
        span(bars.map((p) => p.dy)),
        lessThan(8),
        reason: 'Fixed pull-up bar, not a descending lat-pulldown bar',
      );
      expect(
        span(bars.map((p) => p.dx)),
        lessThan(5),
        reason: 'Rack registration prevents horizontal slide',
      );
      expect(
        span(rackGround),
        lessThanOrEqualTo(2),
        reason: 'Gray rack ground is independent of moving character',
      );
      expect(
        bodyBottom[0] - bodyBottom[4],
        greaterThan(70),
        reason: 'Drawn body rises, not just bar or fixed destination',
      );
      expect(
        bodyBottom[7] - bodyBottom[4],
        greaterThan(40),
        reason: 'Drawn body descends after the highest pose',
      );
      expect(
        (bodyBottom.first - bodyBottom.last).abs(),
        lessThanOrEqualTo((bodyBottom[0] - bodyBottom[1]).abs() + 2),
        reason: 'Loop closure must not jump farther than its first upward step',
      );
      for (var i = 1; i < count; i++) {
        expect(listEquals(poses[i - 1], poses[i]), isFalse);
      }
    });
  }

  for (final config in [
    ('aion', 'tr', false),
    ('sheep', 'en', false),
    ('wolf', 'tr', true),
    ('owl', 'en', true),
  ]) {
    testWidgets(
      'frame controls, pause, reduced motion and persistence (${config.$1}, ${config.$2}, phone=${config.$3})',
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

        await click(find.text(config.$2 == 'tr' ? 'Barfiks' : 'Pull-up'));
        final slider = find.byKey(const Key('animation-phase'));
        expect(t.widget<Slider>(slider).divisions, config.$1 == 'aion' ? 8 : 7);
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
            (w) => w is CompanionStage && w.exerciseId == 'pull_up',
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
    'pull-up family, equipment and missing atlas never borrow other clips',
    () {
      for (final id in companionIds) {
        final sprites = sheets[id]!;
        final missing = CompanionSprites(sprites.actions, sprites.pet);
        for (final entry in [
          (sprites, Motion.pulldown, Equipment.dumbbell, 'pull_up'),
          (sprites, Motion.pulldown, Equipment.cable, 'pull_up'),
          (sprites, Motion.pulldown, Equipment.machine, 'lateral_machine'),
          (sprites, Motion.pulldown, Equipment.machine, 'lateral_dumbbell'),
          (sprites, Motion.pulldown, Equipment.bodyweight, 'custom:pull'),
          (sprites, Motion.pulldown, Equipment.machine, 'assisted_pull_up'),
          (sprites, Motion.pulldown, Equipment.bodyweight, 'lat_pulldown'),
          (sprites, Motion.overhead, Equipment.bodyweight, 'pull_up'),
          (sprites, Motion.read, Equipment.bodyweight, 'pull_up'),
          (sprites, Motion.reverseFly, Equipment.bodyweight, 'pull_up'),
          (missing, Motion.pulldown, Equipment.bodyweight, 'pull_up'),
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
          hasActivityFrames(Motion.pulldown, Equipment.bodyweight, 'pull_up'),
          isTrue,
        );
        expect(
          hasActivityFrames(Motion.pulldown, Equipment.machine, 'pull_up'),
          isFalse,
        );
        expect(
          hasActivityFrames(Motion.press, Equipment.bodyweight, 'pull_up'),
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
            equipment: Equipment.bodyweight,
            exerciseId: 'pull_up',
            controls: true,
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final slider = find.byKey(const Key('animation-phase'));
    await t.tap(slider);
    await t.pumpAndSettle();
    expect(t.widget<Slider>(slider).value, .5);
    await t.tap(find.byKey(const Key('animation-play')));
    await t.pump(const Duration(milliseconds: 220));
    expect(
      t.widget<Slider>(slider).value,
      5 / 9,
      reason: 'Play must continue from the selected fifth pose instead of returning to the old timer counter',
    );
    await t.pumpWidget(const SizedBox());
  });
  test('capture actual pull-up renderer hang/top contact sheet', () async {
    if (Platform.environment['RPG_CAPTURE_PULL_UP'] != '1') return;
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
    await File('docs/screenshots/pull-up-frames.png').writeAsBytes(
      (await im.toByteData(format: ui.ImageByteFormat.png))!.buffer
          .asUint8List(),
    );
    im.dispose();
  });
}
