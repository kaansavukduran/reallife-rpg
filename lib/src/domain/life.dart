import 'local_date.dart';

const lifeSchema = 1;

enum LifeArea {
  mind('Zihin', 'Öğren, üret, merak et'),
  body('Beden', 'Hareket et, dinlen, güçlen'),
  craft('Meslek', 'Küçük adımlarla ustalaş'),
  social('Sosyal', 'Bağ kur, birlikte büyü'),
  spirit('Denge', 'Kendine alan aç');

  const LifeArea(this.label, this.description);
  final String label;
  final String description;
}

const professions = <String, String>{
  'explorer': 'Kaşif',
  'developer': 'Yazılımcı',
  'scholar': 'Araştırmacı',
  'artist': 'Yaratıcı',
  'athlete': 'Sporcu',
  'healer': 'İyilik elçisi',
};

/// Personal records are separate from game points: no self-report certifies
/// proficiency, and no elapsed time becomes a completion.
class LifeData {
  LifeData({
    this.name = '',
    this.profession = 'explorer',
    this.companion = 'mint',
    this.bio = '',
    List<LifeProject> projects = const [],
    Map<String, TaskLink> links = const {},
    Map<String, HealthEntry> health = const {},
    List<FocusSession> sessions = const [],
    List<Milestone> milestones = const [],
    List<AssessmentRecord> assessments = const [],
  }) : projects = List.unmodifiable(projects),
       links = Map.unmodifiable(links),
       health = Map.unmodifiable(health),
       sessions = List.unmodifiable(sessions),
       milestones = List.unmodifiable(milestones),
       assessments = List.unmodifiable(assessments);

  final String name, profession, companion, bio;
  final List<LifeProject> projects;
  final Map<String, TaskLink> links;
  final Map<String, HealthEntry> health;
  final List<FocusSession> sessions;
  final List<Milestone> milestones;
  final List<AssessmentRecord> assessments;

  LifeData copyWith({
    String? name,
    String? profession,
    String? companion,
    String? bio,
    List<LifeProject>? projects,
    Map<String, TaskLink>? links,
    Map<String, HealthEntry>? health,
    List<FocusSession>? sessions,
    List<Milestone>? milestones,
    List<AssessmentRecord>? assessments,
  }) => LifeData(
    name: name ?? this.name,
    profession: profession ?? this.profession,
    companion: companion ?? this.companion,
    bio: bio ?? this.bio,
    projects: projects ?? this.projects,
    links: links ?? this.links,
    health: health ?? this.health,
    sessions: sessions ?? this.sessions,
    milestones: milestones ?? this.milestones,
    assessments: assessments ?? this.assessments,
  );

  Map<String, Object?> toJson() => {
    'version': lifeSchema,
    'name': name,
    'profession': profession,
    'companion': companion,
    'bio': bio,
    'projects': projects.map((e) => e.toJson()).toList(),
    'links': links.map((k, v) => MapEntry(k, v.toJson())),
    'health': health.map((k, v) => MapEntry(k, v.toJson())),
    'sessions': sessions.map((e) => e.toJson()).toList(),
    'milestones': milestones.map((e) => e.toJson()).toList(),
    'assessments': assessments.map((e) => e.toJson()).toList(),
  };

  static LifeData fromJson(Object? raw) {
    if (raw == null) return LifeData();
    final j = object(raw);
    if (j['version'] != lifeSchema) {
      throw const FormatException('Desteklenmeyen yaşam verisi sürümü');
    }
    final projects = items(j['projects']).map(LifeProject.fromJson).toList();
    if (projects.map((p) => p.id).toSet().length != projects.length) {
      throw const FormatException('Proje kimlikleri tekrarlanamaz');
    }
    final health = object(j['health']).map((k, v) {
      LocalDate.parse(k);
      return MapEntry(k, HealthEntry.fromJson(v));
    });
    return LifeData(
      name: string(j, 'name'),
      profession: string(j, 'profession'),
      companion: string(j, 'companion'),
      bio: string(j, 'bio'),
      projects: projects,
      links: object(j['links'])
          .map((k, v) => MapEntry(k, TaskLink.fromJson(v))),
      health: health,
      sessions: items(j['sessions']).map(FocusSession.fromJson).toList(),
      milestones: items(j['milestones']).map(Milestone.fromJson).toList(),
      assessments: items(j['assessments'])
          .map(AssessmentRecord.fromJson)
          .toList(),
    );
  }
}

class LifeProject {
  const LifeProject({
    required this.id,
    required this.title,
    required this.area,
    this.note = '',
    this.archived = false,
  });
  final String id, title, note;
  final LifeArea area;
  final bool archived;
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'area': area.name,
    'note': note,
    'archived': archived,
  };
  static LifeProject fromJson(Object? raw) {
    final j = object(raw);
    return LifeProject(
      id: string(j, 'id'),
      title: string(j, 'title'),
      area: areaOf(j['area']),
      note: string(j, 'note'),
      archived: boolean(j, 'archived'),
    );
  }
}

