import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/domain/codec.dart';
import 'package:reallife_rpg/src/domain/daily_summary.dart';
import 'package:reallife_rpg/src/domain/life.dart';
import 'package:reallife_rpg/src/domain/local_date.dart';
import 'package:reallife_rpg/src/domain/meal_template.dart';
import 'package:reallife_rpg/src/domain/nutrition.dart';
import 'package:reallife_rpg/src/domain/repeat_rule.dart';
import 'package:reallife_rpg/src/domain/routine.dart';
import 'package:reallife_rpg/src/domain/skill_tree.dart';
import 'package:reallife_rpg/src/domain/task.dart';
import 'package:reallife_rpg/src/domain/task_data.dart';
import 'package:reallife_rpg/src/domain/weekly_review.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';

void main() {
  test('interval expiry is dynamic; retroactive ticks correct score; no clock XP or data writes', () async {
    var now = DateTime(2026, 11, 9, 9, 30);
    final store = MemoryTaskStore();
    final c = TaskController(store: store, clock: () => now);
    await c.load();
    final task = c.addTask(
      title: 'Training',
      rule: const DailyRule(),
      start: c.today,
      time: ClockTime(9, 0),
      durationMinutes: 60,
      baseXp: 73,
    );
    expect(
      c.data.statusOf(task, c.today, c.today, now: now),
      DayStatus.pending,
    );
    expect(WeeklyReview(c.data, c.today, now).score, isNull);
    await c.saved;
    final saves = store.saveCount;
    now = DateTime(2026, 11, 9, 10);
    c.refreshToday();
    expect(c.data.statusOf(task, c.today, c.today, now: now), DayStatus.missed);
    expect(WeeklyReview(c.data, c.today, now).score, 0);
    expect(c.profile.totalXp, 0);
    expect(store.saveCount, saves);
    expect(c.data.completions, isEmpty);
    final yesterday = c.today;
    now = DateTime(2026, 11, 10, 8);
    c.refreshToday();
    c.toggle(task.id, yesterday);
    expect(WeeklyReview(c.data, yesterday, now).score, 10);
    expect(c.data.statusOf(task, yesterday, c.today, now: now), DayStatus.done);
    expect(c.profile.totalXp, 73 + 25);
    c.dispose();
  });
  test('cross-midnight interval remains pending until its own end', () async {
    final c = TaskController(
      store: MemoryTaskStore(),
      clock: () => DateTime(2026, 11, 9),
    );
    await c.load();
    final task = c.addTask(
      title: 'Night',
      rule: const DailyRule(),
      start: c.today,
      time: ClockTime(23, 30),
      durationMinutes: 90,
    );
    expect(task.isOverdueOn(c.today, DateTime(2026, 11, 10, 0, 59)), false);
    expect(task.isOverdueOn(c.today, DateTime(2026, 11, 10, 1)), true);
    c.dispose();
  });
  test('routine source and canonical task save together; edits do not duplicate or lose history', () async {
    var now = DateTime(2026, 11, 9, 9);
    final store = MemoryTaskStore();
    final c = TaskController(store: store, clock: () => now);
    await c.load();
    const binding = RoutineBinding(
      kind: RoutineKind.training,
      entityId: 'p',
      dayId: 'd',
    );
    c.updateLifeWithRoutine(
      c.data.life,
      binding,
      title: 'Upper',
      weekdays: [1, 3],
      time: ClockTime(10, 0),
      durationMinutes: 45,
    );
    final task = c.data.tasks.single;
    expect(c.data.life.links[task.id]!.area, LifeArea.body);
    expect(c.profile.totalXp, 0);
    c.toggle(task.id, c.today);
    final oldDay = c.today;
    now = DateTime(2026, 11, 10);
    c.refreshToday();
    c.updateLifeWithRoutine(
      c.data.life,
      binding,
      title: 'Upper 2',
      weekdays: [2, 4],
      time: ClockTime(11, 0),
    );
    expect(c.data.tasks.length, 1);
    expect(c.data.tasks.single.isScheduledOn(oldDay), true);
    expect(c.data.isDone(task.id, oldDay), true);
    c.updateLifeEndingRoutines(c.data.life, RoutineKind.training, 'p');
    expect(c.data.tasks.single.isEndedOn(c.today), true);
    await c.saved;
    final restored = decodeTaskData(store.saved!);
    expect(restored.life.routines[task.id]!.key, binding.key);
    expect(restored.isDone(task.id, oldDay), true);
    final raw = jsonDecode(store.saved!) as Map<String, dynamic>;
    final life = raw['life'] as Map;
    life['routines'] = {'missing': binding.toJson()};
    expect(() => decodeTaskData(jsonEncode(raw)), throwsFormatException);
    c.dispose();
  });
  test('meal projections never mark eaten; gram snapshot, override and omission survive reopening', () {
    final day = LocalDate(2026, 11, 9);
    final food = Food(
      id: 'blue',
      tr: 'Yaban mersini',
      en: 'Blueberry',
      source: 'test',
      values: {'energy': 57, 'protein': .7},
    );
    final template = MealTemplate(
      id: 'm',
      title: 'Berries',
      meal: Meal.breakfast,
      start: day,
      weekdays: [1, 3],
      foods: [TemplateFood(id: 'f', food: food, grams: 150)],
    );
    var n = NutritionData(templates: [template]);
    final projected = n.entriesOn(day).single;
    expect(projected.eaten, false);
    expect(projected.grams, 150);
    expect(n.entriesOn(day.addDays(1)), isEmpty);
    n = n.copyWith(entries: [projected.copyWith(eaten: true)]);
    expect(n.entriesOn(day).length, 1);
    final summary = PeriodSummary(
      TaskData(life: LifeData(nutrition: n)),
      day,
      day,
      now: DateTime(2026, 11, 9, 12),
    );
    expect(summary.nutrient('energy').known, 85.5);
    expect(summary.recordedDifference, 85.5);
    n = n.copyWith(entries: [], omitted: {projected.id});
    expect(NutritionData.fromJson(n.toJson()).entriesOn(day), isEmpty);
    expect(template.copyWith(until: day).plannedOn(day.addDays(2)), isEmpty);
    expect(n.templates.single.foods.single.grams, 150);
  });
  test('skill trees reject cycles and cross-tree parents; deleting a node reparents children', () {
    const root = SkillNode(id: 'a', title: 'A');
    const child = SkillNode(id: 'b', title: 'B', parentId: 'a');
    const leaf = SkillNode(id: 'c', title: 'C', parentId: 'b');
    final tree = SkillTreeData(nodes: [root, child, leaf]);
    expect(tree.descendants('a'), {'b', 'c'});
    expect(tree.without('b').nodes.last.parentId, 'a');
    expect(
      () => SkillTreeData(nodes: [root.reparent('c'), child, leaf]),
      throwsFormatException,
    );
    expect(
      () => SkillTreeData(
        nodes: [
          root,
          const SkillNode(
            id: 'b',
            title: 'B',
            parentId: 'a',
            kind: SkillTreeKind.passive,
          ),
        ],
      ),
      throwsFormatException,
    );
    expect(SkillTreeData.fromJson(tree.toJson()).nodes.last.parentId, 'b');
  });
  test('passive unlocks use actual task base XP and require parent; no health/settings XP', () async {
    final c = TaskController(
      store: MemoryTaskStore(),
      clock: () => DateTime(2026, 11, 9),
    );
    await c.load();
    final task = c.addTask(
      title: 'Sport',
      rule: const DailyRule(),
      start: c.today,
      baseXp: 100,
    );
    c.updateLife(
      c.data.life.copyWith(
        links: {task.id: const TaskLink(area: LifeArea.body)},
      ),
    );
    const root = SkillNode(
      id: 'a',
      title: 'Sport starter',
      kind: SkillTreeKind.passive,
      area: LifeArea.body,
      minLevel: 2,
    );
    const child = SkillNode(
      id: 'b',
      title: 'Sport path',
      kind: SkillTreeKind.passive,
      area: LifeArea.body,
      minLevel: 2,
      parentId: 'a',
    );
    final tree = SkillTreeData(nodes: [root, child]);
    expect(tree.unlocked(child, areaXp(c.data, c.today)), false);
    c.toggle(task.id, c.today);
    expect(areaXp(c.data, c.today)[LifeArea.body], 100);
    expect(tree.unlocked(child, areaXp(c.data, c.today)), true);
    c.toggle(task.id, c.today);
    expect(tree.unlocked(child, areaXp(c.data, c.today)), false);
    c.dispose();
  });
}
