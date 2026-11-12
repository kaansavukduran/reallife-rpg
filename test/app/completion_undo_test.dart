import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/domain/repeat_rule.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';

void main() {
  test(
    'undo restores the original timestamp and reward, preserving later edits',
    () async {
      final store = MemoryTaskStore();
      final c = TaskController(
        store: store,
        clock: () => DateTime(2026, 11, 12, 14),
      );
      await c.load();
      final task = c.addTask(
        title: 'Okuma',
        rule: const DailyRule(),
        start: c.today,
        baseXp: 7,
      );
      c.toggle(task.id, c.today);
      final originalXp = c.profile.totalXp;
      final before = c.data;
      c.toggle(task.id, c.today);
      final after = c.data;
      c.updateTask(task.id, title: 'Yeni ad', baseXp: 90);
      final other = c.addTask(
        title: 'Başka iş',
        rule: const DailyRule(),
        start: c.today,
      );
      c.toggle(other.id, c.today.addDays(-1));
      expect(
        c.undoTick(task.id, c.today, before: before, after: after),
        isTrue,
      );
      expect(c.data.doneAt(task.id, c.today), before.doneAt(task.id, c.today));
      expect(c.data.rewardXp[task.id]![c.today], 7);
      expect(c.data.taskById(task.id)!.title, 'Yeni ad');
      expect(c.data.taskById(task.id)!.baseXp, 90);
      expect(c.data.isDone(other.id, c.today.addDays(-1)), isTrue);
      expect(c.profile.totalXp, greaterThanOrEqualTo(originalXp));
      await c.saved;
      final reopened = TaskController(
        store: store,
        clock: () => DateTime(2026, 11, 12, 14),
      );
      await reopened.load();
      expect(reopened.data.rewardXp[task.id]![c.today], 7);
      expect(reopened.data.isDone(other.id, c.today.addDays(-1)), isTrue);
      c.dispose();
      reopened.dispose();
    },
  );

  test(
    'stale undo cannot reverse a newer tick, step change or deletion',
    () async {
      var now = DateTime(2026, 11, 12, 14);
      final c = TaskController(store: MemoryTaskStore(), clock: () => now);
      await c.load();
      final task = c.addTask(
        title: 'Okuma',
        rule: const DailyRule(),
        start: c.today,
        steps: ['Bir adım'],
      );
      final before = c.data;
      c.toggle(task.id, c.today);
      final after = c.data;
      c.toggle(task.id, c.today);
      now = now.add(const Duration(minutes: 1));
      c.toggle(task.id, c.today);
      expect(
        c.undoTick(task.id, c.today, before: before, after: after),
        isFalse,
      );
      final stepBefore = c.data;
      c.toggle(task.id, c.today);
      final stepAfter = c.data;
      c.toggleStep(task.id, c.today, task.steps.single.id);
      expect(
        c.undoTick(task.id, c.today, before: stepBefore, after: stepAfter),
        isFalse,
      );
      c.deleteTask(task.id);
      expect(
        c.undoTick(task.id, c.today, before: before, after: after),
        isFalse,
      );
      c.dispose();
    },
  );
}
