import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/domain/codec.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';
import 'package:reallife_rpg/src/ui/app.dart';
import 'package:reallife_rpg/src/ui/task_actions.dart';

void main() {
  testWidgets(
    'XP slider accepts real mouse and keyboard; save, edit and cancel preserve data',
    (t) async {
      t.view.physicalSize = const Size(1400, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final store = MemoryTaskStore();
      final c = TaskController(
        store: store,
        clock: () => DateTime(2026, 11, 9, 10),
      );
      await c.load();
      await t.pumpWidget(RealLifeRPGApp(controller: c, initialPage: 'gun'));
      await t.pumpAndSettle();
      final context = t.element(find.byType(Scaffold).first);
      final opened = addTaskWithEditor(context, c, start: c.today);
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('editor-title')), 'XP test');
      final slider = find.byKey(const Key('editor-difficulty'));
      await t.ensureVisible(slider);
      await t.pumpAndSettle();
      expect(t.widget<Slider>(slider).divisions, 100);
      final rect = t.getRect(slider);
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: rect.center);
      await mouse.down(rect.center);
      await mouse.moveTo(Offset(rect.left + rect.width * .73, rect.center.dy));
      await mouse.up();
      await t.pumpAndSettle();
      final dragged = t.widget<Slider>(slider).value.round();
      expect(dragged, inInclusiveRange(60, 85));
      await t.sendKeyEvent(LogicalKeyboardKey.home);
      await t.pumpAndSettle();
      expect(t.widget<Slider>(slider).value, 0);
      await t.sendKeyEvent(LogicalKeyboardKey.end);
      await t.pumpAndSettle();
      expect(t.widget<Slider>(slider).value, 100);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await t.pumpAndSettle();
      expect(t.widget<Slider>(slider).value, 99);
      // Autorepeat must not lose increments while several keys share a frame.
      for (int i = 0; i < 26; i++) {
        await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      }
      await t.pumpAndSettle();
      expect(t.widget<Slider>(slider).value, 73);
      await t.ensureVisible(find.byKey(const Key('editor-save')));
      await t.tap(find.byKey(const Key('editor-save')));
      await t.pumpAndSettle();
      await opened;
      expect(c.data.tasks.single.baseXp, 73);
      expect(c.profile.totalXp, 0);
      await c.saved;
      expect(decodeTaskData(store.saved!).tasks.single.baseXp, 73);
      final edited = editTask(context, c, c.data.tasks.single);
      await t.pumpAndSettle();
      expect(t.widget<Slider>(slider).value, 73);
      await t.tap(find.text('İptal'));
      await t.pumpAndSettle();
      await edited;
      expect(c.data.tasks.single.baseXp, 73);
      expect(c.data.completions, isEmpty);
      await mouse.removePointer();
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
