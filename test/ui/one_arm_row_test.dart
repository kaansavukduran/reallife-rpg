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
      );
    }
  });
  CompanionPainter painter(
    String id,
    double phase, {
    String exercise = 'one_arm_row',
    Equipment equipment = Equipment.dumbbell,
  }) => CompanionPainter(
    character: id,
    motion: Motion.row,
    equipment: equipment,
    exerciseId: exercise,
    phase: phase,
    sprites: sheets[id],
  );

  for (final id in companionIds) {
    test('$id has eight complete one-arm rows with fixed bench and planted foot', () async {
      final atlas = sheets[id]!.oneArmRow!;
      final bytes = (await atlas.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!.buffer.asUint8List();
      final poses = <List<int>>[], handles = <Offset>[], benchEnds = <Offset>[];
      final grounds = <double>[], feet = <double>[], tops = <double>[];
      final sources = <Rect>{};
      for (var i = 0; i < 8; i++) {
        final f = painter(id, i / 8).frame!;
        expect(f.image, same(atlas));
        expect(f.clip, 'one_arm_row');
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
        var clear = 0,
            opaque = 0,
            left = atlas.width,
            right = 0,
            top = atlas.height,
            bottom = 0;
        final green = <Offset>[],
            blue = <Offset>[],
            baseRows = <int, int>{},
            footRows = <int, int>{},
            pixels = <int>[];
        for (var y = f.source.top.ceil(); y < f.source.bottom.floor(); y++) {
          pixels.addAll(
            bytes.sublist(
              (y * atlas.width + f.source.left.ceil()) * 4,
              (y * atlas.width + f.source.right.floor()) * 4,
            ),
          );
          for (var x = f.source.left.ceil(); x < f.source.right.floor(); x++) {
            final o = (y * atlas.width + x) * 4, a = bytes[o + 3];
            if (a == 0) clear++;
            if (a <= 200) continue;
            opaque++;
            if (x < left) left = x;
            if (x > right) right = x;
            if (y < top) top = y;
            bottom = y;
            final r = bytes[o], g = bytes[o + 1], b = bytes[o + 2];
            final dx = x - f.source.left, dy = y - f.source.top;
            final channels = [r, g, b]..sort();
            // Both green heads belong to ONE dumbbell joined by its gray handle.
            // Other equipment/character colors are excluded from this mask.
            if (dy > f.source.height * .5 &&
                g > r + 12 &&
                g > b + 8 &&
                g > 90) {
              green.add(Offset(dx, dy));
            }
            // Far bench end stays visible, independent of the moving weight.
            // The lower ROI excludes Aion eyes/gills and wolf's violet marking.
            if (dx > f.source.width * .78 &&
                dy > f.source.height * .6 &&
                r < 90 &&
                b > r + 70 &&
                b > g + 35 &&
                b > 110) {
              blue.add(Offset(dx, dy));
            }
            if (dy > f.source.height * .75 &&
                dx > f.source.width * .65 &&
                channels.last - channels.first < 45) {
              baseRows[y] = (baseRows[y] ?? 0) + 1;
            }
            // Warm planted hindfoot/talons: separate from neutral bench leg.
            if (dy > f.source.height * .75 &&
                dx < f.source.width * .4 &&
                channels.last - channels.first > 35 &&
                r > g + 8 &&
                r > b + 5) {
              footRows[y] = (footRows[y] ?? 0) + 1;
            }
          }
        }
        expect(left - f.source.left, greaterThan(15));
        expect(f.source.right - right, greaterThan(15));
        expect(top - f.source.top, greaterThan(15));
        expect(f.source.bottom - bottom, greaterThan(15));
        expect(clear, greaterThan(10000));
        expect(opaque, greaterThan(7000));
        expect(green.length, greaterThan(1500));
        handles.add(green.reduce((a, b) => a + b) / green.length.toDouble());
        // Compact single prop envelope, not a bilateral/cable/barbell row.
        final gx = green.map((p) => p.dx);
        expect(
          gx.reduce((a, b) => a > b ? a : b) -
              gx.reduce((a, b) => a < b ? a : b),
          lessThan(140),
        );
        expect(blue.length, greaterThan(100));
        benchEnds.add(
          Offset(
            blue.map((p) => p.dx).reduce((a, b) => a > b ? a : b),
            blue.map((p) => p.dy).reduce((a, b) => a < b ? a : b),
          ),
        );
        final base = baseRows.entries
            .where((e) => e.value >= 8)
            .map((e) => e.key)
            .toList();
        final foot = footRows.entries
            .where((e) => e.value >= 8)
            .map((e) => e.key)
            .toList();
        expect(base, isNotEmpty);
        expect(foot, isNotEmpty);
        grounds.add(base.last - f.source.top);
        feet.add(foot.last - f.source.top);
        tops.add(top - f.source.top);
        poses.add(pixels);
      }
      double span(Iterable<double> xs) =>
          xs.reduce((a, b) => a > b ? a : b) -
          xs.reduce((a, b) => a < b ? a : b);
      expect(sources.length, 8);
      for (var i = 1; i <= 4; i++) {
        expect(
          handles[i - 1].dy - handles[i].dy,
          greaterThan(3),
          reason: 'Weight rises each phase toward hip',
        );
      }
      for (var i = 5; i < 8; i++) {
        expect(
          handles[i].dy - handles[i - 1].dy,
          greaterThan(15),
          reason: 'Controlled lowering each return phase',
        );
      }
      expect(handles[0].dy - handles[4].dy, greaterThan(80));
      expect(handles[7].dy - handles[4].dy, greaterThan(70));
      expect(
        handles[0].dx - handles[4].dx,
        greaterThan(15),
        reason: 'Elbow/weight travel back, not a forward raise',
      );
      expect(
        (handles.first - handles.last).distance,
        lessThanOrEqualTo((handles[0] - handles[1]).distance + 2),
        reason: 'No oversized loop closing jump',
      );
      expect(span(benchEnds.map((p) => p.dx)), lessThanOrEqualTo(3));
      expect(span(benchEnds.map((p) => p.dy)), lessThanOrEqualTo(3));
      expect(span(grounds), lessThanOrEqualTo(2));
      expect(span(feet), lessThanOrEqualTo(5));
      expect(span(tops), lessThanOrEqualTo(3));
      for (var i = 1; i < 8; i++) {
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
            config.$2 == 'tr' ? 'Tek kol dambıl kürek' : 'One-arm dumbbell row',
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
            (w) => w is CompanionStage && w.exerciseId == 'one_arm_row',
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
  test('one-arm row rejects wrong pair/missing art and preserves other rows and vertical clips', () {
    for (final id in companionIds) {
      final sprites = sheets[id]!,
          missing = CompanionSprites(sheets[id]!.actions, sheets[id]!.pet);
      for (final entry in [
        (sprites, Motion.row, Equipment.cable, 'one_arm_row'),
        (sprites, Motion.row, Equipment.bodyweight, 'one_arm_row'),
        (sprites, Motion.row, Equipment.machine, 'one_arm_row'),
        (sprites, Motion.pulldown, Equipment.dumbbell, 'one_arm_row'),
        (sprites, Motion.read, Equipment.dumbbell, 'one_arm_row'),
        (sprites, Motion.reverseFly, Equipment.dumbbell, 'one_arm_row'),
        (sprites, Motion.curl, Equipment.dumbbell, 'one_arm_row'),
        (sprites, Motion.row, Equipment.dumbbell, 'custom:row'),
        (sprites, Motion.row, Equipment.barbell, 'barbell_row'),
        (missing, Motion.row, Equipment.dumbbell, 'one_arm_row'),
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
        hasActivityFrames(Motion.row, Equipment.dumbbell, 'one_arm_row'),
        isTrue,
      );
      expect(
        hasActivityFrames(Motion.read, Equipment.dumbbell, 'one_arm_row'),
        isFalse,
      );
      expect(
        hasActivityFrames(Motion.row, Equipment.machine, 'one_arm_row'),
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
            motion: Motion.row,
            equipment: Equipment.dumbbell,
            exerciseId: 'one_arm_row',
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
    'capture actual one-arm row renderer extension/contraction contact sheet',
    () async {
      if (Platform.environment['RPG_CAPTURE_ONE_ARM_ROW'] != '1') return;
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
      await File('docs/screenshots/one-arm-row-frames.png').writeAsBytes(
        (await im.toByteData(format: ui.ImageByteFormat.png))!.buffer
            .asUint8List(),
      );
      im.dispose();
    },
  );
}
