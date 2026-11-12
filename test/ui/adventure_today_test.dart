import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/settings.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/domain/repeat_rule.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';
import 'package:reallife_rpg/src/ui/app.dart';
import 'package:reallife_rpg/src/ui/today_task_card.dart';

void main() {
  for (final english in [false, true]) {
    testWidgets('first minute: create, tick, undo, reopen (English=$english)', (
      t,
    ) async {
      t.view.physicalSize = const Size(1440, 1100);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final store = MemoryTaskStore()
        ..settings = AppSettings(
          languageCode: english ? 'en' : 'tr',
          gameMode: false,
        );
      final c = TaskController(
        store: store,
        clock: () => DateTime(2026, 11, 12, 14),
      );
      await c.load();
      await t.pumpWidget(RealLifeRPGApp(controller: c, initialPage: 'maceram'));
      await t.pumpAndSettle();
      expect(c.data.tasks, isEmpty);
      expect(c.profile.totalXp, 0);
      expect(store.saved, isNull);
      expect(
        find.textContaining(english ? 'Use New task' : 'Yeni görev düğmesiyle'),
        findsOneWidget,
      );
      await t.tap(find.text(english ? 'New task' : 'Yeni görev'));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('editor-title')), 'Bir sayfa oku');
      expect(find.text(english ? 'Task name' : 'Görev adı'), findsOneWidget);
      await t.ensureVisible(find.byKey(const Key('editor-save')));
      await t.tap(find.byKey(const Key('editor-save')));
      await t.pumpAndSettle();
      final task = c.data.tasks.single;
      final check = find.byKey(ValueKey('adventure-check-${task.id}'));
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: t.getCenter(check));
      await mouse.down(t.getCenter(check));
      await mouse.up();
      await mouse.removePointer();
      await t.pumpAndSettle();
      expect(c.data.isDone(task.id, c.today), isTrue);
      expect(t.widget<Checkbox>(check).value, isTrue);
      expect(
        find.text(
          english ? 'Done · open to edit' : 'Tamamlandı · düzenlemek için aç',
        ),
        findsOneWidget,
      );
      await t.tap(find.text(english ? 'Undo' : 'Geri al'));
      await t.pumpAndSettle();
      expect(c.data.isDone(task.id, c.today), isFalse);
      expect(c.profile.totalXp, 0);
      // Keyboard traversal reaches the same persistent checkbox.
      for (var i = 0; i < 35; i++) {
        await t.sendKeyEvent(LogicalKeyboardKey.tab);
        await t.pump();
        if (FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<Checkbox>() !=
            null) {
          break;
        }
      }
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<Checkbox>(),
        isNotNull,
      );
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pumpAndSettle();
      expect(c.data.isDone(task.id, c.today), isTrue);
      // The same control keeps focus after completion; Space can untick it.
      await t.sendKeyEvent(LogicalKeyboardKey.space);
      await t.pumpAndSettle();
      expect(c.data.isDone(task.id, c.today), isFalse);
      await c.saved;
      await t.pumpWidget(const SizedBox());
      final second = TaskController(
        store: store,
        clock: () => DateTime(2026, 11, 12, 14),
      );
      await second.load();
      expect(second.data.tasks.single.title, 'Bir sayfa oku');
      expect(second.data.isDone(task.id, second.today), isFalse);
      c.dispose();
      second.dispose();
    });
  }

  testWidgets('phone at 200%, long titles, four stable rows and honest count', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final c = TaskController(
      store: MemoryTaskStore()
        ..settings = const AppSettings(
          uiScale: 2,
          textScale: 1.3,
          languageCode: 'en',
          appearance: Appearance(reduceMotion: true, font: 'dyslexic'),
        ),
    );
    await c.load();
    for (var i = 0; i < 5; i++) {
      c.addTask(
        title: 'A long task title that wraps instead of losing its meaning $i',
        rule: const DailyRule(),
        start: c.today,
      );
    }
    await t.pumpWidget(RealLifeRPGApp(controller: c, initialPage: 'maceram'));
    await t.pumpAndSettle();
    final check = find.byKey(
      ValueKey('adventure-check-${c.data.tasks.first.id}'),
    );
    for (var i = 0; i < 12 && check.evaluate().isEmpty; i++) {
      await t.drag(find.byType(ListView).last, const Offset(0, -200));
      await t.pumpAndSettle();
    }
    await t.ensureVisible(check);
    await t.pumpAndSettle();
    await t.tap(check);
    await t.pumpAndSettle();
    expect(t.widget<Checkbox>(check).value, isTrue);
    expect(
      find.descendant(
        of: find.byType(TodayTaskCard),
        matching: find.byType(Checkbox),
      ),
      findsNWidgets(4),
    );
    final count = find.textContaining('Showing the first 4 / 5');
    await t.ensureVisible(count);
    expect(count, findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets(
    'task card meets labels, contrast and Android touch target guidelines',
    (t) async {
      final semantics = t.ensureSemantics();

      final c = TaskController(store: MemoryTaskStore());
      await c.load();
      c.addTask(title: 'Okuma', rule: const DailyRule(), start: c.today);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodayTaskCard(controller: c, openDay: () {}),
          ),
        ),
      );
      await t.pumpAndSettle();
      final control = t.getSemantics(find.byType(Checkbox));
      expect(control.rect.width, 48);
      expect(control.rect.height, 48);
      await expectLater(t, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      await expectLater(t, meetsGuideline(textContrastGuideline));
      semantics.dispose();
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
