import 'local_date.dart';
import 'wellness_values.dart';

enum Muscle {
  chest,
  frontDelts,
  sideDelts,
  rearDelts,
  lats,
  upperBack,
  traps,
  biceps,
  triceps,
  forearms,
  abs,
  obliques,
  lowerBack,
  glutes,
  quads,
  hamstrings,
  calves,
  adductors,
  abductors,
}

enum Equipment { machine, cable, dumbbell, barbell, bodyweight, band, cardio }

enum Motion {
  legPress,
  lyingLegCurl,
  hipThrust,
  backExtension,
  frontRaise,
  overheadTriceps,
  sidePlank,
  legRaise,
  squat,
  hinge,
  lunge,
  calf,
  curl,
  pushdown,
  press,
  overhead,
  row,
  pulldown,
  fly,
  reverseFly,
  lateralRaise,
  crunch,
  plank,
  legCurl,
  legExtension,
  hipAbduction,
  hipAdduction,
  shrug,
  wrist,
  walk,
  cycle,
  elliptical,
  rowing,
  stairs,
  eat,
  read,
  idle,
}

enum Cardio {
  walking,
  treadmill,
  bicycle,
  airWalk,
  elliptical,
  rowing,
  stairs,
  running,
}

class Exercise {
  Exercise({
    required this.id,
    required this.tr,
    required this.en,
    required this.equipment,
    required this.motion,
    required List<Muscle> primary,
    List<Muscle> secondary = const [],
    this.cueTr = '',
    this.cueEn = '',
    this.custom = false,
    this.cardio,
  }) : primary = List.unmodifiable(primary),
       secondary = List.unmodifiable(secondary);
  final String id, tr, en, cueTr, cueEn;
  final Equipment equipment;
  final Motion motion;
  final List<Muscle> primary, secondary;
  final bool custom;
  final Cardio? cardio;
  String name(bool english) => english ? en : tr;
  Map<String, Object?> toJson() => {
    'id': id,
    'tr': tr,
    'en': en,
    'equipment': equipment.name,
    'motion': motion.name,
    'primary': primary.map((e) => e.name).toList(),
    'secondary': secondary.map((e) => e.name).toList(),
    'cue_tr': cueTr,
    'cue_en': cueEn,
    'custom': custom,
    'cardio': cardio?.name,
  };
  static Exercise fromJson(Object? raw) {
    final j = wellnessObject(raw);
    final p = wellnessList(j['primary'])
        .map((e) => wellnessEnum(Muscle.values, e))
        .toList();
    final s = wellnessList(j['secondary'])
        .map((e) => wellnessEnum(Muscle.values, e))
        .toList();
    if (j['custom'] is! bool ||
        p.toSet().length != p.length ||
        s.toSet().length != s.length ||
        p.any(s.contains)) {
      throw const FormatException('Invalid muscle roles');
    }
    return Exercise(
      id: wellnessString(j, 'id'),
      tr: wellnessString(j, 'tr'),
      en: wellnessString(j, 'en'),
      equipment: wellnessEnum(Equipment.values, j['equipment']),
      motion: wellnessEnum(Motion.values, j['motion']),
      primary: p,
      secondary: s,
      cueTr: wellnessString(j, 'cue_tr'),
      cueEn: wellnessString(j, 'cue_en'),
      custom: j['custom']! as bool,
      cardio: j['cardio'] == null
          ? null
          : wellnessEnum(Cardio.values, j['cardio']),
    );
  }
}

/// Prescription is not a performance record. Each performed set is confirmed separately.
class WorkoutItem {
  const WorkoutItem({
    required this.id,
    required this.exerciseId,
    this.sets = 3,
    this.reps = 10,
    this.kg,
    this.minutes = 20,
    this.speed,
    this.incline,
    this.met = 4,
    this.rest = 90,
    this.note = '',
  });
  final String id, exerciseId, note;
  final int sets, reps, rest;
  final double? kg, speed, incline;
  final double minutes, met;
  Map<String, Object?> toJson() => {
    'id': id,
    'exercise': exerciseId,
    'sets': sets,
    'reps': reps,
    'kg': kg,
    'minutes': minutes,
    'speed': speed,
    'incline': incline,
    'met': met,
    'rest': rest,
    'note': note,
  };
  static WorkoutItem fromJson(Object? raw) {
    final j = wellnessObject(raw);
    return WorkoutItem(
      id: wellnessString(j, 'id'),
      exerciseId: wellnessString(j, 'exercise'),
      sets: wellnessInt(j, 'sets', 1, 30),
      reps: wellnessInt(j, 'reps', 1, 500),
      kg: wellnessOptional(j, 'kg', 0, 2000),
      minutes: wellnessNumber(j, 'minutes', .1, 1440),
      speed: wellnessOptional(j, 'speed', 0, 100),
      incline: wellnessOptional(j, 'incline', 0, 40),
      met: wellnessNumber(j, 'met', 1, 25),
      rest: wellnessInt(j, 'rest', 0, 3600),
      note: wellnessString(j, 'note'),
    );
  }
}

