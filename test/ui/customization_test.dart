import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/settings.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/domain/repeat_rule.dart';
import 'package:reallife_rpg/src/domain/task.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';
import 'package:reallife_rpg/src/ui/app.dart';
import 'package:reallife_rpg/src/ui/appearance_settings.dart';
import 'package:reallife_rpg/src/ui/themes.dart';

Future<TaskController> start(
  WidgetTester tester,
  String page, {
  MemoryTaskStore? store,
}) async {
  tester.view.physicalSize = const Size(1200, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final c = TaskController(
    store:
        store ??
        (MemoryTaskStore()..settings = const AppSettings(gameMode: false)),
  );
  await c.load();
  await tester.pumpWidget(RealLifeRPGApp(controller: c, initialPage: page));
  await tester.pumpAndSettle();
  return c;
}

Future<void> mouseDrag(WidgetTester tester, Finder from, Finder to) async {
  final origin = tester.getCenter(from);
  final target = tester.getCenter(to) + const Offset(0, 60);
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.down(origin);
  for (var step = 1; step <= 12; step++) {
    await gesture.moveTo(Offset.lerp(origin, target, step / 12)!);
    await tester.pump(const Duration(milliseconds: 60));
  }
  await tester.pump(const Duration(milliseconds: 300));
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('quick add accepts a task time on a zoomed phone', (
    tester,
  ) async {
    final store = MemoryTaskStore()
      ..settings = const AppSettings(gameMode: false, uiScale: 2);
    final c = await start(tester, 'gun', store: store);
    tester.view.physicalSize = const Size(360, 1000);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('quick-time')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quick-time')));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), '07');
    await tester.enterText(fields.at(1), '30');
    await tester.ensureVisible(find.text('Seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seç'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsNothing);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(
      find.byKey(const Key('quick-add-field')),
      'Sabah yürüyüşü',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(c.data.tasks.single.time, ClockTime(7, 30));
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets(
    'time sorting is optional and leaves the stored manual order intact',
    (tester) async {
      final c = await start(tester, 'gun');
      c.addTask(
        title: 'Akşam görevi',
        rule: const DailyRule(),
        start: c.today,
        time: ClockTime(18, 30),
      );
      c.addTask(
        title: 'Sabah görevi',
        rule: const DailyRule(),
        start: c.today,
        time: ClockTime(8, 0),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Akşam görevi')).dy,
        lessThan(tester.getTopLeft(find.text('Sabah görevi')).dy),
      );
      await tester.tap(find.byKey(const Key('sort-by-time')));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Sabah görevi')).dy,
        lessThan(tester.getTopLeft(find.text('Akşam görevi')).dy),
      );
      expect(c.data.tasks.first.title, 'Akşam görevi');
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  for (final page in ['gun', 'gorevler']) {
    testWidgets('mouse drags task card and persists order on $page', (
      tester,
    ) async {
      final c = await start(tester, page);
      final first = c.addTask(
        title: 'İlk adım',
        rule: const DailyRule(),
        start: c.today,
      );
      final hidden = c.addTask(
        title: 'Sonlandırılmış',
        rule: const DailyRule(),
        start: c.today,
      );
      c.endTask(hidden.id);
      final last = c.addTask(
        title: 'İkinci adım',
        rule: const DailyRule(),
        start: c.today,
      );
      await tester.pumpAndSettle();
      await mouseDrag(tester, find.text('İlk adım'), find.text('İkinci adım'));
      expect(c.data.tasks.map((t) => t.id), [last.id, hidden.id, first.id]);
      expect(c.data.completions, isEmpty);
      await c.saved;
      final reopened = TaskController(store: c.store);
      await reopened.load();
      expect(reopened.data.tasks.map((t) => t.id), [
        last.id,
        hidden.id,
        first.id,
      ]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      reopened.dispose();
    });
  }
  testWidgets('24 hour keyboard entry saves task time', (tester) async {
    final c = await start(tester, 'gorevler');
    final task = c.addTask(
      title: 'Saatli görev',
      rule: const DailyRule(),
      start: c.today,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saatli görev'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('editor-time')));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextField),
    );
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), '18');
    await tester.enterText(fields.at(1), '45');
    await tester.tap(find.text('Seç'));
    await tester.pumpAndSettle();
    expect(find.text('18:45'), findsOneWidget);
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(c.data.taskById(task.id)!.time, ClockTime(18, 45));
    await c.saved;
    final reopened = TaskController(store: c.store);
    await reopened.load();
    expect(reopened.data.taskById(task.id)!.time, ClockTime(18, 45));
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    reopened.dispose();
  });
  testWidgets(
    'HEX color applies, cancel preserves selection, reset restores preset',
    (tester) async {
      final c = await start(tester, 'ayarlar');
      await tester.dragUntilVisible(
        find.byKey(const Key('color-primary')),
        find.byType(ListView).first,
        const Offset(0, -250),
      );
      await tester.ensureVisible(find.byKey(const Key('color-primary')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('color-primary')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('color-hex')), 'XYZ');
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('color-apply')))
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byKey(const Key('color-hex')), '7C5CFC');
      await tester.pump();
      await tester.tap(find.byKey(const Key('color-apply')));
      await tester.pumpAndSettle();
      expect(c.settings.appearance.primary, 0xff7c5cfc);
      expect(
        (c.store as MemoryTaskStore).settings.appearance.primary,
        0xff7c5cfc,
      );
      final ctx = tester.element(find.byKey(const Key('color-primary')));
      expect(Theme.of(ctx).colorScheme.primary, const Color(0xff7c5cfc));
      await tester.tap(find.byKey(const Key('color-primary')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('color-hex')), 'FF0000');
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(c.settings.appearance.primary, 0xff7c5cfc);
      await tester.tap(find.byKey(const Key('color-reset-primary')));
      await tester.pumpAndSettle();
      expect(c.settings.appearance.primary, isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets('color field supports pointer dragging at phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Color? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                chosen = await showColorPicker(
                  context,
                  initial: Colors.red,
                  title: 'Renk',
                );
              },
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('color-field')),
      const Offset(35, 45),
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('color-apply')));
    await tester.tap(find.byKey(const Key('color-apply')));
    await tester.pumpAndSettle();
    expect(chosen, isNotNull);
    expect(chosen, isNot(Colors.red));
    expect(tester.takeException(), isNull);
  });
  test('appearance settings survive restart and old files use defaults', () {
    final original = const AppSettings(
      appearance: Appearance(
        primary: 0xff7c5cfc,
        secondary: 0xffe09c55,
        background: 0xff171923,
        surface: 0xff232637,
        radius: 28,
        font: 'mono',
        compact: true,
        reduceMotion: true,
      ),
    );
    final loaded = AppSettings.decode(original.encode());
    expect(loaded.appearance.toJson(), original.appearance.toJson());
    expect(
      AppSettings.decode('{}').appearance.toJson(),
      const Appearance().toJson(),
    );
    expect(
      Appearance.decode({'primary': -1, 'radius': 100, 'font': 'bad'}).primary,
      isNull,
    );
    expect(Appearance.decode({'radius': 100}).radius, 32);
    final spec = customizedTheme(themeById('bahce'), loaded.appearance);
    final theme = buildTheme(spec, appearance: loaded.appearance);
    expect(spec.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, const Color(0xff7c5cfc));
    expect(spec.radius, 28);
  });
}
