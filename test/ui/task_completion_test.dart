import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/settings.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/domain/codec.dart';
import 'package:reallife_rpg/src/domain/repeat_rule.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';
import 'package:reallife_rpg/src/ui/app.dart';

void main() {
  for (final phone in [false, true]) {
    testWidgets(
      'all tasks supports direct completion, history and restart (phone=$phone)',
      (t) async {
        t.view.physicalSize = phone
            ? const Size(390, 844)
            : const Size(1440, 1100);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final store = MemoryTaskStore()
          ..settings = AppSettings(gameMode: false, uiScale: phone ? 2 : 1);
        final c = TaskController(
          store: store,
          clock: () => DateTime(2026, 11, 9, 15),
        );
        await c.load();
        final task = c.addTask(
          title: 'Okuma',
          rule: const DailyRule(),
          start: c.today.addDays(-3),
          baseXp: 7,
        );
        await t.pumpWidget(
          RealLifeRPGApp(controller: c, initialPage: 'gorevler'),
        );
        await t.pumpAndSettle();
        Future<void> reveal(Finder f, {bool up = false}) async {
          for (var i = 0; i < 12 && f.evaluate().isEmpty; i++) {
            final viewport = t
                .getRect(find.byType(CustomScrollView).last)
                .intersect(Offset.zero & t.view.physicalSize);
            await t.dragFrom(viewport.center, Offset(0, up ? 160 : -160));
            await t.pumpAndSettle();
          }
          await t.ensureVisible(f);
          await t.pumpAndSettle();
        }

        final check = find.byKey(Key('tasks-check-${task.id}'));
        await reveal(check);
        await t.pumpAndSettle();
        if (phone) {
          await t.tap(check);
        } else {
          final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
          await mouse.addPointer(location: t.getCenter(check));
          await mouse.down(t.getCenter(check));
          await mouse.up();
          await mouse.removePointer();
        }
        await t.pumpAndSettle();
        expect(c.data.isDone(task.id, c.today), isTrue);
        expect(find.byKey(const Key('task-title-field')), findsNothing);
        expect(t.widget<Checkbox>(check).value, isTrue);
        final xp = c.profile.totalXp;
        expect(xp, greaterThan(0));
        await c.saved;
        expect(decodeTaskData(store.saved!).isDone(task.id, c.today), isTrue);

        // A card click keeps editing separate from the nested checkbox.
        await reveal(find.text('Okuma').last);
        await t.pumpAndSettle();
        await t.tap(find.text('Okuma').last);
        await t.pumpAndSettle();
        expect(find.text('Görevi düzenle'), findsOneWidget);
        await t.tap(find.text('İptal').last);
        await t.pumpAndSettle();
        expect(c.profile.totalXp, xp);

        Future<void> selectDay(String day) async {
          final date = find.byKey(const Key('tasks-completion-date'));
          await reveal(date, up: true);
          await t.tap(date);
          await t.pumpAndSettle();
          final input = find.descendant(
            of: find.byKey(const Key('task-date-dialog')),
            matching: find.byType(TextField),
          );
          if (input.evaluate().isNotEmpty) {
            final text = MaterialLocalizations.of(t.element(input))
                .formatCompactDate(DateTime(2026, 11, int.parse(day)));
            await t.enterText(input, text);
          } else {
            await t.ensureVisible(find.text(day).last);
            await t.pumpAndSettle();
            await t.tap(find.text(day).last);
          }
          await t.ensureVisible(find.text('Seç').last);
          await t.pumpAndSettle();
          await t.tap(find.text('Seç').last);
          await t.pumpAndSettle();
        }

        await selectDay('8');
        await reveal(check);
        await t.tap(check);
        await t.pumpAndSettle();
        expect(c.data.isDone(task.id, c.today.addDays(-1)), isTrue);
        expect(c.data.isDone(task.id, c.today), isTrue);
        final afterHistory = c.profile.totalXp;
        await selectDay('10');
        await reveal(check);
        expect(t.widget<Checkbox>(check).onChanged, isNull);
        expect(c.profile.totalXp, afterHistory);
        await reveal(find.byKey(const Key('tasks-today')), up: true);
        await t.tap(find.byKey(const Key('tasks-today')));
        await t.pumpAndSettle();
        await reveal(check);
        if (!phone) {
          // Reach the checkbox using ordinary keyboard traversal and toggle it.
          bool reached = false;
          for (var i = 0; i < 20; i++) {
            await t.sendKeyEvent(LogicalKeyboardKey.tab);
            await t.pump();
            final focus = FocusManager.instance.primaryFocus?.context;
            if (focus != null &&
                focus.findAncestorWidgetOfExactType<Checkbox>() != null) {
              reached = true;
              break;
            }
          }
          expect(reached, isTrue);
          await t.sendKeyEvent(LogicalKeyboardKey.space);
        } else {
          await t.tap(check);
        }
        await t.pumpAndSettle();
        expect(c.data.isDone(task.id, c.today), isFalse);
        expect(c.data.isDone(task.id, c.today.addDays(-1)), isTrue);
        await c.saved;
        await t.pumpWidget(const SizedBox());
        c.dispose();
        final reopened = TaskController(
          store: store,
          clock: () => DateTime(2026, 11, 9, 15),
        );
        await reopened.load();
        expect(reopened.data.isDone(task.id, reopened.today), isFalse);
        expect(
          reopened.data.isDone(task.id, reopened.today.addDays(-1)),
          isTrue,
        );
        expect(reopened.data.tasks.single.id, task.id);
        expect(t.takeException(), isNull);
        reopened.dispose();
      },
    );
  }
}
