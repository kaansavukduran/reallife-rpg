import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/domain/codec.dart';
import 'package:reallife_rpg/src/domain/exercise_catalog.dart';
import 'package:reallife_rpg/src/domain/fitness.dart';
import 'package:reallife_rpg/src/domain/life.dart';
import 'package:reallife_rpg/src/domain/local_date.dart';
import 'package:reallife_rpg/src/domain/nutrition.dart';
import 'package:reallife_rpg/src/domain/task_data.dart';

void main() {
  final date = LocalDate(2026, 11, 9);
  final e = exerciseCatalog.firstWhere((e) => e.id == 'reverse_pec_deck');
  const item = WorkoutItem(
    id: 'item',
    exerciseId: 'reverse_pec_deck',
    sets: 3,
    reps: 12,
  );
  final food = Food(
    id: 'test',
    tr: 'Deneme',
    en: 'Test',
    source: 'manual',
    values: {'energy': 100, 'protein': 5, 'fat': 0},
  );
  WorkoutLog log() => WorkoutLog(
    id: 'log',
    date: date,
    exercise: e,
    prescription: item,
    planTitle: 'Plan',
    dayTitle: 'Üst',
    sets: [const PerformedSet(11, 15)],
    minutes: 10,
    bodyKg: 80,
    met: 4,
  );

  test(
    'catalog covers each muscle and requested machine; definitions roundtrip',
    () {
      expect(exerciseCatalog.length, 76);
      expect(exerciseCatalog.map((e) => e.id).toSet().length, 76);
      for (final m in Muscle.values) {
        expect(
          exerciseCatalog.any(
            (e) => e.primary.contains(m) || e.secondary.contains(m),
          ),
          isTrue,
          reason: m.name,
        );
      }
      expect(e.primary, [Muscle.rearDelts]);
      expect(e.secondary, contains(Muscle.upperBack));
      expect(e.motion, Motion.reverseFly);
      expect(
        exerciseCatalog
            .where((e) => e.cardio != null)
            .map((e) => e.cardio)
            .toSet()
            .length,
        Cardio.values.length,
      );
      for (final e in exerciseCatalog) {
        expect(Exercise.fromJson(e.toJson()).toJson(), e.toJson());
      }
    },
  );
  test('prescriptions and character choices do not create completed work', () {
    final life = LifeData(
      companion: 'wolf',
      fitness: FitnessData(
        plans: [
          TrainingPlan(
            id: 'plan',
            title: 'Plan',
            days: [
              TrainingDay(
                id: 'upper',
                title: 'Üst',
                weekdays: [2, 5],
                items: [item],
              ),
            ],
          ),
        ],
      ),
    );
    expect(life.fitness.logs, isEmpty);
    expect(TaskData(life: life).completions, isEmpty);
    expect(
      life
          .copyWith(companion: 'owl')
          .fitness
          .plans
          .single
          .days
          .single
          .items
          .single
          .reps,
      12,
    );
  });
  test('energy is gross MET arithmetic and walking equation uses percent as fraction', () {
    expect(estimatedCalories(minutes: 30, bodyKg: 80, met: 4), 168);
    final met = walkingMet(Cardio.treadmill, 6, 10)!;
    expect(met, closeTo(9, 1e-9));
    expect(estimatedCalories(minutes: 30, bodyKg: 80, met: met), 378);
    expect(walkingMet(Cardio.airWalk, 6, 10), isNull);
    expect(walkingMet(Cardio.bicycle, 6, 10), isNull);
    expect(walkingMet(Cardio.treadmill, 8, 0), isNull);
    expect(walkingMet(Cardio.walking, 4, null), isNull);
    expect(walkingMet(Cardio.walking, 4, -2), isNull);
    expect(
      () => estimatedCalories(minutes: double.nan, bodyKg: 80, met: 4),
      throwsArgumentError,
    );
  });
  test(
    'unknown body weight gives unknown calories, history retains snapshot',
    () {
      final record = log();
      final f = FitnessData(logs: [record], bodyKg: 80);
      final changed = f.copyWith(bodyKg: 60);
      expect(changed.logs.single.bodyKg, 80);
      expect(changed.logs.single.kcal, 56);
      final raw = record.toJson()..['body_kg'] = null;
      expect(WorkoutLog.fromJson(raw).kcal, isNull);
      expect(record.sets.single.reps, 11);
      expect(record.prescription.reps, 12);
    },
  );
  test('nutrition arithmetic scales grams; missing and measured zero stay distinct', () {
    final a = MealEntry(
      id: 'a',
      date: date,
      food: food,
      grams: 250,
      meal: Meal.lunch,
      eaten: true,
    );
    final b = MealEntry(
      id: 'b',
      date: date,
      food: Food(id: 'unknown', tr: '?', en: '?', source: 'manual', values: {}),
      grams: 100,
      meal: Meal.lunch,
    );
    expect(nutrientTotal([a], 'energy').known, 250);
    expect(nutrientTotal([a], 'protein').known, 12.5);
    expect(nutrientTotal([a], 'fat').complete, isTrue);
    expect(nutrientTotal([a], 'fat').known, 0);
    expect(nutrientTotal([a], 'fiber').covered, 0);
    expect(nutrientTotal([a], 'fiber').complete, isFalse);
    expect(nutrientTotal([a, b], 'energy').known, 250);
    expect(nutrientTotal([a, b], 'energy').complete, isFalse);
    expect(nutrientTotal([a, b].where((e) => e.eaten), 'energy').count, 1);
    expect(nutrientTotal([], 'energy').complete, isFalse);
  });
  test(
    'all records survive JSON export, edits, unrelated life copy and reload',
    () {
      final data = TaskData(
        life: LifeData(
          companion: 'sheep',
          fitness: FitnessData(
            logs: [log()],
            plans: [
              TrainingPlan(
                id: 'p',
                title: 'Plan',
                days: [
                  TrainingDay(
                    id: 'd',
                    title: 'Üst',
                    weekdays: [1, 3],
                    items: [item],
                  ),
                ],
              ),
            ],
          ),
          nutrition: NutritionData(
            custom: [food],
            entries: [
              MealEntry(
                id: 'meal',
                date: date,
                food: food,
                grams: 80,
                meal: Meal.snack,
                eaten: true,
              ),
            ],
            targets: {'protein': 90},
          ),
        ),
      );
      final json = encodeTaskData(data, savedAt: DateTime.utc(2026, 11, 9));
      expect(jsonDecode(json)['schema_version'], 4);
      final restored = decodeTaskData(json)
          .copyWith(life: data.life.copyWith(name: 'İpek'));
      expect(restored.life.fitness.logs.single.toJson(), log().toJson());
      expect(restored.life.nutrition.entries.single.food.values['energy'], 100);
      expect(restored.life.nutrition.targets['protein'], 90);
      expect(restored.life.companion, 'sheep');
      expect(
        () =>
            restored.life.fitness.plans.add(TrainingPlan(id: 'x', title: 'x')),
        throwsUnsupportedError,
      );
    },
  );
  test(
    'schema 3 life 1 migrates without invented records; future schema rejected',
    () {
      final raw = jsonDecode(
        encodeTaskData(TaskData(), savedAt: DateTime.utc(2026)),
      ) as Map<String, dynamic>;
      raw['schema_version'] = 3;
      final life = raw['life'] as Map<String, dynamic>;
      life['version'] = 1;
      life.remove('fitness');
      life.remove('nutrition');
      final migrated = decodeTaskData(jsonEncode(raw));
      expect(migrated.life.fitness.logs, isEmpty);
      expect(migrated.life.nutrition.entries, isEmpty);
      raw['schema_version'] = schemaVersion + 1;
      expect(
        () => decodeTaskData(jsonEncode(raw)),
        throwsA(isA<NewerSchemaException>()),
      );
    },
  );
  test('corrupt wellness fields and duplicate IDs reject the whole import', () {
    final raw = jsonDecode(
      encodeTaskData(
        TaskData(
          life: LifeData(fitness: FitnessData(logs: [log()])),
        ),
        savedAt: DateTime.utc(2026),
      ),
    ) as Map<String, dynamic>;
    final life = raw['life'] as Map<String, dynamic>;
    final fitness = life['fitness'] as Map<String, dynamic>;
    (fitness['logs'] as List).add((fitness['logs'] as List).first);
    expect(() => decodeTaskData(jsonEncode(raw)), throwsFormatException);
    fitness['logs'] = [log().toJson()..['minutes'] = -1];
    expect(() => decodeTaskData(jsonEncode(raw)), throwsFormatException);
    fitness['logs'] = [log().toJson()..['sets'] = []];
    expect(() => decodeTaskData(jsonEncode(raw)), throwsFormatException);
    life.remove('nutrition');
    expect(() => decodeTaskData(jsonEncode(raw)), throwsFormatException);
  });
}
