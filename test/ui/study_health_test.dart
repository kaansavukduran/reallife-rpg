import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/settings.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/domain/codec.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';
import 'package:reallife_rpg/src/ui/app.dart';

Future<TaskController> start(
  WidgetTester t,
  String page, {
  Size size = const Size(1440, 1300),
  AppSettings settings = const AppSettings(),
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final store = MemoryTaskStore()..settings = settings;
  final c = TaskController(store: store, clock: () => DateTime(2026, 11, 9));
  await c.load();
  await t.pumpWidget(RealLifeRPGApp(controller: c, initialPage: page));
  await t.pumpAndSettle();
  return c;
}

Future<void> click(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'OpenDyslexic is visible in the existing font style choices and persists',
    (t) async {
      final c = await start(t, 'ayarlar');
      final chip = find.byKey(const Key('font-dyslexic'));
      await t.dragUntilVisible(
        chip,
        find.byType(ListView).last,
        const Offset(0, -300),
      );
      await click(t, chip);
      expect(c.settings.appearance.font, 'dyslexic');
      expect(
        AppSettings.decode((c.store as MemoryTaskStore).settings.encode())
            .appearance
            .font,
        'dyslexic',
      );
      expect(c.profile.totalXp, 0);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'create course with unit count and optional names; only marked units count',
    (t) async {
      final c = await start(t, 'courses');
      await click(t, find.byKey(const Key('add-course')));
      await t.enterText(find.byKey(const Key('course-name')), 'Biyoloji');
      await t.enterText(find.byKey(const Key('course-unit-count')), '3');
      await t.pumpAndSettle();
      await click(t, find.byKey(const Key('course-unit-names')));
      await t.enterText(find.byKey(const Key('course-unit-name-0')), 'Hücre');
      await click(t, find.byKey(const Key('editor-save')));
      final course = c.data.life.study.courses.single;
      expect(course.units.length, 3);
      expect(course.units.first.title, 'Hücre');
      expect(course.units[1].title, '');
      expect(course.completed, 0);
      await click(t, find.byKey(Key('unit-${course.units.first.id}')));
      await c.saved;
      expect(c.data.life.study.courses.single.completed, 1);
      expect(c.profile.totalXp, 0);
      expect(c.data.completions, isEmpty);
      await t.tap(find.byKey(Key('unit-${course.units[0].id}')));
      await t.tap(find.byKey(Key('unit-${course.units[1].id}')));
      await t.pumpAndSettle();
      expect(c.data.life.study.courses.single.completed, 1);
      expect(c.data.life.study.courses.single.units[1].completed, isTrue);
      await c.saved;
      final restored = decodeTaskData((c.store as MemoryTaskStore).saved!);
      expect(restored.life.study.courses.single.completed, 1);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'invalid unit counts keep form and data; cancelled course adds nothing',
    (t) async {
      final c = await start(t, 'courses');
      await click(t, find.byKey(const Key('add-course')));
      await t.enterText(find.byKey(const Key('course-name')), 'Math');
      for (final value in ['0', '201', '2.5', '']) {
        await t.enterText(find.byKey(const Key('course-unit-count')), value);
        await click(t, find.byKey(const Key('editor-save')));
        expect(c.data.life.study.courses, isEmpty);
      }
      await click(t, find.text('Vazgeç'));
      expect(c.data.life.study.courses, isEmpty);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'height and weight with opt-in adult BMI save; unknown height does not classify',
    (t) async {
      final c = await start(t, 'saglik');
      expect(find.byKey(const Key('bmi-range')), findsNothing);
      await click(t, find.byKey(const Key('edit-body-measurements')));
      await t.enterText(find.byKey(const Key('body-height')), '175');
      await t.enterText(find.byKey(const Key('body-weight')), '70');
      await click(t, find.byKey(const Key('adult-reference')));
      await click(t, find.byKey(const Key('editor-save')));
      expect(c.data.life.measurements.heightCm, 175);
      expect(c.data.life.fitness.bodyKg, 70);
      expect(find.text('Normal aralık (yetişkin BKİ)'), findsOneWidget);
      expect(c.profile.totalXp, 0);
      await click(t, find.byKey(const Key('edit-body-measurements')));
      await t.enterText(find.byKey(const Key('body-height')), '');
      await click(t, find.byKey(const Key('editor-save')));
      expect(c.data.life.measurements.heightCm, isNull);
      expect(c.data.life.fitness.bodyKg, 70);
      expect(find.byKey(const Key('bmi-range')), findsNothing);
      await c.saved;
      expect(
        decodeTaskData((c.store as MemoryTaskStore).saved!)
            .life
            .measurements
            .heightCm,
        isNull,
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  for (final language in ['tr', 'en']) {
    for (final page in ['courses', 'saglik']) {
      testWidgets(
        '$page is readable in $language at real 200 percent on a phone',
        (t) async {
          final c = await start(
            t,
            page,
            size: const Size(390, 844),
            settings: AppSettings(
              languageCode: language,
              uiScale: 2,
              appearance: const Appearance(
                font: 'dyslexic',
                reduceMotion: true,
              ),
            ),
          );
          expect(t.takeException(), isNull);
          expect(c.settings.uiScale, 2);
          expect(c.profile.totalXp, 0);
          await t.pumpWidget(const SizedBox());
          c.dispose();
        },
      );
    }
  }
}
