import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/settings.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/domain/codec.dart';
import 'package:reallife_rpg/src/domain/exercise_catalog.dart';
import 'package:reallife_rpg/src/domain/fitness.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';
import 'package:reallife_rpg/src/ui/app.dart';
import 'package:reallife_rpg/src/ui/muscle_map.dart';

void main() {
  test('every muscle has named primary alternatives and an interactive front/back region', () {
    for (final muscle in Muscle.values) {
      expect(
        exerciseCatalog.any((e) => e.primary.contains(muscle)),
        isTrue,
        reason: muscle.name,
      );
      expect(muscleRegions.any((r) => r.muscle == muscle), isTrue);
    }
    expect(
      muscleAt(const Offset(79, 210), const Size(400, 260)),
      Muscle.calves,
    );
    expect(
      muscleAt(const Offset(279, 210), const Size(400, 260)),
      Muscle.calves,
    );
    expect(muscleAt(const Offset(15, 15), const Size(400, 260)), isNull);
    expect(
      exerciseCatalog.firstWhere((e) => e.motion == Motion.curl).kind,
      ExerciseKind.isolation,
    );
    expect(
      exerciseCatalog.firstWhere((e) => e.motion == Motion.press).kind,
      ExerciseKind.compound,
    );
    expect(const WorkoutItem(id: 'new', exerciseId: 'test').sets, 3);
    expect(const WorkoutItem(id: 'new', exerciseId: 'test').reps, 12);
  });
  for (final config in [('tr', false), ('en', false), ('tr', true)]) {
    testWidgets(
      'map + equipment OR filters → 3×12 counters → saved program (${config.$1}, phone=${config.$2})',
      (t) async {
        t.view.physicalSize = config.$2
            ? const Size(390, 844)
            : const Size(1440, 1300);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final store = MemoryTaskStore()
          ..settings = AppSettings(
            languageCode: config.$1,
            uiScale: config.$2 ? 2 : 1,
          );
        final c = TaskController(
          store: store,
          clock: () => DateTime(2026, 11, 9, 10),
        );
        await c.load();
        c.updateLife(
          c.data.life.copyWith(
            fitness: FitnessData(
              plans: [
                TrainingPlan(
                  id: 'plan',
                  title: 'Deneme',
                  days: [TrainingDay(id: 'day', title: 'Gün A', weekdays: [])],
                ),
              ],
            ),
          ),
        );
        await t.pumpWidget(
          RealLifeRPGApp(controller: c, initialPage: 'fitness'),
        );
        await t.pumpAndSettle();
        Future<void> click(Finder f) async {
          for (var i = 0; i < 12 && f.evaluate().isEmpty; i++) {
            final rect = t
                .getRect(find.byType(Scrollable).last)
                .intersect(Offset.zero & t.view.physicalSize);
            await t.dragFrom(rect.center, const Offset(0, -140));
            await t.pumpAndSettle();
          }
          await t.ensureVisible(f);
          await t.pumpAndSettle();
          await t.tap(f);
          await t.pumpAndSettle();
        }

        await click(find.byKey(const Key('fitness-library')));
        final map = find.byKey(const Key('muscle-selector'));
        await Scrollable.ensureVisible(t.element(map), alignment: 1);
        await t.pumpAndSettle();
        if (config.$2) {
          final visible = t
              .getRect(map)
              .intersect(Offset.zero & t.view.physicalSize);
          await t.dragFrom(visible.center, const Offset(450, 0));
          await t.pumpAndSettle();
        }
        final box = t.renderObject<RenderBox>(map);
        final z = math.min(box.size.width / 400, 1.0);
        final point = box.localToGlobal(
          Offset(
            (box.size.width - 400 * z) / 2 + 79 * z,
            210 * box.size.height / 260,
          ),
        );
        expect(point.dx, greaterThanOrEqualTo(0));
        expect(point.dx, lessThan(t.view.physicalSize.width));
        final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: point);
        await mouse.down(point);
        await mouse.up();
        await mouse.removePointer();
        await t.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('muscle-filter-calves')),
          findsOneWidget,
        );
        final alternatives = exerciseCatalog
            .where(
              (e) =>
                  e.primary.contains(Muscle.calves) ||
                  e.secondary.contains(Muscle.calves),
            )
            .toList();
        final equipment = alternatives
            .map((e) => e.equipment)
            .toSet()
            .take(2)
            .toList();
        expect(equipment.length, 2);
        for (final eq in equipment) {
          await click(find.byKey(Key('equipment-${eq.name}')));
        }
        for (final e in exerciseCatalog) {
          final expected =
              alternatives.contains(e) && equipment.contains(e.equipment);
          expect(
            find.text(e.name(config.$1 == 'en')),
            expected ? findsOneWidget : findsNothing,
            reason: e.id,
          );
        }
        expect(c.data.life.fitness.plans.single.days.single.items, isEmpty);
        final exercise = alternatives.firstWhere(
          (e) => equipment.contains(e.equipment) && e.cardio == null,
        );
        await click(find.text(exercise.name(config.$1 == 'en')));
        expect(
          t
              .widget<TextFormField>(find.byKey(const Key('prescription-sets')))
              .controller!
              .text,
          '3',
        );
        expect(
          t
              .widget<TextFormField>(find.byKey(const Key('prescription-reps')))
              .controller!
              .text,
          '12',
        );
        await click(find.byKey(const Key('sets-plus')));
        await click(find.byKey(const Key('reps-minus')));
        await click(find.byKey(const Key('editor-save')));
        await click(find.text('Gün A').last);
        await c.saved;
        final item = c.data.life.fitness.plans.single.days.single.items.single;
        expect(item.sets, 4);
        expect(item.reps, 11);
        expect(item.exerciseId, exercise.id);
        expect(
          decodeTaskData(store.saved!)
              .life
              .fitness
              .plans
              .single
              .days
              .single
              .items
              .single
              .reps,
          11,
        );
        expect(c.data.life.fitness.logs, isEmpty);
        expect(c.data.completions, isEmpty);
        expect(c.profile.totalXp, 0);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        c.dispose();
      },
    );
  }
}
