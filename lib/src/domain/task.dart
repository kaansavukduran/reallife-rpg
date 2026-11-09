import 'local_date.dart';
import 'repeat_rule.dart';

/// From [from] on, the task follows [rule]; a null rule means the task was
/// ended (it is not expected on those days).
///
/// A task keeps every segment it ever had, so changing a rule or ending a
/// task never changes what was expected on an earlier day.
class ScheduleSegment {
  const ScheduleSegment(this.from, this.rule);

  final LocalDate from;
  final RepeatRule? rule;

  Map<String, Object?> toJson() => {
    'from': from.toIso(),
    'rule': rule?.toJson(),
  };

  static ScheduleSegment fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('Takvim dilimi bir nesne olmalı');
    }
    final from = json['from'];
    if (from is! String) {
      throw const FormatException('Takvim diliminin başlangıcı yok');
    }
    final rule = json['rule'];
    return ScheduleSegment(
      LocalDate.parse(from),
      rule == null ? null : RepeatRule.fromJson(rule),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ScheduleSegment && other.from == from && other.rule == rule;

  @override
  int get hashCode => Object.hash(from, rule);
}

/// How hard a task is; harder tasks give more XP.
enum Difficulty {
  kolay('Kolay', 10),
  orta('Orta', 20),
  zor('Zor', 35);

  const Difficulty(this.label, this.baseXp);
  final String label;
  final int baseXp;

  static Difficulty parse(Object? v) {
    for (final d in values) {
      if (d.name == v) return d;
    }
    throw FormatException('Bilinmeyen zorluk', v);
  }
}

/// A clock time in the day ("HH:MM"), used as a reminder.
class ClockTime implements Comparable<ClockTime> {
  ClockTime(this.hour, this.minute) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw ArgumentError('Saat 00:00 ile 23:59 arasında olmalı');
    }
  }

  factory ClockTime.parse(String text) {
    final m = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(text);
    if (m == null) throw FormatException('Saat SS:DD biçiminde olmalı', text);
    try {
      return ClockTime(int.parse(m.group(1)!), int.parse(m.group(2)!));
    } on ArgumentError {
      throw FormatException('Böyle bir saat yok', text);
    }
  }

  final int hour;
  final int minute;

  int get minutes => hour * 60 + minute;

  String format() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(ClockTime other) => minutes.compareTo(other.minutes);

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.minutes == minutes;

  @override
  int get hashCode => minutes;

  @override
  String toString() => format();
}

/// One step of a task (a small checklist item).
class TaskStep {
  TaskStep(this.id, this.title) {
    if (id.isEmpty || title.trim().isEmpty) {
      throw ArgumentError('Adımın kimliği ve adı olmalı');
    }
  }

  final String id;
  final String title;

  Map<String, Object?> toJson() => {'id': id, 'title': title};

