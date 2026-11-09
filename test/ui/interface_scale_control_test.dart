import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/settings.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';
import 'package:reallife_rpg/src/ui/app.dart';

Future<TaskController> settingsApp(
  WidgetTester tester, {
  Size size = const Size(1600, 1200),
  MemoryTaskStore? store,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = TaskController(store: store ?? MemoryTaskStore());
  await controller.load();
  await tester.pumpWidget(
    RealLifeRPGApp(controller: controller, initialPage: 'ayarlar'),
  );
  await tester.pumpAndSettle();
  return controller;
}

Future<void> enterPercent(WidgetTester tester, String value) async {
  final field = find.byKey(const Key('interface-scale-percent'));
  await tester.enterText(field, value);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'mouse drags both ways, previews without track movement, then persists',
    (tester) async {
      final store = MemoryTaskStore();
      final controller = await settingsApp(tester, store: store);
      final slider = find.byKey(const Key('interface-scale-slider'));
      final widget = tester.widget<Slider>(slider);
      expect(widget.min, AppSettings.minScale * 100);
      expect(widget.max, AppSettings.maxScale * 100);
      expect(widget.divisions, 120);
      expect(find.byKey(const Key('scale-150')), findsNothing);
      final rect = tester.getRect(slider);
      Offset at(double fraction) =>
          Offset(rect.left + 24 + (rect.width - 48) * fraction, rect.center.dy);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.down(at(20 / 120));
      await tester.pump();
      await mouse.moveTo(at(42 / 120));
      await tester.pump();
      final middle = tester.widget<Slider>(slider).value;
      await mouse.moveTo(at(92 / 120));
      await tester.pump();
      expect(tester.widget<Slider>(slider).value, greaterThan(middle));
      await mouse.moveTo(at(57 / 120));
      await tester.pump();
      final preview = tester.widget<Slider>(slider).value.round();
      expect(preview, isNot(isIn([80, 100, 125, 150, 175, 200])));
      expect(find.text('Arayüz ölçeği: %$preview'), findsOneWidget);
      expect(controller.settings.uiScale, 1);
      expect(store.settings.uiScale, 1);
      expect(tester.getRect(slider), rect);
      await mouse.up();
      await tester.pumpAndSettle();
      expect(controller.settings.uiScale, preview / 100);
      expect(store.settings.uiScale, preview / 100);
      final reopened = TaskController(store: store);
      await reopened.load();
      expect(reopened.settings.uiScale, preview / 100);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      reopened.dispose();
    },
  );

  testWidgets(
    'exact 137 percent entry survives restart and reset restores 100',
    (tester) async {
      final store = MemoryTaskStore();
      final controller = await settingsApp(tester, store: store);
      await enterPercent(tester, '137');
      expect(controller.settings.uiScale, 1.37);
      expect(
        tester
            .widget<Slider>(find.byKey(const Key('interface-scale-slider')))
            .value,
        137,
      );
      expect(AppSettings.decode(store.settings.encode()).uiScale, 1.37);
      await tester.tap(find.byKey(const Key('scale-reset')));
      await tester.pumpAndSettle();
      expect(store.settings.uiScale, 1);
      expect(find.text('Arayüz ölçeği: %100'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );

  testWidgets(
    'invalid percentages do not alter saved scale and Escape restores it',
    (tester) async {
      final controller = await settingsApp(tester);
      for (final value in ['', '79', '201', 'abc', '137.5']) {
        await enterPercent(tester, value);
        expect(controller.settings.uiScale, 1);
        expect(find.text('80–200 arasında tam sayı gir.'), findsOneWidget);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Arayüz ölçeği: %100'), findsOneWidget);
      expect(find.text('80–200 arasında tam sayı gir.'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );

  for (final width in [360.0, 1600.0]) {
    testWidgets('slider endpoints remain usable at width $width', (
      tester,
    ) async {
      final controller = await settingsApp(tester, size: Size(width, 1200));
      await enterPercent(tester, '200');
      expect(controller.settings.uiScale, 2);
      expect(tester.takeException(), isNull);
      await enterPercent(tester, '80');
      expect(controller.settings.uiScale, .8);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
  }
}
