import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/settings.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';
import 'package:reallife_rpg/src/ui/app.dart';

class SlowSettingsStore extends MemoryTaskStore {
  @override
  Future<void> saveSettings(AppSettings value) async {
    if (value.effectiveNavigationOrder.first == 'courses') {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
    await super.saveSettings(value);
  }
}

void main() {
  test('old and malformed orders append missing pages and exclude fixed/removed pages', () {
    final settings = AppSettings.decode(
      jsonEncode({
        'navigation_order': [
          'courses',
          'ayarlar',
          'odak',
          'courses',
          'atlas',
          12,
          'unknown',
          'gun',
        ],
      }),
    );
    expect(settings.effectiveNavigationOrder.take(2), ['courses', 'gun']);
    expect(
      settings.effectiveNavigationOrder.toSet(),
      AppSettings.defaultNavigationOrder.toSet(),
    );
    expect(
      settings.effectiveNavigationOrder.length,
      AppSettings.defaultNavigationOrder.length,
    );
    expect(
      AppSettings.decode('{}').effectiveNavigationOrder,
      AppSettings.defaultNavigationOrder,
    );
    expect(
      AppSettings.decode(settings.copyWith(themeId: 'aion_gece').encode())
          .effectiveNavigationOrder,
      settings.effectiveNavigationOrder,
    );
  });

  test(
    'rapid settings writes finish in order without creating task data',
    () async {
      final store = SlowSettingsStore();
      final c = TaskController(store: store);
      await c.load();
      final first = c.updateSettings(
        c.settings.copyWith(navigationOrder: ['courses']),
      );
      final last = c.updateSettings(
        c.settings.copyWith(navigationOrder: ['nutrition']),
      );
      await Future.wait([first, last]);
      final reopened = TaskController(store: store);
      await reopened.load();
      expect(reopened.settings.effectiveNavigationOrder.first, 'nutrition');
      expect(store.saved, isNull);
      expect(c.data.completions, isEmpty);
      reopened.dispose();
      c.dispose();
    },
  );

  for (final language in ['tr', 'en']) {
    for (final phone in [false, true]) {
      testWidgets(
        'menu drag, keyboard, fixed Settings and restart ($language, phone=$phone)',
        (t) async {
          t.view.physicalSize = phone
              ? const Size(390, 844)
              : const Size(1440, 1100);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          final store = MemoryTaskStore()
            ..settings = AppSettings(
              languageCode: language,
              uiScale: phone ? 2 : 1,
              textScale: phone ? 1.2 : 1,
              appearance: const Appearance(font: 'dyslexic'),
            );
          final c = TaskController(store: store);
          await c.load();
          await t.pumpWidget(
            RealLifeRPGApp(controller: c, initialPage: 'maceram'),
          );
          await t.pumpAndSettle();
          if (phone) {
            await t.tap(find.byType(DrawerButton));
            await t.pumpAndSettle();
          }
          expect(find.byKey(const Key('nav-odak')), findsNothing);
          expect(find.byKey(const Key('nav-atlas')), findsNothing);
          Offset point(String id) => t
              .getRect(find.byKey(Key('nav-$id')))
              .intersect(Offset.zero & t.view.physicalSize)
              .center;
          final pinned = t.getRect(find.byKey(const Key('nav-ayarlar')));
          final origin = point('maceram'),
              target = point('gun') + const Offset(0, 20);
          final gesture = await t.createGesture(
            kind: phone ? PointerDeviceKind.touch : PointerDeviceKind.mouse,
          );
          await gesture.down(origin);
          if (phone) await t.pump(const Duration(milliseconds: 600));
          for (var i = 1; i <= 12; i++) {
            await gesture.moveTo(Offset.lerp(origin, target, i / 12)!);
            await t.pump(const Duration(milliseconds: 60));
          }
          await gesture.up();
          await t.pumpAndSettle();
          expect(c.settings.effectiveNavigationOrder.take(2), [
            'gun',
            'maceram',
          ]);
          expect(t.getRect(find.byKey(const Key('nav-ayarlar'))), pinned);
          expect(
            t.widget<ListTile>(find.byKey(const Key('nav-maceram'))).selected,
            isTrue,
          );

          t
              .widget<ListTile>(find.byKey(const Key('nav-maceram')))
              .focusNode!
              .requestFocus();
          await t.pump();
          await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await t.pumpAndSettle();
          expect(c.settings.effectiveNavigationOrder.take(2), [
            'maceram',
            'gun',
          ]);

          // Reorder while Character is hidden; its saved slot must survive.
          await c.updateSettings(
            c.settings.copyWith(
              gameMode: false,
              navigationOrder: ['courses', 'gun', 'maceram'],
            ),
          );
          await t.pumpAndSettle();
          final second = TaskController(store: store);
          await second.load();
          expect(second.settings.effectiveNavigationOrder.first, 'courses');
          expect(
            second.settings.effectiveNavigationOrder.contains('karakter'),
            isTrue,
          );
          expect(second.settings.languageCode, language);
          expect(second.settings.appearance.font, 'dyslexic');
          expect(second.settings.uiScale, phone ? 2 : 1);
          expect(c.data.completions, isEmpty);
          expect(c.profile.totalXp, 0);
          expect(store.saved, isNull);
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
          second.dispose();
          c.dispose();
        },
      );
    }
  }
}
