import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/life.dart';
import '../domain/skill_tree.dart';
import '../l10n/strings.dart';
import 'life_widgets.dart';
import 'wellness_widgets.dart';

class SkillTreePage extends StatefulWidget {
  const SkillTreePage({super.key, required this.controller});
  final TaskController controller;
  @override
  State<SkillTreePage> createState() => _SkillTreePageState();
}

class _SkillTreePageState extends State<SkillTreePage> {
  SkillTreeKind kind = SkillTreeKind.life;
  bool list = false;
  final transform = TransformationController();
  TaskController get c => widget.controller;
  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  void save(SkillTreeData tree) =>
      c.updateLife(c.data.life.copyWith(skillTree: tree));
  Future<void> edit([SkillNode? node]) async {
    final next = await editSkillNode(context, c, kind, node);
    if (next != null) {
      save(
        SkillTreeData(
          nodes: [
            for (final n in c.data.life.skillTree.nodes)
              if (n.id != next.id) n,
            next,
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s, tree = c.data.life.skillTree;
    final nodes = tree.nodes.where((n) => n.kind == kind).toList();
    final xp = areaXp(c.data, c.today);
    final gaming = c.settings.gameMode;
    Widget card(SkillNode n) {
      final open = kind == SkillTreeKind.life
          ? n.marked
          : gaming && tree.unlocked(n, xp);
      return Semantics(
        button: true,
        label: '${n.title}: ${s(open ? 'unlocked' : 'locked')}',
        child: Card(
          color: open ? Theme.of(context).colorScheme.primaryContainer : null,
          child: InkWell(
            key: Key('skill-node-${n.id}'),
            onTap: () => edit(n),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(n.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(
                    '${s('area.${n.area.name}')}${kind == SkillTreeKind.passive && gaming ? ' · Lv ${n.minLevel}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (kind == SkillTreeKind.life)
                    Icon(
                      n.marked
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                    )
                  else if (gaming)
                    Icon(open ? Icons.lock_open : Icons.lock_outline),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return LifePage(
      children: [
        PageHeading(
          'RealLife RPG',
          s('skill_tree'),
          s('treeIntro'),
          action: FilledButton.icon(
            key: const Key('add-skill'),
            onPressed: () => edit(),
            icon: const Icon(Icons.add),
            label: Text(s('addSkill')),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final k in SkillTreeKind.values)
              ChoiceChip(
                label: Text(
                  s(k == SkillTreeKind.life ? 'treeLife' : 'treePassive'),
                ),
                selected: kind == k,
                onSelected: (_) => setState(() => kind = k),
              ),
            FilterChip(
              label: Text(s('treeList')),
              selected: list,
              onSelected: (v) => setState(() => list = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (kind == SkillTreeKind.passive) ...[
          Text(s(gaming ? 'treeFormula' : 'treeGameOff')),
          if (gaming)
            Wrap(
              spacing: 16,
              children: [
                for (final a in LifeArea.values)
                  Chip(
                    label: Text(
                      '${s('area.${a.name}')} · Lv ${areaLevel(xp[a]!)} · ${xp[a]} XP',
                    ),
                  ),
              ],
            ),
        ],
        if (nodes.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(s('treeEmpty')),
          )
        else if (list) ...[
          for (final node in nodes)
            SizedBox(
              height: 140,
              child: Row(
                children: [
                  if (node.parentId != null)
                    const Icon(Icons.subdirectory_arrow_right),
                  Expanded(child: card(node)),
                ],
              ),
            ),
        ] else
          LayoutBuilder(
            builder: (context, box) {
              final byId = {for (final n in nodes) n.id: n};
              int depth(SkillNode n) =>
                  n.parentId == null ? 0 : 1 + depth(byId[n.parentId]!);
              final levels = <int, List<SkillNode>>{};
              for (final n in nodes) {
                levels.putIfAbsent(depth(n), () => []).add(n);
              }
              final width = math.max(
                box.maxWidth,
                levels.values.map((v) => v.length * 220.0).reduce(math.max),
              );
              final height = math.max(360.0, levels.length * 160.0);
              final positions = <String, Offset>{};
              levels.forEach((d, group) {
                for (var i = 0; i < group.length; i++) {
                  positions[group[i].id] = Offset(
                    (width / group.length) * (i + .5) - 100,
                    d * 160 + 20,
                  );
                }
              });
              return Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: s('reset'),
                      onPressed: () => transform.value = Matrix4.identity(),
                      icon: const Icon(Icons.center_focus_strong),
                    ),
                  ),
                  SizedBox(
                    height: 430,
                    child: ClipRect(
                      child: InteractiveViewer(
                        transformationController: transform,
                        constrained: false,
                        minScale: .25,
                        maxScale: 3,
                        boundaryMargin: const EdgeInsets.all(100),
                        child: SizedBox(
                          width: width,
                          height: height,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _Branches(
                                    nodes,
                                    positions,
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              for (final n in nodes)
                                Positioned(
                                  left: positions[n.id]!.dx,
                                  top: positions[n.id]!.dy,
                                  width: 200,
                                  height: 120,
                                  child: card(n),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ExpansionTile(
          title: Text(s('assignTaskAreas')),
          children: [
            for (final task in c.data.tasks.where((t) => !t.isEndedOn(c.today)))
              Padding(
                padding: const EdgeInsets.all(8),
                child: DropdownButtonFormField<LifeArea>(
                  key: ValueKey(
                    '${task.id}-${c.data.life.links[task.id]?.area.name}',
                  ),
                  initialValue:
                      c.data.life.links[task.id]?.area ?? LifeArea.mind,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: task.title),
                  items: [
                    for (final a in LifeArea.values)
                      DropdownMenuItem(
                        value: a,
                        child: Text(s('area.${a.name}')),
                      ),
                  ],
                  onChanged: (v) {
                    final old = c.data.life.links[task.id];
                    c.updateLife(
                      c.data.life.copyWith(
                        links: {
                          ...c.data.life.links,
                          task.id: TaskLink(
                            area: v!,
                            projectId: old?.projectId ?? '',
                            skillId: old?.skillId ?? '',
                          ),
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Branches extends CustomPainter {
  _Branches(this.nodes, this.positions, this.color);
  final List<SkillNode> nodes;
  final Map<String, Offset> positions;
  final Color color;
  @override
  void paint(Canvas c, Size size) {
    for (final n in nodes.where((n) => n.parentId != null)) {
      final a = positions[n.parentId]! + const Offset(100, 120),
          b = positions[n.id]! + const Offset(100, 0);
      c.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..cubicTo(a.dx, a.dy + 20, b.dx, b.dy - 20, b.dx, b.dy),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_Branches old) => true;
}

Future<SkillNode?> editSkillNode(
  BuildContext context,
  TaskController c,
  SkillTreeKind kind, [
  SkillNode? node,
]) async {
  final title = TextEditingController(text: node?.title ?? ''),
      description = TextEditingController(text: node?.description ?? '');
  final level = TextEditingController(text: '${node?.minLevel ?? 2}');
  var parent = node?.parentId;
  var area = node?.area ?? LifeArea.mind;
  var marked = node?.marked ?? false;
  final forbidden = node == null
      ? <String>{}
      : {node.id, ...c.data.life.skillTree.descendants(node.id)};
  final key = GlobalKey<FormState>();
  final result = await showEditor<SkillNode>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => EditorDialog(
        title: context.s(node == null ? 'addSkill' : 'edit'),
        formKey: key,
        children: [
          textField(
            context,
            title,
            context.s('skillName'),
            key: const Key('skill-name'),
          ),
          textField(context, description, context.s('notes'), required: false),
          DropdownButtonFormField<String>(
            initialValue: parent ?? '',
            isExpanded: true,
            decoration: InputDecoration(labelText: context.s('parentSkill')),
            items: [
              DropdownMenuItem(value: '', child: Text(context.s('treeRoot'))),
              for (final n in c.data.life.skillTree.nodes.where(
                (n) => n.kind == kind && !forbidden.contains(n.id),
              ))
                DropdownMenuItem(
                  value: n.id,
                  child: Text(n.title, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => parent = v == '' ? null : v,
          ),
          DropdownButtonFormField<LifeArea>(
            initialValue: area,
            decoration: InputDecoration(labelText: context.s('skillArea')),
            items: [
              for (final a in LifeArea.values)
                DropdownMenuItem(
                  value: a,
                  child: Text(context.s('area.${a.name}')),
                ),
            ],
            onChanged: (v) => area = v!,
          ),
          if (kind == SkillTreeKind.life)
            CheckboxListTile(
              title: Text(context.s('doneTask')),
              value: marked,
              onChanged: (v) => set(() => marked = v!),
            )
          else ...[
            numberField(
              context,
              level,
              context.s('unlockLevel'),
              min: 1,
              max: 1000,
              integer: true,
              required: true,
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: level,
              builder: (context, v, _) => Slider(
                min: 1,
                max: 100,
                divisions: 99,
                value: (int.tryParse(v.text) ?? 2).clamp(1, 100).toDouble(),
                label: v.text,
                onChanged: (v) => level.text = v.round().toString(),
              ),
            ),
          ],
          if (node != null)
            TextButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: Text(context.s('delete')),
              onPressed: () async {
                if (await confirmRemoval(context, node.title)) {
                  c.updateLife(
                    c.data.life.copyWith(
                      skillTree: c.data.life.skillTree.without(node.id),
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
        onSave: () => Navigator.pop(
          context,
          SkillNode(
            id: node?.id ?? c.newLifeId(),
            title: title.text.trim(),
            description: description.text.trim(),
            kind: kind,
            parentId: parent,
            area: area,
            minLevel: int.parse(level.text),
            marked: marked,
          ),
        ),
      ),
    ),
  );
  title.dispose();
  description.dispose();
  level.dispose();
  return result;
}
