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
      );
    }
  });
  CompanionPainter painter(
    String id,
    double phase, {
    String exercise = 'barbell_row',
    Equipment equipment = Equipment.barbell,
  }) => CompanionPainter(
    character: id,
    motion: Motion.row,
    equipment: equipment,
    exerciseId: exercise,
    phase: phase,
    sprites: sheets[id],
  );

  for (final id in companionIds) {
    test(
      '$id has eight connected barbell rows with two moving plates and fixed soles',
      () async {
        final atlas = sheets[id]!.barbellRow!;
        final bytes = (await atlas.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!.buffer.asUint8List();
        final leftPlates = <Offset>[], rightPlates = <Offset>[];
        final leftSoles = <Offset>[], rightSoles = <Offset>[];
        final tops = <double>[], poses = <List<int>>[], sources = <Rect>{};
        for (var i = 0; i < 8; i++) {
          final f = painter(id, i / 8).frame!;
          expect(f.image, same(atlas));
          expect(f.clip, 'barbell_row');
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
          var bellyPixels = 0;
          var clear = 0,
              opaque = 0,
              left = atlas.width,
              right = 0,
              top = atlas.height,
              bottom = 0;
          final green = [<Offset>[], <Offset>[]],
              blue = <Offset>[],
              feet = [<Offset>[], <Offset>[]],
              pixels = <int>[];
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
              // Lower-half masks exclude the wolf's turquoise eyes and Aion gills.
              if (dy > f.source.height * .5 &&
                  g > r + 12 &&
                  g > b + 8 &&
                  g > 90) {
                green[dx < f.source.width / 2 ? 0 : 1].add(Offset(dx, dy));
              }
              if (dy > f.source.height * .5 && b > r + 35 && b > g + 10) {
                blue.add(Offset(dx, dy));
              }
              if (id == 'owl' &&
                  dx > f.source.width * .44 &&
                  dx < f.source.width * .48 &&
                  dy > f.source.height * .76 &&
                  dy < f.source.height * .87 &&
                  r > g + 8 &&
                  r > b + 12) {
                bellyPixels++;
              }
              final channels = [r, g, b]..sort();
              if (dy > f.source.height * .83 &&
                  dx > f.source.width * .15 &&
                  dx < f.source.width * .8 &&
                  channels.last - channels.first > 20 &&
                  r > g + 8 &&
                  r > b + 5 &&
                  (id != 'owl' || (r > g + 30 && g > b + 35))) {
                feet[dx < f.source.width / 2 ? 0 : 1].add(Offset(dx, dy));
              }
            }
          }
          expect(left - f.source.left, greaterThan(15));
          expect(f.source.right - right, greaterThan(15));
          expect(top - f.source.top, greaterThan(15));
          expect(f.source.bottom - bottom, greaterThan(15));
          if (id == 'owl') {
            expect(
              bellyPixels,
              greaterThan(350),
              reason: 'Round feathered belly extends low between short talon feet; no long human-like leg columns',
            );
          }
          expect(clear, greaterThan(10000));
          expect(opaque, greaterThan(7000));
          final centers = <Offset>[];
          for (final points in green) {
            expect(points.length, greaterThan(1800));
            centers.add(
              points.reduce((a, b) => a + b) / points.length.toDouble(),
            );
          }
          leftPlates.add(centers[0]);
          rightPlates.add(centers[1]);
          expect(
            centers[1].dx - centers[0].dx,
            greaterThan(200),
            reason: 'Two separate round end plates on one long shaft',
          );
          expect(
            (centers[0].dy - centers[1].dy).abs(),
            lessThan(12),
            reason: 'Ends remain aligned with the same slightly foreshortened rigid bar',
          );
          // Only the steel-blue shaft near the line between plate centers. Hands
          // naturally occlude two sections; this is drawing evidence, not an
          // automatic topology/anatomy certification.
          final shaft = blue.where((p) {
            final t = (p.dx - centers[0].dx) / (centers[1].dx - centers[0].dx);
            final lineY = centers[0].dy + (centers[1].dy - centers[0].dy) * t;
            return p.dx > centers[0].dx + 25 &&
                p.dx < centers[1].dx - 25 &&
                (p.dy - lineY).abs() < 10;
          }).toList();
          expect(shaft.length, greaterThan(200));
          final sx = shaft.map((p) => p.dx);
          expect(
            sx.reduce((a, b) => a > b ? a : b) -
                sx.reduce((a, b) => a < b ? a : b),
            greaterThan(140),
          );
          expect(
            shaft
                .where(
                  (p) =>
                      p.dx > f.source.width * .43 && p.dx < f.source.width * .6,
                )
                .length,
            greaterThan(25),
            reason: 'Visible central shaft between grips, not independent dumbbells',
          );
          for (var side = 0; side < 2; side++) {
            final rows = <int, int>{};
            for (final p in feet[side]) {
              rows[p.dy.floor()] = (rows[p.dy.floor()] ?? 0) + 1;
            }
            final dense =
                rows.entries
                    .where((e) => e.value >= 8)
                    .map((e) => e.key)
                    .toList()
                  ..sort();
            expect(dense, isNotEmpty);
            final sole = feet[side]
                .where((p) => p.dy >= dense.last - 8)
                .toList();
            expect(sole.length, greaterThan(80));
            final anchor = Offset(
              (sole.map((p) => p.dx).reduce((a, b) => a < b ? a : b) +
                      sole.map((p) => p.dx).reduce((a, b) => a > b ? a : b)) /
                  2,
              dense.last.toDouble(),
            );
            (side == 0 ? leftSoles : rightSoles).add(anchor);
          }
          tops.add(top - f.source.top);
          poses.add(pixels);
        }
        double span(Iterable<double> xs) =>
            xs.reduce((a, b) => a > b ? a : b) -
            xs.reduce((a, b) => a < b ? a : b);
        expect(sources.length, 8);
        for (final plate in [leftPlates, rightPlates]) {
          for (var i = 1; i <= 4; i++) {
            expect(
              plate[i - 1].dy - plate[i].dy,
              greaterThan(5),
              reason: 'Each plate rises toward abdomen each pull phase',
            );
          }
          for (var i = 5; i < 8; i++) {
            expect(
              plate[i].dy - plate[i - 1].dy,
              greaterThan(8),
              reason: 'Both ends lower together',
            );
          }
          expect(plate[0].dy - plate[4].dy, greaterThan(65));
          expect(plate[7].dy - plate[4].dy, greaterThan(50));
          expect(
            span(plate.map((p) => p.dx)),
            lessThan(8),
            reason: 'No lateral bar sliding',
          );
          expect(
            (plate.first - plate.last).distance,
            lessThanOrEqualTo((plate[0] - plate[1]).distance + 2),
            reason: 'No oversized loop jump',
          );
        }
        expect(
          span(List.generate(8, (i) => rightPlates[i].dx - leftPlates[i].dx)),
          lessThan(10),
          reason: 'Rigid bar length, shading/perspective tolerances only',
        );
        for (final sole in [leftSoles, rightSoles]) {
          expect(span(sole.map((p) => p.dx)), lessThan(5));
          expect(span(sole.map((p) => p.dy)), lessThanOrEqualTo(3));
        }
        expect(span(tops), lessThanOrEqualTo(3));
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
            config.$2 == 'tr'
                ? 'Barbell eğilerek kürek'
                : 'Bent-over barbell row',
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
            (w) => w is CompanionStage && w.exerciseId == 'barbell_row',
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
  test('barbell row rejects wrong pair/missing art and preserves all other rows and vertical clips', () {
    for (final id in companionIds) {
      final sprites = sheets[id]!,
          missing = CompanionSprites(sheets[id]!.actions, sheets[id]!.pet);
      for (final entry in [
        (sprites, Motion.row, Equipment.cable, 'barbell_row'),
        (sprites, Motion.row, Equipment.dumbbell, 'barbell_row'),
        (sprites, Motion.row, Equipment.machine, 'barbell_row'),
        (sprites, Motion.pulldown, Equipment.barbell, 'barbell_row'),
        (sprites, Motion.read, Equipment.barbell, 'barbell_row'),
        (sprites, Motion.curl, Equipment.barbell, 'barbell_row'),
        (sprites, Motion.reverseFly, Equipment.barbell, 'barbell_row'),
        (sprites, Motion.row, Equipment.barbell, 'custom:row'),
        (sprites, Motion.row, Equipment.band, 'band_row'),
        (missing, Motion.row, Equipment.barbell, 'barbell_row'),
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
        hasActivityFrames(Motion.row, Equipment.barbell, 'barbell_row'),
        isTrue,
      );
      expect(
        hasActivityFrames(Motion.read, Equipment.barbell, 'barbell_row'),
        isFalse,
      );
      expect(
        hasActivityFrames(Motion.row, Equipment.dumbbell, 'barbell_row'),
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
            equipment: Equipment.barbell,
            exerciseId: 'barbell_row',
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
    'capture actual barbell row renderer extension/contraction contact sheet',
    () async {
      if (Platform.environment['RPG_CAPTURE_BARBELL_ROW'] != '1') return;
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
      await File('docs/screenshots/barbell-row-frames.png').writeAsBytes(
        (await im.toByteData(format: ui.ImageByteFormat.png))!.buffer
            .asUint8List(),
      );
      im.dispose();
    },
  );
}
