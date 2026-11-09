import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/settings.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/domain/codec.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';
import 'package:reallife_rpg/src/ui/app.dart';
import 'package:reallife_rpg/src/ui/food_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all official foods retain category/family metadata without changing values', () async {
    final catalog = await loadFoodCatalog();
    expect(catalog.entries.length, 8789);
    expect(catalog.entries.map((e) => e.food.id).toSet().length, 8789);
    expect(
      catalog.entries.every((e) => catalog.categories.contains(e.category)),
      isTrue,
    );
    final berry = catalog.entries.singleWhere(
      (e) => e.food.en == 'Blueberries, raw',
    );
    expect(berry.category, 'fruit');
    expect(berry.familyTr, 'Yaban mersini');
    expect(berry.form, 'raw');
    expect(berry.food.values['energy'], 57);
    final almonds = catalog.entries.firstWhere(
      (e) => e.food.en == 'Nuts, almonds',
    );
    final walnuts = catalog.entries.firstWhere(
      (e) => e.food.en == 'Nuts, walnuts, english',
    );
    expect(almonds.familyTr, 'Badem');
    expect(walnuts.familyTr, 'Ceviz');
    expect(almonds.family, isNot(walnuts.family));
    final whiteBread = catalog.entries.firstWhere(
      (e) => e.family == 'grain/bread, white',
    );
    expect(whiteBread.familyTr, 'Beyaz ekmek');
    expect(
      catalog.entries
          .where((e) => e.category == 'grain')
          .any((e) => e.familyTr.contains('fasulye')),
      isFalse,
    );
    expect(catalog.entries.any((e) => e.category == 'legume'), isTrue);
    expect(catalog.entries.any((e) => e.category == 'vegetable'), isTrue);
  });
  for (final config in [('tr', false), ('en', false), ('tr', true)]) {
    testWidgets(
      'category → food → form is usable and creates only the chosen meal (${config.$1}, phone=${config.$2})',
      (t) async {
        t.view.physicalSize = config.$2
            ? const Size(390, 844)
            : const Size(1440, 1100);
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
        await t.runAsync(loadFoodCatalog);
        await t.pumpWidget(
          RealLifeRPGApp(controller: c, initialPage: 'nutrition'),
        );
        await t.pumpAndSettle();
        Future<void> click(Finder f) async {
          for (var i = 0; i < 12 && f.evaluate().isEmpty; i++) {
            final target = find.byType(Scrollable).last;
            final rect = t
                .getRect(target)
                .intersect(Offset.zero & t.view.physicalSize);
            await t.dragFrom(rect.center, const Offset(0, -140));
            await t.pumpAndSettle();
          }
          await t.ensureVisible(f);
          await t.pumpAndSettle();
          await t.tap(f);
          await t.pumpAndSettle();
        }

        await click(find.byKey(const Key('add-meal')));
        expect(
          t.widget<TextField>(find.byKey(const Key('food-search'))).enabled,
          isFalse,
        );
        expect(
          find.byKey(const Key('food-family-fruit/blueberries')),
          findsNothing,
        );
        await click(find.byKey(const Key('food-category-fruit')));
        expect(
          t.widget<TextField>(find.byKey(const Key('food-search'))).enabled,
          isTrue,
        );
        await t.enterText(find.byKey(const Key('food-search')), 'blueberries');
        await t.pumpAndSettle();
        await click(find.byKey(const Key('food-family-fruit/blueberries')));
        expect(c.data.life.nutrition.entries, isEmpty);
        final catalog = await loadFoodCatalog();
        final berry = catalog.entries.singleWhere(
          (e) => e.food.en == 'Blueberries, raw',
        );
        await click(find.byKey(Key('food-choice-${berry.food.id}')));
        expect(find.byKey(const Key('meal-grams')), findsOneWidget);
        await click(find.byKey(const Key('editor-save')));
        await c.saved;
        final meal = c.data.life.nutrition.entries.single;
        expect(meal.food.id, berry.food.id);
        expect(meal.grams, 100);
        expect(meal.eaten, isTrue);
        expect(
          decodeTaskData(store.saved!)
              .life
              .nutrition
              .entries
              .single
              .food
              .values,
          berry.food.values,
        );
        expect(c.profile.totalXp, 0);
        expect(c.data.completions, isEmpty);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        c.dispose();
      },
    );
  }
}