class TrainingDay {
  TrainingDay({
    required this.id,
    required this.title,
    required List<int> weekdays,
    List<WorkoutItem> items = const [],
  }) : weekdays = List.unmodifiable(weekdays),
       items = List.unmodifiable(items);
  final String id, title;
  final List<int> weekdays;
  final List<WorkoutItem> items;
  TrainingDay copyWith({
    String? title,
    List<int>? weekdays,
    List<WorkoutItem>? items,
  }) => TrainingDay(
    id: id,
    title: title ?? this.title,
    weekdays: weekdays ?? this.weekdays,
    items: items ?? this.items,
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'weekdays': weekdays,
    'items': items.map((e) => e.toJson()).toList(),
  };
  static TrainingDay fromJson(Object? raw) {
    final j = wellnessObject(raw);
    final days = wellnessList(j['weekdays']);
    if (days.any((v) => v is! int || v < 1 || v > 7) ||
        days.toSet().length != days.length) {
      throw const FormatException('Invalid weekdays');
    }
    return TrainingDay(
      id: wellnessString(j, 'id'),
      title: wellnessString(j, 'title'),
      weekdays: days.cast<int>(),
      items: wellnessUnique(
        wellnessList(j['items']).map(WorkoutItem.fromJson).toList(),
        (e) => e.id,
      ),
    );
  }
}

class TrainingPlan {
  TrainingPlan({
    required this.id,
    required this.title,
    List<TrainingDay> days = const [],
  }) : days = List.unmodifiable(days);
  final String id, title;
  final List<TrainingDay> days;
  TrainingPlan copyWith({String? title, List<TrainingDay>? days}) =>
      TrainingPlan(id: id, title: title ?? this.title, days: days ?? this.days);
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'days': days.map((e) => e.toJson()).toList(),
  };
  static TrainingPlan fromJson(Object? raw) {
    final j = wellnessObject(raw);
    return TrainingPlan(
      id: wellnessString(j, 'id'),
      title: wellnessString(j, 'title'),
      days: wellnessUnique(
        wellnessList(j['days']).map(TrainingDay.fromJson).toList(),
        (e) => e.id,
      ),
    );
  }
}

class PerformedSet {
  const PerformedSet(this.reps, this.kg);
  final int reps;
  final double? kg;
  Map<String, Object?> toJson() => {'reps': reps, 'kg': kg};
  static PerformedSet fromJson(Object? raw) {
    final j = wellnessObject(raw);
    return PerformedSet(
      wellnessInt(j, 'reps', 1, 500),
      wellnessOptional(j, 'kg', 0, 2000),
    );
  }
}

