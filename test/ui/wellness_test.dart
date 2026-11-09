import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/settings.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/domain/codec.dart';
import 'package:reallife_rpg/src/domain/exercise_catalog.dart';
import 'package:reallife_rpg/src/domain/nutrition.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';
import 'package:reallife_rpg/src/ui/app.dart';
import 'package:reallife_rpg/src/ui/companion_stage.dart';
import 'package:reallife_rpg/src/ui/fitness_page.dart';
import 'package:reallife_rpg/src/ui/nutrition_page.dart';

Future<TaskController> start(
  WidgetTester t,
  String page, {
  MemoryTaskStore? store,
  Size size = const Size(1440, 1400),
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  final c = TaskController(
    store: store ?? MemoryTaskStore(),
    clock: () => DateTime(2026, 11, 9, 10),
  );
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
    'adventure starts with Aion and offers other characters without resetting a saved choice',
    (t) async {
      final store = MemoryTaskStore();
      final c = await start(t, 'maceram', store: store);
      expect(c.data.life.companion, 'aion');
      expect(
        t.widget<Text>(find.byKey(const Key('hero-companion-name'))).data,
        'Aion',
      );
      await click(t, find.byKey(const Key('hero-change-companion')));
      await click(t, find.byKey(const Key('choose-wolf')));
      await c.saved;
      await click(t, find.text('Maceram').first);
      expect(
        t.widget<Text>(find.byKey(const Key('hero-companion-name'))).data,
        'Accursed Wise Wolf',
      );
      await t.pumpWidget(const SizedBox());
      c.dispose();
      final reopened = await start(t, 'maceram', store: store);
      expect(reopened.data.life.companion, 'wolf');
      expect(reopened.profile.totalXp, 0);
      expect(
        t
            .widgetList<CompanionStage>(find.byType(CompanionStage))
            .first
            .character,
        'wolf',
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      reopened.dispose();
    },
  );

  testWidgets(
    'reading controls preserve independent text size, font and settings after restart',
    (t) async {
      final store = MemoryTaskStore();
      final c = await start(t, 'ayarlar', store: store);
      final slider = find.byKey(const Key('text-scale-slider'));
      await t.ensureVisible(slider);
      await t.pumpAndSettle();
      await t.drag(slider, const Offset(80, 0));
      await t.pumpAndSettle();
      expect(c.settings.textScale, greaterThan(1));
      expect(c.settings.uiScale, 1);
      await click(t, find.byKey(const Key('reader-font')));
      await click(t, find.text('OpenDyslexic · disleksi dostu').last);
      expect(c.settings.appearance.font, 'dyslexic');
      final context = t.element(find.byKey(const Key('reader-font')));
      expect(
        Theme.of(context).textTheme.bodyMedium!.fontFamily,
        'OpenDyslexic',
      );
      final decoded = AppSettings.decode(store.settings.encode());
      expect(decoded.textScale, c.settings.textScale);
      expect(decoded.appearance.font, 'dyslexic');
      expect(c.profile.totalXp, 0);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  testWidgets(
    'program template creates editable plans, real set logging stays separate and survives reload',
    (t) async {
      final store = MemoryTaskStore();
      final c = await start(t, 'fitness', store: store);
      await click(t, find.byKey(const Key('upper-lower-template')));
      expect(c.data.life.fitness.plans.single.days.length, 2);
      expect(c.data.life.fitness.logs, isEmpty);
      expect(c.profile.totalXp, 0);
      final item = c.data.life.fitness.plans.single.days.first.items.first;
      await click(t, find.byKey(Key('record-${item.id}')));
      await click(t, find.byKey(const Key('editor-save')));
      expect(c.data.life.fitness.logs, isEmpty);
      await click(t, find.byKey(const Key('performed-set-0')));
      await t.enterText(find.byKey(const Key('actual-reps-0')), '11');
      await t.ensureVisible(find.byKey(const Key('actual-minutes')));
      await t.enterText(find.byKey(const Key('actual-minutes')), '10');
      await click(t, find.byKey(const Key('editor-save')));
      await t.pump(const Duration(milliseconds: 400));
      await c.saved;
      expect(c.data.life.fitness.logs.single.sets.single.reps, 11);
      expect(c.data.life.fitness.logs.single.sets.single.kg, isNull);
      expect(c.data.life.fitness.logs.single.prescription.reps, 12);
      expect(c.profile.totalXp, 0);
      expect(c.data.completions, isEmpty);
      final restored = decodeTaskData(store.saved!);
      expect(restored.life.fitness.logs.single.minutes, 10);
      expect(
        restored.life.fitness.plans.single.days.first.items.first.id,
        item.id,
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'nutrition distinguishes planned/eaten and persists actual grams without XP',
    (t) async {
      final c = await start(t, 'nutrition');
      final food = Food(
        id: 'blueberry',
        tr: 'Yaban mersini',
        en: 'Blueberry',
        source: 'test',
        values: {'energy': 50, 'protein': 1},
      );
      MealEntry? entry;
      unawaited(
        showDialog<void>(
          context: t.element(find.byType(NutritionPage)),
          builder: (context) => TextButton(
            onPressed: () async {
              entry = await editMeal(context, c, food, c.today);
            },
            child: const Text('test editor'),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('test editor'));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('meal-grams')), '150,5');
      await click(t, find.byKey(const Key('editor-save')));
      await t.pump(const Duration(milliseconds: 400));
      expect(entry!.eaten, isFalse);
      expect(entry!.grams, 150.5);
      Navigator.of(t.element(find.text('test editor'))).pop();
      await t.pumpAndSettle();
      c.updateLife(
        c.data.life.copyWith(nutrition: NutritionData(entries: [entry!])),
      );
      await t.pumpAndSettle();
      await click(t, find.byKey(Key('eaten-${entry!.id}')));
      await c.saved;
      expect(c.data.life.nutrition.entries.single.eaten, isTrue);
      expect(
        nutrientTotal(c.data.life.nutrition.entries, 'energy').known,
        75.25,
      );
      expect(c.profile.totalXp, 0);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'character selection is shared and persistent; animation phase can be inspected',
    (t) async {
      final store = MemoryTaskStore();
      final c = await start(t, 'companions', store: store);
      await click(t, find.byKey(const Key('choose-wolf')));
      await c.saved;
      expect(c.data.life.companion, 'wolf');
      expect(decodeTaskData(store.saved!).life.companion, 'wolf');
      expect(c.profile.totalXp, 0);
      final stage = t
          .widgetList<CompanionStage>(find.byType(CompanionStage))
          .first;
      expect(stage.character, 'wolf');
      final slider = find.byKey(const Key('animation-phase'));
      await t.ensureVisible(slider);
      await t.drag(slider, const Offset(100, 0));
      await t.pump();
      expect(
        t
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .where((w) => w.painter is CompanionPainter)
            .map((w) => (w.painter! as CompanionPainter).phase)
            .any((p) => p > 0),
        isTrue,
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'device English, unsupported language fallback and explicit Turkish preference',
    (t) async {
      t.binding.platformDispatcher.localesTestValue = const [
        Locale('en', 'GB'),
      ];
      final store = MemoryTaskStore();
      final c = await start(t, 'fitness', store: store);
      expect(find.text('My programs'), findsOneWidget);
      await c.updateSettings(c.settings.copyWith(languageCode: 'tr'));
      await t.pumpAndSettle();
      expect(find.text('Programlarım'), findsOneWidget);
      expect(AppSettings.decode(store.settings.encode()).languageCode, 'tr');
      await c.updateSettings(c.settings.copyWith(languageCode: ''));
      t.binding.platformDispatcher.localesTestValue = const [
        Locale('ja', 'JP'),
      ];
      await t.pumpAndSettle();
      expect(find.text('Programlarım'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  for (final page in ['fitness', 'nutrition', 'companions']) {
    testWidgets(
      '$page works at real 200 percent on a phone with reduced motion',
      (t) async {
        final store = MemoryTaskStore()
          ..settings = const AppSettings(
            uiScale: 2,
            textScale: 1.2,
            languageCode: 'en',
            appearance: Appearance(font: 'dyslexic', reduceMotion: true),
          );
        final c = await start(
          t,
          page,
          store: store,
          size: const Size(390, 844),
        );
        expect(c.settings.uiScale, 2);
        expect(t.takeException(), isNull);
        final scroll = t.widget<SingleChildScrollView>(
          find.byKey(const Key('interface-horizontal-scroll')),
        );
        expect(scroll.controller!.position.maxScrollExtent, greaterThan(300));
        await t.drag(
          find.byKey(const Key('interface-horizontal-scroll')),
          const Offset(-250, 0),
        );
        await t.pumpAndSettle();
        expect(scroll.controller!.offset, greaterThan(0));
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        c.dispose();
      },
    );
  }
  testWidgets(
    'reverse pec deck preview uses selected character and is paused under reduced motion',
    (t) async {
      final c = await start(
        t,
        'fitness',
        store: MemoryTaskStore()
          ..settings = const AppSettings(
            appearance: Appearance(reduceMotion: true),
          ),
      );
      unawaited(
        showExercise(
          t.element(find.byType(FitnessPage)),
          c,
          exerciseCatalog.firstWhere((e) => e.id == 'reverse_pec_deck'),
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.textContaining('Arka omuz', findRichText: true),
        findsWidgets,
      );
      expect(find.byTooltip('Animasyonu oynat'), findsOneWidget);
      final before = t
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .where((w) => w.painter is CompanionPainter)
          .map((w) => (w.painter! as CompanionPainter).phase)
          .first;
      await t.pump(const Duration(seconds: 4));
      final after = t
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .where((w) => w.painter is CompanionPainter)
          .map((w) => (w.painter! as CompanionPainter).phase)
          .first;
      expect(after, before);
      await click(t, find.text('Kapat'));
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
