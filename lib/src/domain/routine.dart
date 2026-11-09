import 'wellness_values.dart';

/// A routine uses the existing task engine for dates, time and outcome history.
/// Linking never completes a task or an underlying unit/workout automatically.
enum RoutineKind { course, training }

class RoutineBinding {
  const RoutineBinding({
    required this.kind,
    required this.entityId,
    this.dayId = '',
  });
  final RoutineKind kind;
  final String entityId, dayId;
  String get key => '${kind.name}:$entityId:$dayId';
  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'entity': entityId,
    'day': dayId,
  };
  static RoutineBinding fromJson(Object? raw) {
    final j = wellnessObject(raw);
    return RoutineBinding(
      kind: wellnessEnum(RoutineKind.values, j['kind']),
      entityId: wellnessString(j, 'entity'),
      dayId: wellnessString(j, 'day'),
    );
  }
}
