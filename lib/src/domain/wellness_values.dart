// Shared strict validators for persisted wellness data. Unknown is null, never 0.
Map<String, Object?> wellnessObject(Object? raw) {
  if (raw is! Map<String, Object?>) {
    throw const FormatException('Invalid wellness object');
  }
  return raw;
}

List<Object?> wellnessList(Object? raw) {
  if (raw is! List<Object?> || raw.length > 100000) {
    throw const FormatException('Invalid wellness list');
  }
  return raw;
}

String wellnessString(Map<String, Object?> j, String key) {
  final v = j[key];
  if (v is! String || v.length > 50000) throw FormatException('Invalid $key');
  return v;
}

double wellnessNumber(
  Map<String, Object?> j,
  String key,
  double min,
  double max,
) {
  final v = j[key];
  if (v is! num || !v.isFinite || v < min || v > max) {
    throw FormatException('Invalid $key');
  }
  return v.toDouble();
}

double? wellnessOptional(
  Map<String, Object?> j,
  String key,
  double min,
  double max,
) => j[key] == null ? null : wellnessNumber(j, key, min, max);
int wellnessInt(Map<String, Object?> j, String key, int min, int max) {
  final v = j[key];
  if (v is! int || v < min || v > max) throw FormatException('Invalid $key');
  return v;
}

T wellnessEnum<T extends Enum>(List<T> values, Object? raw) =>
    values.firstWhere(
      (v) => v.name == raw,
      orElse: () => throw const FormatException('Unknown enum'),
    );
List<T> wellnessUnique<T>(List<T> values, String Function(T) id) {
  if (values.map(id).toSet().length != values.length) {
    throw const FormatException('Duplicate IDs');
  }
  return List.unmodifiable(values);
}
