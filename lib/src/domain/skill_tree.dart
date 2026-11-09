import 'life.dart';
import 'local_date.dart';
import 'task_data.dart';
import 'wellness_values.dart';

enum SkillTreeKind { life, passive }

class SkillNode {
  const SkillNode({
    required this.id,
    required this.title,
    this.description = '',
    this.parentId,
    this.kind = SkillTreeKind.life,
    this.area = LifeArea.mind,
    this.minLevel = 2,
    this.marked = false,
  });
  final String id, title, description;
  final String? parentId;
  final SkillTreeKind kind;
  final LifeArea area;
  final int minLevel;
  final bool marked;
  SkillNode reparent(String? parent) => SkillNode(
    id: id,
    title: title,
    description: description,
    parentId: parent,
    kind: kind,
    area: area,
    minLevel: minLevel,
    marked: marked,
  );
  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'parent': parentId,
    'kind': kind.name,
    'area': area.name,
    'min_level': minLevel,
    'marked': marked,
  };
  static SkillNode fromJson(Object? raw) {
    final j = wellnessObject(raw);
    if (j['description'] is! String || j['marked'] is! bool) {
      throw const FormatException('Invalid skill text or mark');
    }
    return SkillNode(
      id: wellnessString(j, 'id'),
      title: wellnessString(j, 'title'),
      description: j['description'] as String,
      parentId: j['parent'] == null ? null : wellnessString(j, 'parent'),
      kind: wellnessEnum(SkillTreeKind.values, j['kind']),
      area: wellnessEnum(LifeArea.values, j['area']),
      minLevel: wellnessInt(j, 'min_level', 1, 1000),
      marked: j['marked'] as bool,
    );
  }
}

class SkillTreeData {
  SkillTreeData({List<SkillNode> nodes = const []})
    : nodes = List.unmodifiable(nodes) {
    final ids = nodes.map((n) => n.id).toSet();
    if (ids.length != nodes.length) {
      throw const FormatException('Duplicate skill nodes');
    }
    final map = {for (final n in nodes) n.id: n};
    for (final n in nodes) {
      if (n.id.isEmpty ||
          n.title.trim().isEmpty ||
          n.minLevel < 1 ||
          n.minLevel > 1000) {
        throw const FormatException('Invalid skill node');
      }
      final visited = <String>{n.id};
      var parent = n.parentId;
      while (parent != null) {
        final p = map[parent];
        if (p == null || p.kind != n.kind || !visited.add(parent)) {
          throw const FormatException('Invalid skill branch or cycle');
        }
        parent = p.parentId;
      }
    }
  }
  final List<SkillNode> nodes;
  Set<String> descendants(String id) {
    final found = <String>{};
    void visit(String p) {
      for (final n in nodes.where((n) => n.parentId == p)) {
        found.add(n.id);
        visit(n.id);
      }
    }

    visit(id);
    return found;
  }

  SkillTreeData without(String id) {
    final node = nodes.firstWhere((n) => n.id == id);
    return SkillTreeData(
      nodes: [
        for (final n in nodes)
          if (n.id != id) n.parentId == id ? n.reparent(node.parentId) : n,
      ],
    );
  }

  bool unlocked(SkillNode node, Map<LifeArea, int> xp) {
    if (node.kind == SkillTreeKind.life) return node.marked;
    if (areaLevel(xp[node.area] ?? 0) < node.minLevel) return false;
    if (node.parentId == null) return true;
    return unlocked(nodes.firstWhere((n) => n.id == node.parentId), xp);
  }

  Map<String, Object?> toJson() => {
    'nodes': nodes.map((n) => n.toJson()).toList(),
  };
  static SkillTreeData fromJson(Object? raw) => raw == null
      ? SkillTreeData()
      : SkillTreeData(
          nodes: wellnessList(wellnessObject(raw)['nodes'])
              .map(SkillNode.fromJson)
              .toList(),
        );
}

int areaLevel(int xp) => 1 + xp ~/ 100;
Map<LifeArea, int> areaXp(TaskData data, LocalDate today) {
  final result = {for (final a in LifeArea.values) a: 0};
  for (final task in data.tasks) {
    final area = data.life.links[task.id]?.area ?? LifeArea.mind;
    for (final day in data.completions[task.id]?.keys ?? const <LocalDate>[]) {
      if (!day.isAfter(today)) {
        result[area] = result[area]! + data.baseXpAt(task, day);
      }
    }
  }
  return result;
}
