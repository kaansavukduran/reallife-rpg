import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/domain/codec.dart';
import 'package:reallife_rpg/src/domain/nutrition.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';
import 'package:reallife_rpg/src/ui/app.dart';
import 'package:reallife_rpg/src/ui/nutrition_page.dart';

void main() {
  testWidgets(
    'grams slider and kg switch preserve precise amount; recurring combination stays planned',
    (t) async {
      t.view.physicalSize = const Size(1500, 1500);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final store = MemoryTaskStore();
      final c = TaskController(
        store: store,
        clock: () => DateTime(2026, 11, 9, 10),
      );
      await c.load();
      final food = Food(
        id: 'berry',
        tr: 'Yaban mersini',
        en: 'Blueberry',
        source: 'test',
        values: {'energy': 57},
      );
      c.updateLife(
        c.data.life.copyWith(
          nutrition: NutritionData(
            entries: [
              MealEntry(
                id: 'one',
                date: c.today,
                food: food,
                grams: 150.5,
                meal: Meal.breakfast,
              ),
            ],
          ),
        ),
      );
      await t.pumpWidget(
        RealLifeRPGApp(controller: c, initialPage: 'nutrition'),
      );
      await t.pumpAndSettle();
      final context = t.element(find.byType(NutritionPage));
      final opened = editMeal(context, c, food, c.today);
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('meal-grams')), '150.5');
      await t.pump();
      await t.tap(find.text('kg').last);
      await t.pumpAndSettle();
      expect(
        t
            .widget<TextFormField>(find.byKey(const Key('meal-grams')))
            .controller!
            .text,
        '0.1505',
      );
      await t.tap(find.text('g').last);
      await t.pumpAndSettle();
      expect(
        t
            .widget<TextFormField>(find.byKey(const Key('meal-grams')))
            .controller!
            .text,
        '150.5',
      );
      await t.tap(find.byKey(const Key('editor-save')));
      await t.pumpAndSettle();
      expect((await opened)!.grams, 150.5);
      final templates = find.byKey(const Key('meal-templates'));
      await t.dragUntilVisible(
        templates,
        find.byType(ListView).last,
        const Offset(0, -400),
      );
      await t.ensureVisible(templates);
      await t.tap(templates);
      await t.pumpAndSettle();
      final repeat = find.byKey(const Key('repeat-meal-breakfast'));
      await t.ensureVisible(repeat);
      await t.tap(repeat);
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const Key('editor-save')));
      await t.tap(find.byKey(const Key('editor-save')));
      await t.pumpAndSettle();
      final template = c.data.life.nutrition.templates.single;
      expect(template.foods.single.grams, 150.5);
      expect(template.plannedOn(c.today.addDays(1)).single.eaten, false);
      expect(c.data.life.nutrition.entries.single.eaten, false);
      expect(c.profile.totalXp, 0);
      await c.saved;
      expect(
        decodeTaskData(store.saved!)
            .life
            .nutrition
            .templates
            .single
            .foods
            .single
            .grams,
        150.5,
      );
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
