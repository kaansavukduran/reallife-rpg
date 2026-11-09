import 'local_date.dart';
import 'routine.dart';
import 'task_data.dart';

enum ReviewScope { all, training, study }

/// The score is deterministic. Randomness belongs only to supportive copy.
class WeeklyReview {
  WeeklyReview(
    TaskData data,
    LocalDate selected,
    DateTime now, {
    ReviewScope scope = ReviewScope.all,
  }) : from = selected.addDays(1 - selected.weekday) {
    for (
      var date = from;
      !date.isAfter(from.addDays(6));
      date = date.addDays(1)
    ) {
      for (final task in data.tasksOn(date)) {
        final binding = data.life.routines[task.id];
        if (scope == ReviewScope.training &&
            binding?.kind != RoutineKind.training) {
          continue;
        }
        if (scope == ReviewScope.study && binding?.kind != RoutineKind.course) {
          continue;
        }
        if (date.isAfter(LocalDate.of(now))) continue;
        if (data.isDone(task.id, date)) {
          done++;
        } else if (task.isOverdueOn(date, now)) {
          missed++;
        } else {
          pending++;
        }
      }
    }
  }
  final LocalDate from;
  int done = 0, missed = 0, pending = 0;
  int get eligible => done + missed;
  int? get score => eligible == 0 ? null : (done / eligible * 10).round();
  int? get band => score?.clamp(1, 10);
  String get mood => score == null || score! >= 4 && score! <= 6
      ? 'neutral'
      : score! >= 7
      ? 'happy'
      : 'sad';
}