class TaskLink {
  const TaskLink({
    this.area = LifeArea.mind,
    this.projectId = '',
    this.skillId = '',
  });
  final LifeArea area;
  final String projectId, skillId;
  Map<String, Object?> toJson() => {
    'area': area.name,
    'project': projectId,
    'skill': skillId,
  };
  static TaskLink fromJson(Object? raw) {
    final j = object(raw);
    return TaskLink(
      area: areaOf(j['area']),
      projectId: string(j, 'project'),
      skillId: string(j, 'skill'),
    );
  }
}

class HealthEntry {
  const HealthEntry({
    this.water = 0,
    this.sleep,
    this.movement,
    this.mood,
    this.note = '',
  });
  final int water;
  final double? sleep;
  final int? movement, mood;
  final String note;
  Map<String, Object?> toJson() => {
    'water': water,
    'sleep': sleep,
    'movement': movement,
    'mood': mood,
    'note': note,
  };
  static HealthEntry fromJson(Object? raw) {
    final j = object(raw);
    final water = integer(j, 'water', 0, 40);
    final sleep = j['sleep'];
    if (sleep != null &&
        (sleep is! num || !sleep.isFinite || sleep < 0 || sleep > 24)) {
      throw const FormatException('Uyku 0–24 saat olmalı');
    }
    return HealthEntry(
      water: water,
      sleep: (sleep as num?)?.toDouble(),
      movement: j['movement'] == null ? null : integer(j, 'movement', 0, 1440),
      mood: j['mood'] == null ? null : integer(j, 'mood', 1, 5),
      note: string(j, 'note'),
    );
  }
}

class FocusSession {
  const FocusSession({
    required this.id,
    required this.at,
    required this.minutes,
    required this.taskId,
  });
  final String id, taskId;
  final DateTime at;
  final int minutes;
  Map<String, Object?> toJson() => {
    'id': id,
    'at': at.toUtc().toIso8601String(),
    'minutes': minutes,
    'task': taskId,
  };
  static FocusSession fromJson(Object? raw) {
    final j = object(raw);
    return FocusSession(
      id: string(j, 'id'),
      at: DateTime.parse(string(j, 'at')),
      minutes: integer(j, 'minutes', 1, 180),
      taskId: string(j, 'task'),
    );
  }
}

class Milestone {
  const Milestone({
    required this.id,
    required this.title,
    required this.kind,
    required this.date,
    this.note = '',
  });
  final String id, title, kind, note;
  final LocalDate date;
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'kind': kind,
    'date': date.toIso(),
    'note': note,
  };
  static Milestone fromJson(Object? raw) {
    final j = object(raw);
    return Milestone(
      id: string(j, 'id'),
      title: string(j, 'title'),
      kind: string(j, 'kind'),
      date: LocalDate.parse(string(j, 'date')),
      note: string(j, 'note'),
    );
  }
}

class AssessmentRecord {
  const AssessmentRecord({
    required this.id,
    required this.skill,
    required this.at,
    required this.score,
    required this.total,
    required this.method,
    required this.feedback,
    required this.evidence,
    this.rubric = 'v1',
  });
  final String id, skill, method, feedback, evidence, rubric;
  final DateTime at;
  final int score, total;
  Map<String, Object?> toJson() => {
    'id': id,
    'skill': skill,
    'at': at.toUtc().toIso8601String(),
    'score': score,
    'total': total,
    'method': method,
    'feedback': feedback,
    'evidence': evidence,
    'rubric': rubric,
  };
  static AssessmentRecord fromJson(Object? raw) {
    final j = object(raw);
    final total = integer(j, 'total', 1, 1000);
    return AssessmentRecord(
      id: string(j, 'id'),
      skill: string(j, 'skill'),
      at: DateTime.parse(string(j, 'at')),
      score: integer(j, 'score', 0, total),
      total: total,
      method: string(j, 'method'),
      feedback: string(j, 'feedback'),
      evidence: string(j, 'evidence'),
      rubric: string(j, 'rubric'),
    );
  }
}

Map<String, Object?> object(Object? raw) {
  if (raw is! Map<String, Object?>) {
    throw const FormatException('Nesne bekleniyordu');
  }
  return raw;
}

List<Object?> items(Object? raw) {
  if (raw is! List<Object?> || raw.length > 100000) {
    throw const FormatException('Geçersiz liste');
  }
  return raw;
}

String string(Map<String, Object?> j, String key) {
  final value = j[key];
  if (value is! String || value.length > 50000) {
    throw FormatException('Geçersiz metin: $key');
  }
  return value;
}

bool boolean(Map<String, Object?> j, String key) {
  final value = j[key];
  if (value is! bool) throw FormatException('Geçersiz mantıksal değer: $key');
  return value;
}

int integer(Map<String, Object?> j, String key, int min, int max) {
  final value = j[key];
  if (value is! int || value < min || value > max) {
    throw FormatException('Aralık dışında: $key');
  }
  return value;
}

LifeArea areaOf(Object? raw) => LifeArea.values.firstWhere(
  (a) => a.name == raw,
  orElse: () => throw const FormatException('Bilinmeyen yaşam alanı'),
);
