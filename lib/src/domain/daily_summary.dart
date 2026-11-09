import 'fitness.dart';
import 'local_date.dart';
import 'nutrition.dart';
import 'routine.dart';
import 'task_data.dart';

/// Arithmetic of recorded intake and gross activity estimates, not TDEE or a
/// measured physiological surplus/deficit. Planned meals never become eaten.
class PeriodSummary {
  PeriodSummary(TaskData data, this.from, this.to, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    for (var day = from; !day.isAfter(to); day = day.addDays(1)) {
      foods.addAll(data.life.nutrition.entriesOn(day).where((e) => e.eaten));
      plannedFoods += data.life.nutrition.entriesOn(day).length;
      workouts.addAll(data.life.fitness.logs.where((e) => e.date == day));
      for (final entry in data.life.routines.entries) {
        if (entry.value.kind != RoutineKind.course) continue;
        final task = data.taskById(entry.key);
        if (task == null ||
            (!task.isScheduledOn(day) && !data.isDone(task.id, day))) {
          continue;
        }
        studyPlanned++;
        if (data.isDone(task.id, day)) {
          studyDone++;
        } else if (task.isOverdueOn(day, clock)) {
          studyNotDone++;
        }
      }
    }
  }
  final LocalDate from, to;
  final List<MealEntry> foods = [];
  final List<WorkoutLog> workouts = [];
  int plannedFoods = 0, studyPlanned = 0, studyDone = 0, studyNotDone = 0;
  int get studyPending => studyPlanned - studyDone - studyNotDone;
  double get minutes => workouts.fold(0, (sum, e) => sum + e.minutes);
  NutrientTotal nutrient(String key) => nutrientTotal(foods, key);
  int get energyCovered => workouts.where((e) => e.kcal != null).length;
  double get knownExerciseKcal =>
      workouts.fold(0, (sum, e) => sum + (e.kcal ?? 0));
  double? get recordedDifference =>
      foods.isEmpty ||
          !nutrient('energy').complete ||
          energyCovered != workouts.length
      ? null
      : nutrient('energy').known - knownExerciseKcal;
}
