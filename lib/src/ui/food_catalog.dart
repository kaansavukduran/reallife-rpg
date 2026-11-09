import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/nutrition.dart';
import '../domain/food_search.dart';

class FoodLabel {
  const FoodLabel(this.title, this.traits);
  final List<String> title;
  final List<List<String>> traits;
  String name(bool english) => title[english ? 1 : 0];
  String details(bool english) =>
      traits.map((t) => t[english ? 1 : 0]).join(' · ');
  static FoodLabel fromJson(Map<String, dynamic> json) => FoodLabel(
    (json['title'] as List).cast<String>(),
    [for (final t in json['traits'] as List) (t as List).cast<String>()],
  );
}

class CatalogFood {
  const CatalogFood(
    this.food,
    this.category,
    this.family,
    this.familyTr,
    this.familyEn,
    this.form, {
    this.part,
    this.partTr,
    this.partEn,
    this.label,
  });
  final Food food;
  final String category, family, familyTr, familyEn, form;
  final String? part, partTr, partEn;
  final FoodLabel? label;
  String familyName(bool english) => english ? familyEn : familyTr;
  String partName(bool english) => (english ? partEn : partTr) ?? '';
  String displayName(bool english) =>
      label?.name(english) ?? food.name(english);
  bool matches(String query) {
    if (foodMatches(food, query)) return true;
    final text = normalizedFoodText(
      [
        food.source,
        familyTr,
        familyEn,
        partTr ?? '',
        partEn ?? '',
        if (label != null) ...[
          label!.name(false),
          label!.name(true),
          label!.details(false),
          label!.details(true),
        ],
      ].join(' '),
    );
    return normalizedFoodText(query.trim())
        .split(RegExp(r'\s+'))
        .every(text.contains);
  }

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
  FoodCatalog(this.entries, this.categories)
    : byId = {for (final entry in entries) entry.food.id: entry};
  final List<CatalogFood> entries;
  final List<String> categories;
  final Map<String, CatalogFood> byId;
}

Future<FoodCatalog>? _catalog;
FoodCatalog? _ready;

/// UI-only. Never replaces the saved Food snapshot or a user's edited name.
FoodLabel? savedFoodLabel(Food food) {
  final entry = _ready?.byId[food.id];
  if (entry == null ||
      entry.food.tr != food.tr ||
      entry.food.en != food.en ||
      entry.food.source != food.source ||
      !mapEquals(entry.food.values, food.values)) {
    return null;
  }
  return entry.label;
}

String foodDisplayName(Food food, bool english) =>
    savedFoodLabel(food)?.name(english) ?? food.name(english);
String foodTraitText(Food food, bool english) =>
    savedFoodLabel(food)?.details(english) ?? '';
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
  final parts = index['parts'] as Map<String, dynamic>? ?? {};
  final labels = index['labels'] as Map<String, dynamic>? ?? {};
  return FoodCatalog([
    for (final food in foods)
      (() {
        final item = items[food.id] as List;
        final family = families[item[0]] as Map<String, dynamic>;
        final part = item.length > 2 ? item[2] as String : null;
        final names = parts[part] as List?;
        return CatalogFood(
          food,
          family['category'] as String,
          item[0] as String,
          family['tr'] as String,
          family['en'] as String,
          item[1] as String,
          part: part,
          partTr: names?[0] as String?,
          partEn: names?[1] as String?,
          label: labels[food.id] is Map<String, dynamic>
              ? FoodLabel.fromJson(labels[food.id] as Map<String, dynamic>)
              : null,
        );
      })(),
  ], (index['categories'] as Map<String, dynamic>).keys.toList());
}

Future<List<Food>> loadFoods() async =>
    (await loadFoodCatalog()).entries.map((e) => e.food).toList();
