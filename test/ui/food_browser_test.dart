import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/settings.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/domain/codec.dart';
import 'package:reallife_rpg/src/domain/nutrition.dart';
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
  test(
    'meat cuts keep whole legs, specific subcuts and mixed cuts distinct',
    () async {
      final catalog = await loadFoodCatalog();
      CatalogFood entry(String text) =>
          catalog.entries.firstWhere((e) => e.food.en == text);
      expect(
        entry(
          'Lamb, domestic, leg, whole (shank and sirloin), separable lean and fat, trimmed to 1/4" fat, choice, raw',
        ).part,
        'leg',
      );
      expect(
        entry('Pork, fresh, loin, tenderloin, separable lean only, raw').part,
        'tenderloin',
      );
      expect(
        entry('Beef, carcass, separable lean and fat, choice, raw').part,
        'mixed',
      );
      expect(
        entry('Chicken, broilers or fryers, dark meat, thigh, meat only, raw')
            .part,
        'thigh',
      );
      final grouped = catalog.entries.where((e) => e.part != null).toList();
      expect(grouped.length, 1976);
      expect(grouped.map((e) => e.family).toSet().length, 6);
      expect(
        grouped.every((e) => e.partTr!.isNotEmpty && e.partEn!.isNotEmpty),
        isTrue,
      );
      expect(
        grouped.firstWhere((e) => e.family == 'meat/beef').familyTr,
        'Sığır eti',
      );
      expect(
        grouped.firstWhere((e) => e.family == 'meat/veal').familyTr,
        'Buzağı eti',
      );
      for (final family in grouped.map((e) => e.family).toSet()) {
        expect(
          catalog.entries
              .where((e) => e.family == family)
              .every((e) => e.part != null),
          isTrue,
        );
      }
    },
  );
  test(
    'short labels preserve canonical snapshots, user edits and exact variants',
    () async {
      final catalog = await loadFoodCatalog();
      final labeled = catalog.entries.where((e) => e.label != null).toList();
      expect(labeled.length, 1976);
      expect(
        labeled.every((e) => e.part != null && e.label!.title.length == 2),
        isTrue,
      );
      final meat = catalog.byId['usda:13047']!;
      expect(meat.displayName(false), 'Sığır eti · Kıyma · Çiğ');
      expect(meat.displayName(true), 'Beef · Ground meat · Raw');
      expect(meat.matches('otla çiğ kıyma'), isTrue);
      expect(meat.matches('NDB 13047'), isTrue);
      expect(meat.matches('kemiksiz'), isFalse);
      final snapshot = Food.fromJson(meat.food.toJson());
      expect(foodDisplayName(snapshot, false), meat.displayName(false));
      expect(snapshot.toJson(), meat.food.toJson());
      for (final changed in [
        Food(
          id: snapshot.id,
          tr: 'Benim besinim',
          en: snapshot.en,
          source: snapshot.source,
          values: snapshot.values,
        ),
        Food(
          id: snapshot.id,
          tr: snapshot.tr,
          en: snapshot.en,
          source: 'Kullanıcının kaynağı',
          values: snapshot.values,
        ),
        Food(
          id: snapshot.id,
          tr: snapshot.tr,
          en: snapshot.en,
          source: snapshot.source,
          values: {...snapshot.values, 'energy': 999},
        ),
        Food(
          id: 'custom:meat',
          tr: 'Özel et',
          en: 'Custom meat',
          source: snapshot.source,
          values: snapshot.values,
        ),
      ]) {
        expect(savedFoodLabel(changed), isNull);
        expect(foodDisplayName(changed, false), changed.tr);
        expect(foodTraitText(changed, false), isEmpty);
      }
      final boneless = labeled.firstWhere(
        (e) => e.food.en.contains('boneless') && e.food.en.contains('raw'),
      );
      expect(boneless.matches('kemiksiz çiğ'), isTrue);
      expect(boneless.label!.details(false), contains('Kemiksiz'));
      expect(boneless.food.en, contains('boneless'));
      final fat = labeled.firstWhere(
        (e) => e.food.en.contains('95% lean meat / 5% fat'),
      );
      expect(fat.label!.details(false), contains('%5 yağ'));
      // Equal short titles never collapse different source records.
      final sameTitle = labeled.where(
        (e) => e.displayName(false) == fat.displayName(false),
      );
      expect(sameTitle.length, greaterThan(1));
      expect(sameTitle.map((e) => e.food.id).toSet().length, sameTitle.length);
    },
  );
  for (final config in [
    ('tr', false),
    ('en', false),
    ('tr', true),
    ('en', true),
  ]) {
    for (final meat in [false, true]) {
      testWidgets(
        'category → food → ${meat ? 'cut → ' : ''}form saves chosen meal (${config.$1}, phone=${config.$2})',
        (t) async {
          final semantics = t.ensureSemantics();
          try {
            t.view.physicalSize = config.$2
                ? const Size(390, 844)
                : const Size(1440, 1100);
            t.view.devicePixelRatio = 1;
            addTearDown(t.view.reset);
            final store = MemoryTaskStore()
              ..settings = AppSettings(
                languageCode: config.$1,
                uiScale: config.$2 ? 2 : 1,
                appearance: Appearance(font: config.$2 ? 'dyslexic' : 'system'),
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
              for (var i = 0; i < 40 && f.evaluate().isEmpty; i++) {
                // TextField has its own horizontal Scrollable. Drag the actual
                // vertical food list when a category is below the phone fold.
                final target = find
                    .byWidgetPredicate(
                      (w) =>
                          w is Scrollable &&
                          w.axisDirection == AxisDirection.down,
                    )
                    .last;
                final rect = t
                    .getRect(target)
                    .intersect(Offset.zero & t.view.physicalSize);
                await t.dragFrom(rect.center, const Offset(0, -140));
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

            await click(find.byKey(const Key('add-meal')));
            expect(
              t.widget<TextField>(find.byKey(const Key('food-search'))).enabled,
              isFalse,
            );
            expect(
              find.byKey(const Key('food-family-fruit/blueberries')),
              findsNothing,
            );
            await click(
              find.byKey(Key('food-category-${meat ? 'meat' : 'fruit'}')),
            );
            expect(
              t.widget<TextField>(find.byKey(const Key('food-search'))).enabled,
              isTrue,
            );
            await t.enterText(
              find.byKey(const Key('food-search')),
              meat ? 'kıyma' : 'blueberries',
            );
            await t.pumpAndSettle();
            await click(
              find.byKey(
                Key('food-family-${meat ? 'meat/beef' : 'fruit/blueberries'}'),
              ),
            );
            if (meat) {
              // A family never dumps its source variants before a cut is chosen.
              expect(find.byKey(const Key('food-form-raw')), findsNothing);
              await click(find.byKey(const Key('food-part-ground')));
              await click(
                find.byTooltip(
                  config.$1 == 'tr'
                      ? 'Et parçalarına dön'
                      : 'Back to meat cuts',
                ),
              );
              expect(find.byKey(const Key('food-form-raw')), findsNothing);
              await click(find.byKey(const Key('food-part-ground')));
              await click(find.byKey(const Key('food-form-raw')));
            }
            expect(c.data.life.nutrition.entries, isEmpty);
            final catalog = await loadFoodCatalog();
            final berry = catalog.entries.firstWhere(
              (e) => meat
                  ? e.family == 'meat/beef' &&
                        e.part == 'ground' &&
                        e.form == 'raw'
                  : e.food.en == 'Blueberries, raw',
            );
            await click(find.byKey(Key('food-choice-${berry.food.id}')));
            expect(find.byKey(const Key('meal-grams')), findsOneWidget);
            expect(
              find.text(berry.displayName(config.$1 == 'en')),
              findsOneWidget,
            );
            if (meat) {
              await click(
                find.text(
                  config.$1 == 'tr' ? 'Kaynak ayrıntısı' : 'Source details',
                ),
              );
              expect(
                find.text('${berry.food.en}\n${berry.food.source}'),
                findsOneWidget,
              );
              expect(
                find.bySemanticsLabel('${berry.food.en}\n${berry.food.source}'),
                findsOneWidget,
              );
            }
            await click(find.byKey(const Key('editor-save')));
            await c.saved;
            final meal = c.data.life.nutrition.entries.single;
            expect(meal.food.id, berry.food.id);
            expect(meal.grams, 100);
            expect(meal.eaten, isTrue);
            expect(meal.food.toJson(), berry.food.toJson());
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
            final reopened = TaskController(
              store: store,
              clock: () => DateTime(2026, 11, 9, 10),
            );
            await reopened.load();
            expect(
              reopened.data.life.nutrition.entries.single.food.toJson(),
              berry.food.toJson(),
            );
            expect(
              foodDisplayName(
                reopened.data.life.nutrition.entries.single.food,
                config.$1 == 'en',
              ),
              berry.displayName(config.$1 == 'en'),
            );
            reopened.dispose();
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox());
            c.dispose();
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
}