  static TaskStep fromJson(Object? json) {
    if (json is! Map<String, Object?> ||
        json['id'] is! String ||
        json['title'] is! String) {
      throw const FormatException('Adım bozuk');
    }
    try {
      return TaskStep(json['id']! as String, json['title']! as String);
    } on ArgumentError catch (e) {
      throw FormatException('${e.message}');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is TaskStep && other.id == id && other.title == title;

  @override
  int get hashCode => Object.hash(id, title);
}

class Task {
  Task({
    required this.id,
    required this.title,
    required this.note,
    required List<ScheduleSegment> schedule,
    required this.createdAt,
    required this.order,
    this.difficulty = Difficulty.orta,
    int? baseXp,
    this.time,
    this.durationMinutes,
    List<TaskStep> steps = const [],
  }) : baseXp = baseXp ?? difficulty.baseXp,
       schedule = List.unmodifiable(schedule),
       steps = List.unmodifiable(steps) {
    if (steps.map((s) => s.id).toSet().length != steps.length) {
      throw ArgumentError('Aynı kimlikle iki adım var');
    }
    if (durationMinutes != null &&
        (durationMinutes! < 1 || durationMinutes! > 1440)) {
      throw ArgumentError('Invalid task duration');
    }
    if (this.baseXp < 0 || this.baseXp > 100) {
      throw ArgumentError('Task XP must be from 0 to 100');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('Görev adı boş olamaz');
    }
    if (schedule.isEmpty) {
      throw ArgumentError('Görevin en az bir takvim dilimi olmalı');
    }
    for (var i = 1; i < schedule.length; i++) {
      if (!schedule[i - 1].from.isBefore(schedule[i].from)) {
        throw ArgumentError('Takvim dilimleri tarih sırasında olmalı');
      }
    }
  }

  final String id;
  final String title;
  final String note;

  /// Sorted by [ScheduleSegment.from], strictly increasing.
  final List<ScheduleSegment> schedule;

  /// When the task was created (UTC).
  final DateTime createdAt;

  /// Position in lists; smaller comes first.
  final int order;

  /// How hard the task is (XP).
  final Difficulty difficulty;

  /// User-selected base reward, 0–100. Legacy difficulty supplies the default.
  final int baseXp;

  /// Optional reminder time on the days the task is expected.
  final ClockTime? time;
  final int? durationMinutes;

  DateTime deadlineOn(LocalDate date) {
    if (time == null) {
      final next = date.addDays(1);
      return DateTime(next.year, next.month, next.day);
    }
    return DateTime(
      date.year,
      date.month,
      date.day,
      time!.hour,
      time!.minute,
    ).add(Duration(minutes: durationMinutes ?? 0));
  }

  bool isOverdueOn(LocalDate date, DateTime now) =>
      isScheduledOn(date) && !now.isBefore(deadlineOn(date));

  /// Optional checklist; ticking every step ticks the task.
  final List<TaskStep> steps;

  /// First day the task could be expected.
  LocalDate get startDate => schedule.first.from;

  /// The rule in force on [date], or null when the task was not started yet
  /// or was ended by then.
  RepeatRule? ruleOn(LocalDate date) {
    RepeatRule? rule;
    for (final s in schedule) {
      if (s.from.isAfter(date)) break;
      rule = s.rule;
    }
    return rule;
  }

  bool isScheduledOn(LocalDate date) => ruleOn(date)?.matches(date) ?? false;

  /// The most recent rule that is not an end marker, or null when the task
  /// was ended before it ever began.
  RepeatRule? get lastRule {
    for (final s in schedule.reversed) {
      if (s.rule != null) return s.rule;
    }
    return null;
  }

  /// Ended means the latest segment that has begun by [today] is an end
  /// marker.
  bool isEndedOn(LocalDate today) {
    final started = schedule.where((s) => !s.from.isAfter(today));
    if (started.isEmpty) return false;
    return started.last.rule == null;
  }

  /// Whether the task can still be expected on [today] or later: it is not
  /// ended, and a one-off has not passed.
  bool hasFutureOn(LocalDate today) {
    if (isEndedOn(today)) {
      return schedule.any((s) => s.from.isAfter(today) && s.rule != null);
    }
    final rule = ruleOn(today) ?? schedule.first.rule;
    if (rule == null) return false;
    if (rule is OnceRule) return !rule.date.isBefore(today);
    return true;
  }

  /// A copy that follows [rule] from [from] on (null ends the task there).
  /// Days before [from] keep the rule they had; segments from [from] on are
  /// replaced. A change that repeats the rule already in force is dropped.
  Task withRuleFrom(LocalDate from, RepeatRule? rule) {
    final kept = schedule.where((s) => s.from.isBefore(from)).toList();
    if (kept.isNotEmpty && kept.last.rule == rule) {
      return copyWith(schedule: kept);
    }
    return copyWith(schedule: [...kept, ScheduleSegment(from, rule)]);
  }

  Task copyWith({
    String? title,
    String? note,
    List<ScheduleSegment>? schedule,
    int? order,
    Difficulty? difficulty,
    int? baseXp,
    ClockTime? Function()? time,
    int? Function()? durationMinutes,
    List<TaskStep>? steps,
  }) => Task(
    id: id,
    title: title ?? this.title,
    note: note ?? this.note,
    schedule: schedule ?? this.schedule,
    createdAt: createdAt,
    order: order ?? this.order,
    difficulty: difficulty ?? this.difficulty,
    baseXp: baseXp ?? (difficulty == null ? this.baseXp : difficulty.baseXp),
    time: time == null ? this.time : time(),
    durationMinutes: durationMinutes == null
        ? this.durationMinutes
        : durationMinutes(),
    steps: steps ?? this.steps,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'note': note,
    'schedule': [for (final s in schedule) s.toJson()],
    'created_at': createdAt.toUtc().toIso8601String(),
    'order': order,
    'difficulty': difficulty.name,
    'base_xp': baseXp,
    'time': time?.format(),
    'duration_minutes': durationMinutes,
    'steps': [for (final s in steps) s.toJson()],
  };

  static Task fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('Görev bir nesne olmalı');
    }
    final id = json['id'];
    final title = json['title'];
    final note = json['note'] ?? '';
    final schedule = json['schedule'];
    final createdAt = json['created_at'];
    final order = json['order'] ?? 0;
    if (id is! String || id.isEmpty) {
      throw const FormatException('Görevin kimliği yok');
    }
    if (title is! String || title.trim().isEmpty) {
      throw FormatException('Görevin adı yok', id);
    }
    if (note is! String) throw FormatException('Görev notu metin olmalı', id);
    if (schedule is! List<Object?> || schedule.isEmpty) {
      throw FormatException('Görevin takvimi yok', id);
    }
    if (createdAt is! String) {
      throw FormatException('Görevin oluşturulma zamanı yok', id);
    }
    if (order is! int) throw FormatException('Görev sırası sayı olmalı', id);
    final xp = json['base_xp'];
    if (json.containsKey('base_xp') && (xp is! int || xp < 0 || xp > 100)) {
      throw const FormatException('Task XP must be an integer from 0 to 100');
    }
    final time = json['time'];
    if (time != null && time is! String) {
      throw FormatException('Görev saati metin olmalı', id);
    }
    final duration = json['duration_minutes'];
    if (duration != null &&
        (duration is! int || duration < 1 || duration > 1440)) {
      throw const FormatException('Invalid duration');
    }
    final steps = json['steps'] ?? const <Object?>[];
    if (steps is! List<Object?>) {
      throw FormatException('Adımlar liste olmalı', id);
    }
    try {
      return Task(
        id: id,
        title: title,
        note: note,
        schedule: [for (final s in schedule) ScheduleSegment.fromJson(s)],
        createdAt: DateTime.parse(createdAt).toUtc(),
        order: order,
        difficulty: json.containsKey('difficulty')
            ? Difficulty.parse(json['difficulty'])
            : Difficulty.orta,
        baseXp: xp as int?,
        time: time == null ? null : ClockTime.parse(time as String),
        durationMinutes: duration as int?,
        steps: [for (final s in steps) TaskStep.fromJson(s)],
      );
    } on ArgumentError catch (e) {
      throw FormatException('${e.message}', id);
    }
  }
}