class WorkoutLog {
  WorkoutLog({
    required this.id,
    required this.date,
    required this.exercise,
    required this.prescription,
    required this.planTitle,
    required this.dayTitle,
    List<PerformedSet> sets = const [],
    required this.minutes,
    this.bodyKg,
    this.speed,
    this.incline,
    this.met = 4,
    this.note = '',
  }) : sets = List.unmodifiable(sets);
  final String id, planTitle, dayTitle, note;
  final LocalDate date;
  // Snapshots preserve history after the original plan or custom exercise changes.
  final Exercise exercise;
  final WorkoutItem prescription;
  final List<PerformedSet> sets;
  final double minutes, met;
  final double? bodyKg, speed, incline;
  double? get kcal => bodyKg == null
      ? null
      : estimatedCalories(minutes: minutes, bodyKg: bodyKg!, met: effectiveMet);
  double get effectiveMet => walkingMet(exercise.cardio, speed, incline) ?? met;
  bool get usesWalkingEquation =>
      walkingMet(exercise.cardio, speed, incline) != null;
  Map<String, Object?> toJson() => {
    'id': id,
    'date': date.toIso(),
    'exercise': exercise.toJson(),
    'prescription': prescription.toJson(),
    'plan': planTitle,
    'day': dayTitle,
    'sets': sets.map((e) => e.toJson()).toList(),
    'minutes': minutes,
    'body_kg': bodyKg,
    'speed': speed,
    'incline': incline,
    'met': met,
    'note': note,
  };
  static WorkoutLog fromJson(Object? raw) {
    final j = wellnessObject(raw);
    final e = Exercise.fromJson(j['exercise']);
    final sets = wellnessList(j['sets']).map(PerformedSet.fromJson).toList();
    if (sets.length > 30 ||
        (e.cardio == null && sets.isEmpty) ||
        (e.cardio != null && sets.isNotEmpty)) {
      throw const FormatException('Invalid performance');
    }
    final item = WorkoutItem.fromJson(j['prescription']);
    if (item.exerciseId != e.id) {
      throw const FormatException('Exercise mismatch');
    }
    return WorkoutLog(
      id: wellnessString(j, 'id'),
      date: LocalDate.parse(wellnessString(j, 'date')),
      exercise: e,
      prescription: item,
      planTitle: wellnessString(j, 'plan'),
      dayTitle: wellnessString(j, 'day'),
      sets: sets,
      minutes: wellnessNumber(j, 'minutes', .1, 1440),
      bodyKg: wellnessOptional(j, 'body_kg', 20, 500),
      speed: wellnessOptional(j, 'speed', 0, 100),
      incline: wellnessOptional(j, 'incline', 0, 40),
      met: wellnessNumber(j, 'met', 1, 25),
      note: wellnessString(j, 'note'),
    );
  }
}

class FitnessData {
  FitnessData({
    List<TrainingPlan> plans = const [],
    List<Exercise> custom = const [],
    List<WorkoutLog> logs = const [],
    this.bodyKg,
  }) : plans = List.unmodifiable(plans),
       custom = List.unmodifiable(custom),
       logs = List.unmodifiable(logs);
  final List<TrainingPlan> plans;
  final List<Exercise> custom;
  final List<WorkoutLog> logs;
  final double? bodyKg;
  FitnessData copyWith({
    List<TrainingPlan>? plans,
    List<Exercise>? custom,
    List<WorkoutLog>? logs,
    double? bodyKg,
    bool clearWeight = false,
  }) => FitnessData(
    plans: plans ?? this.plans,
    custom: custom ?? this.custom,
    logs: logs ?? this.logs,
    bodyKg: clearWeight ? null : bodyKg ?? this.bodyKg,
  );
  Map<String, Object?> toJson() => {
    'plans': plans.map((e) => e.toJson()).toList(),
    'custom': custom.map((e) => e.toJson()).toList(),
    'logs': logs.map((e) => e.toJson()).toList(),
    'body_kg': bodyKg,
  };
  static FitnessData fromJson(Object? raw) {
    if (raw == null) return FitnessData();
    final j = wellnessObject(raw);
    return FitnessData(
      plans: wellnessUnique(
        wellnessList(j['plans']).map(TrainingPlan.fromJson).toList(),
        (e) => e.id,
      ),
      custom: wellnessUnique(
        wellnessList(j['custom']).map(Exercise.fromJson).toList(),
        (e) => e.id,
      ),
      logs: wellnessUnique(
        wellnessList(j['logs']).map(WorkoutLog.fromJson).toList(),
        (e) => e.id,
      ),
      bodyKg: wellnessOptional(j, 'body_kg', 20, 500),
    );
  }
}

/// Gross energy, including resting metabolism. The user supplies MET outside
/// the ACSM walking equation's intended speed range. Never derived from load.
double estimatedCalories({
  required double minutes,
  required double bodyKg,
  required double met,
}) {
  if (!minutes.isFinite ||
      !bodyKg.isFinite ||
      !met.isFinite ||
      minutes <= 0 ||
      bodyKg <= 0 ||
      met <= 0) {
    throw ArgumentError('Invalid energy input');
  }
  return met * 3.5 * bodyKg / 200 * minutes;
}

double? walkingMet(Cardio? kind, double? speed, double? incline) {
  if ((kind != Cardio.walking && kind != Cardio.treadmill) ||
      speed == null ||
      incline == null ||
      !speed.isFinite ||
      !incline.isFinite ||
      speed < 3 ||
      speed > 6 ||
      incline < 0 ||
      incline > 20) {
    return null;
  }
  final mPerMin = speed * 1000 / 60;
  return (0.1 * mPerMin + 1.8 * mPerMin * incline / 100 + 3.5) / 3.5;
}
