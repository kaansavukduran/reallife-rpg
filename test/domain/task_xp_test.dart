import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/domain/codec.dart';
import 'package:reallife_rpg/src/domain/game.dart';
import 'package:reallife_rpg/src/domain/repeat_rule.dart';
import 'package:reallife_rpg/src/domain/task.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';

void main() {
  test(
    'all 101 XP choices persist, zero earns no XP, late ticks earn exact base',
    () async {
      final store = MemoryTaskStore();
      var now = DateTime(2026, 11, 9, 12);
      final c = TaskController(store: store, clock: () => now);
      await c.load();
      final task = c.addTask(
        title: 'Read',
        rule: const DailyRule(),
        start: c.today,
        baseXp: 0,
      );
      expect(c.profile.totalXp, 0);
      c.toggle(task.id, c.today);
      expect(c.profile.totalXp, 0);
      for (var xp = 0; xp <= 100; xp++) {
        c.updateTask(task.id, title: task.title, baseXp: xp);
        expect(c.data.taskById(task.id)!.baseXp, xp);
        expect(
          c.profile.totalXp,
          0,
          reason: 'Changing XP never rewrites the zero-XP completion',
        );
        expect(
          GameRules.xpFor(
            difficulty: Difficulty.orta,
            baseXp: xp,
            onTime: false,
            streak: 20,
          ),
          xp,
        );
      }
      c.updateTask(task.id, title: task.title, baseXp: 73);
      await c.saved;
      final reopened = TaskController(store: store, clock: () => now);
      await reopened.load();
      expect(reopened.data.tasks.single.baseXp, 73);
      now = now.add(const Duration(days: 1));
      reopened.refreshToday();
      reopened.toggle(task.id, reopened.today);
      expect(reopened.data.tasks.single.baseXp, 73);
      c.dispose();
      reopened.dispose();
    },
  );
  test(
    'old easy medium hard backups retain 10/20/35, invalid XP rejected',
    () async {
      final c = TaskController(
        store: MemoryTaskStore(),
        clock: () => DateTime(2026, 11, 9),
      );
      await c.load();
      for (final d in Difficulty.values) {
        final t = c.addTask(
          title: 'Legacy',
          rule: const DailyRule(),
          start: c.today,
          difficulty: d,
        );
        final raw = t.toJson()..remove('base_xp');
        expect(Task.fromJson(raw).baseXp, d.baseXp);
        for (final invalid in [-1, 101, 1.5, '50', null]) {
          expect(
            () => Task.fromJson({...raw, 'base_xp': invalid}),
            throwsFormatException,
          );
        }
        expect(() => t.copyWith(baseXp: 101), throwsArgumentError);
      }
      final raw = jsonDecode(
        encodeTaskData(c.data, savedAt: DateTime.now()),
      ) as Map<String, dynamic>;
      raw['schema_version'] = 2;
      raw.remove('life');
      for (final task in raw['tasks'] as List) {
        (task as Map).remove('base_xp');
      }
      expect(decodeTaskData(jsonEncode(raw)).tasks.map((t) => t.baseXp), [
        10,
        20,
        35,
      ]);
      c.dispose();
    },
  );
}
