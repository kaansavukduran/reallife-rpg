import 'local_date.dart';
import 'wellness_values.dart';
import 'meal_template.dart';

const nutrientKeys = [
  'energy',
  'protein',
  'carb',
  'fat',
  'fiber',
  'sugars',
  'ca',
  'fe',
  'mg',
  'k',
  'na',
  'zn',
  'se',
  'vitc',
  'b12',
  'vitd',
  'folate',
  'vita_rae',
  'vite',
  'vitk',
];
String nutrientUnit(String key) => key == 'energy'
    ? 'kcal'
    : ['protein', 'carb', 'fat', 'fiber', 'sugars'].contains(key)
    ? 'g'
    : ['se', 'b12', 'vitd', 'folate', 'vita_rae', 'vitk'].contains(key)
    ? 'µg'
    : 'mg';

class Food {
  Food({
    required this.id,
    required this.tr,
    required this.en,
    required this.source,
    required Map<String, double> values,
  }) : values = Map.unmodifiable(values);
  final String id, tr, en, source;

  /// Measured or manually entered values per 100 g of this specific food/form.
  final Map<String, double> values;
  String name(bool english) => english ? en : tr;
  Map<String, Object?> toJson() => {
    'id': id,
    'tr': tr,
    'en': en,
    'source': source,
    'values': values,
  };
  static Food fromJson(Object? raw) {
    final j = wellnessObject(raw);
    final values = wellnessObject(j['values']);
    return Food(
      id: wellnessString(j, 'id'),
      tr: wellnessString(j, 'tr'),
      en: wellnessString(j, 'en'),
      source: wellnessString(j, 'source'),
      values: {
        for (final key in values.keys)
          if (nutrientKeys.contains(key))
            key: wellnessNumber(values, key, 0, 1000000),
      },
    );
  }
}

enum Meal { breakfast, lunch, dinner, snack }

class MealEntry {
  const MealEntry({
    required this.id,
    required this.date,
    required this.food,
    required this.grams,
    required this.meal,
    this.eaten = false,
  });
  final String id;
  final LocalDate date;
  // Snapshot prevents later custom food edits changing past nutrition records.
  final Food food;
  final double grams;
  final Meal meal;
  final bool eaten;
  MealEntry copyWith({double? grams, Meal? meal, bool? eaten}) => MealEntry(
    id: id,
    date: date,
    food: food,
    grams: grams ?? this.grams,
    meal: meal ?? this.meal,
    eaten: eaten ?? this.eaten,
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'date': date.toIso(),
    'food': food.toJson(),
    'grams': grams,
    'meal': meal.name,
    'eaten': eaten,
  };
  static MealEntry fromJson(Object? raw) {
    final j = wellnessObject(raw);
    if (j['eaten'] is! bool) throw const FormatException('Invalid meal state');
    return MealEntry(
      id: wellnessString(j, 'id'),
      date: LocalDate.parse(wellnessString(j, 'date')),
      food: Food.fromJson(j['food']),
      grams: wellnessNumber(j, 'grams', .1, 10000),
      meal: wellnessEnum(Meal.values, j['meal']),
      eaten: j['eaten']! as bool,
    );
  }
}

class NutrientTotal {
  const NutrientTotal(this.known, this.covered, this.count);
  final double known;
  final int covered, count;
  bool get complete => count > 0 && covered == count;
}

NutrientTotal nutrientTotal(Iterable<MealEntry> entries, String key) {
  double sum = 0;
  int known = 0, count = 0;
  for (final e in entries) {
    count++;
    final v = e.food.values[key];
    if (v != null) {
      known++;
      sum += v * e.grams / 100;
    }
  }
  return NutrientTotal(sum, known, count);
}

class NutritionData {
  NutritionData({
    Set<String> omitted = const {},
    List<MealTemplate> templates = const [],
    List<Food> custom = const [],
    List<MealEntry> entries = const [],
    Map<String, double> targets = const {},
  }) : omitted = Set.unmodifiable(omitted),
       templates = List.unmodifiable(templates),
       custom = List.unmodifiable(custom),
       entries = List.unmodifiable(entries),
       targets = Map.unmodifiable(targets);
  final Set<String> omitted;
  final List<Food> custom;
  final List<MealTemplate> templates;
  final List<MealEntry> entries;
  final Map<String, double> targets;
  NutritionData copyWith({
    Set<String>? omitted,
    List<MealTemplate>? templates,
    List<Food>? custom,
    List<MealEntry>? entries,
    Map<String, double>? targets,
  }) => NutritionData(
    omitted: omitted ?? this.omitted,
    templates: templates ?? this.templates,
    custom: custom ?? this.custom,
    entries: entries ?? this.entries,
    targets: targets ?? this.targets,
  );
  List<MealEntry> entriesOn(LocalDate date) {
    final actual = entries.where((e) => e.date == date).toList();
    final ids = actual.map((e) => e.id).toSet();
    return [
      ...actual,
      for (final t in templates)
        for (final planned in t.plannedOn(date))
          if (!ids.contains(planned.id) && !omitted.contains(planned.id))
            planned,
    ];
  }

  Map<String, Object?> toJson() => {
    'omitted': omitted.toList()..sort(),
    'templates': templates.map((e) => e.toJson()).toList(),
    'custom': custom.map((e) => e.toJson()).toList(),
    'entries': entries.map((e) => e.toJson()).toList(),
    'targets': targets,
  };
  static NutritionData fromJson(Object? raw) {
    if (raw == null) return NutritionData();
    final j = wellnessObject(raw);
    final t = wellnessObject(j['targets']);
    final omitted = wellnessList(j['omitted'] ?? const []);
    if (omitted.any((id) => id is! String || !id.startsWith('template:'))) {
      throw const FormatException('Invalid omitted meal');
    }
    return NutritionData(
      omitted: omitted.cast<String>().toSet(),
      templates: wellnessUnique(
        wellnessList(j['templates'] ?? const [])
            .map(MealTemplate.fromJson)
            .toList(),
        (t) => t.id,
      ),
      custom: wellnessUnique(
        wellnessList(j['custom']).map(Food.fromJson).toList(),
        (e) => e.id,
      ),
      entries: wellnessUnique(
        wellnessList(j['entries']).map(MealEntry.fromJson).toList(),
        (e) => e.id,
      ),
      targets: {
        for (final k in t.keys)
          if (nutrientKeys.contains(k)) k: wellnessNumber(t, k, 0, 1000000),
      },
    );
  }
}
