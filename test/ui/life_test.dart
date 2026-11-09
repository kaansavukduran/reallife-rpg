import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/app/settings.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';
import 'package:reallife_rpg/src/ui/app.dart';

void main() {
  for (final page in [
    'maceram',
    'projeler',
    'yetenekler',
    'saglik',
    'odak',
    'atlas',
    'karakter',
  ]) {
    for (final width in [360.0, 1200.0]) {
      testWidgets('$page is usable at $width', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final c = TaskController(store: MemoryTaskStore());
        await c.load();
        await tester.pumpWidget(
          RealLifeRPGApp(controller: c, initialPage: page),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        c.dispose();
      });
    }
  }
  testWidgets('health entry saves and survives screen navigation', (
    tester,
  ) async {
    final store = MemoryTaskStore(),
        c = TaskController(store: MemoryTaskStore());
    await c.load();
    await tester.pumpWidget(
      RealLifeRPGApp(controller: c, initialPage: 'saglik'),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byTooltip('Bir bardak su ekle'),
      find.byType(ListView).last,
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Bir bardak su ekle'));
    await tester.pumpAndSettle();
    expect(c.data.life.health[c.today.toIso()]!.water, 1);
    await c.saved;
    store.saved = (c.store as MemoryTaskStore).saved;
    final second = TaskController(store: store);
    await second.load();
    expect(second.data.life.health[c.today.toIso()]!.water, 1);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    second.dispose();
  });
  testWidgets('game mode can be disabled on the adventure screen', (
    tester,
  ) async {
    final store = MemoryTaskStore()
      ..settings = const AppSettings(gameMode: false);
    final c = TaskController(store: store);
    await c.load();
    await tester.pumpWidget(
      RealLifeRPGApp(controller: c, initialPage: 'maceram'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Deneyim puanı'), findsNothing);
    expect(find.text('Karakter'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
