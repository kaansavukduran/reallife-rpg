import 'wellness_values.dart';

class StudyUnit {
  const StudyUnit({required this.id, this.title = '', this.completedAt});
  final String id, title;
  final DateTime? completedAt;
  bool get completed => completedAt != null;
  StudyUnit rename(String name) =>
      StudyUnit(id: id, title: name, completedAt: completedAt);
  StudyUnit mark(DateTime? at) =>
      StudyUnit(id: id, title: title, completedAt: at);
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'completed_at': completedAt?.toUtc().toIso8601String(),
  };
  static StudyUnit fromJson(Object? raw) {
    final j = wellnessObject(raw);
    return StudyUnit(
      id: wellnessString(j, 'id'),
      title: wellnessString(j, 'title'),
      completedAt: j['completed_at'] == null
          ? null
          : DateTime.parse(wellnessString(j, 'completed_at')).toUtc(),
    );
  }
}

class Course {
  Course({
    required this.id,
    required this.title,
    required List<StudyUnit> units,
  }) : units = List.unmodifiable(units);
  final String id, title;
  final List<StudyUnit> units;
  int get completed => units.where((u) => u.completed).length;
  Course copyWith({String? title, List<StudyUnit>? units}) =>
      Course(id: id, title: title ?? this.title, units: units ?? this.units);
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'units': units.map((u) => u.toJson()).toList(),
  };
  static Course fromJson(Object? raw) {
    final j = wellnessObject(raw);
    final units = wellnessUnique(
      wellnessList(j['units']).map(StudyUnit.fromJson).toList(),
      (u) => u.id,
    );
    if (units.isEmpty ||
        units.length > 200 ||
        wellnessString(j, 'title').trim().isEmpty) {
      throw const FormatException('Invalid course');
    }
    return Course(
      id: wellnessString(j, 'id'),
      title: wellnessString(j, 'title'),
      units: units,
    );
  }
}

class StudyData {
  StudyData({List<Course> courses = const []})
    : courses = List.unmodifiable(courses);
  final List<Course> courses;
  StudyData copyWith({List<Course>? courses}) =>
      StudyData(courses: courses ?? this.courses);
  Map<String, Object?> toJson() => {
    'courses': courses.map((c) => c.toJson()).toList(),
  };
  static StudyData fromJson(Object? raw) {
    if (raw == null) return StudyData();
    final j = wellnessObject(raw);
    return StudyData(
      courses: wellnessUnique(
        wellnessList(j['courses']).map(Course.fromJson).toList(),
        (c) => c.id,
      ),
    );
  }
}
