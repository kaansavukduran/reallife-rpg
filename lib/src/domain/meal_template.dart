import 'local_date.dart';
import 'nutrition.dart';
import 'wellness_values.dart';

class TemplateFood {
  const TemplateFood({
    required this.id,
    required this.food,
    required this.grams,
  });
  final String id;
  final Food food;
  final double grams;
  Map<String, Object?> toJson() => {
    'id': id,
    'food': food.toJson(),
    'grams': grams,
  };
  static TemplateFood fromJson(Object? raw) {
    final j = wellnessObject(raw);
    return TemplateFood(
      id: wellnessString(j, 'id'),
      food: Food.fromJson(j['food']),
      grams: wellnessNumber(j, 'grams', .1, 10000),
    );
  }
}

class MealTemplate {
  MealTemplate({
    required this.id,
    required this.title,
    required this.meal,
    required this.start,
    this.until,
    required List<int> weekdays,
    required List<TemplateFood> foods,
  }) : weekdays = List.unmodifiable(weekdays),
       foods = List.unmodifiable(foods);
  final String id, title;
  final Meal meal;
  final LocalDate start;
  final LocalDate? until;
  final List<int> weekdays;
  final List<TemplateFood> foods;
  bool applies(LocalDate day) =>
      !day.isBefore(start) &&
      (until == null || !day.isAfter(until!)) &&
      weekdays.contains(day.weekday);
  List<MealEntry> plannedOn(LocalDate day) => !applies(day)
      ? []
      : [
          for (final f in foods)
            MealEntry(
              id: 'template:$id:${f.id}:${day.toIso()}',
              date: day,
              food: f.food,
              grams: f.grams,
              meal: meal,
            ),
        ];
  MealTemplate copyWith({
    String? title,
    List<int>? weekdays,
    LocalDate? until,
  }) => MealTemplate(
    id: id,
    title: title ?? this.title,
    meal: meal,
    start: start,
    until: until ?? this.until,
    weekdays: weekdays ?? this.weekdays,
    foods: foods,
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'meal': meal.name,
    'start': start.toIso(),
    'until': until?.toIso(),
    'weekdays': weekdays,
    'foods': foods.map((f) => f.toJson()).toList(),
  };
  static MealTemplate fromJson(Object? raw) {
    final j = wellnessObject(raw);
    final days = wellnessList(j['weekdays']);
    if (days.isEmpty ||
        days.any((d) => d is! int || d < 1 || d > 7) ||
        days.toSet().length != days.length) {
      throw const FormatException('Invalid meal weekdays');
    }
    final foods = wellnessUnique(
      wellnessList(j['foods']).map(TemplateFood.fromJson).toList(),
      (f) => f.id,
    );
    if (foods.isEmpty) throw const FormatException('Empty meal template');
    return MealTemplate(
      id: wellnessString(j, 'id'),
      title: wellnessString(j, 'title'),
      meal: wellnessEnum(Meal.values, j['meal']),
      start: LocalDate.parse(wellnessString(j, 'start')),
      until: j['until'] == null
          ? null
          : LocalDate.parse(wellnessString(j, 'until')),
      weekdays: days.cast<int>(),
      foods: foods,
    );
  }
}
