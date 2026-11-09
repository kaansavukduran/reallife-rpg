import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/nutrition.dart';

class CatalogFood {
  const CatalogFood(
    this.food,
    this.category,
    this.family,
    this.familyTr,
    this.familyEn,
    this.form,
  );
  final Food food;
  final String category, family, familyTr, familyEn, form;
  String familyName(bool english) => english ? familyEn : familyTr;
  static CatalogFood custom(Food food) => CatalogFood(
    food,
    'custom',
    'custom/${food.id}',
    food.tr,
    food.en,
    'other',
  );
}

class FoodCatalog {
  const FoodCatalog(this.entries, this.categories);
  final List<CatalogFood> entries;
  final List<String> categories;
}

Future<FoodCatalog>? _catalog;
FoodCatalog? _ready;
Future<FoodCatalog> loadFoodCatalog() => _ready != null
    ? SynchronousFuture(_ready!)
    : _catalog ??= _load()
          .then((value) {
            _ready = value;
            return value;
          })
          .catchError((Object error) {
            _catalog = null;
            throw error;
          });
Future<FoodCatalog> _load() async {
  final strings = await Future.wait([
    rootBundle.loadString('assets/data/foods.json'),
    rootBundle.loadString('assets/data/food_index.json'),
  ]);
  final foods = (jsonDecode(strings[0]) as List).map(Food.fromJson);
  final index = jsonDecode(strings[1]) as Map<String, dynamic>;
  final families = index['families'] as Map<String, dynamic>,
      items = index['items'] as Map<String, dynamic>;
  return FoodCatalog([
    for (final food in foods)
      (() {
        final item = items[food.id] as List;
        final family = families[item[0]] as Map<String, dynamic>;
        return CatalogFood(
          food,
          family['category'] as String,
          item[0] as String,
          family['tr'] as String,
          family['en'] as String,
          item[1] as String,
        );
      })(),
  ], (index['categories'] as Map<String, dynamic>).keys.toList());
}

Future<List<Food>> loadFoods() async =>
    (await loadFoodCatalog()).entries.map((e) => e.food).toList();
