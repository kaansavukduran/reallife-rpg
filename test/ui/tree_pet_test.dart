import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/settings.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/domain/codec.dart';
import 'package:reallife_rpg/src/domain/skill_tree.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';
import 'package:reallife_rpg/src/ui/app.dart';
import 'package:reallife_rpg/src/ui/companion_stage.dart';

void main() {
  testWidgets(
    'life node editor saves manual mark without XP; persisted branches appear in tree',
    (t) async {
      t.view.physicalSize = const Size(1500, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final store = MemoryTaskStore();
      final c = TaskController(
        store: store,
        clock: () => DateTime(2026, 11, 9),
      );
      await c.load();
      await t.pumpWidget(
        RealLifeRPGApp(controller: c, initialPage: 'skill_tree'),
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('add-skill')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('skill-name')), 'Gitar');
      await t.ensureVisible(find.byKey(const Key('editor-save')));
      await t.tap(find.byKey(const Key('editor-save')));
      await t.pumpAndSettle();
      final node = c.data.life.skillTree.nodes.single;
      expect(node.marked, false);
      expect(c.profile.totalXp, 0);
      await c.saved;
      expect(
        decodeTaskData(store.saved!).life.skillTree.nodes.single.title,
        'Gitar',
      );
      expect(find.byKey(Key('skill-node-${node.id}')), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'companion follows app-wide mouse and reacts by touch region without changing tasks or XP',
    (t) async {
      t.view.physicalSize = const Size(1600, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final c = TaskController(
        store: MemoryTaskStore(),
        clock: () => DateTime(2026, 11, 9),
      );
      await c.load();
      await t.pumpWidget(RealLifeRPGApp(controller: c, initialPage: 'maceram'));
      await t.pumpAndSettle();
      final stage = find.byKey(const Key('interactive-companion')).first;
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(10, 10));
      await mouse.moveTo(const Offset(1500, 500));
      await t.pump();
      CompanionPainter painter() => t
          .widgetList<CustomPaint>(
            find.descendant(of: stage, matching: find.byType(CustomPaint)),
          )
          .map((p) => p.painter)
          .whereType<CompanionPainter>()
          .single;
      expect(painter().look.dx, greaterThan(0));
      final box = t.getRect(stage);
      await t.tapAt(Offset(box.center.dx, box.top + box.height * .25));
      await t.pump();
      expect(
        find.text('Merhaba! Biraz merak, kocaman bir macera.'),
        findsOneWidget,
      );
      await t.pumpAndSettle();
      expect(c.profile.totalXp, 0);
      expect(c.data.completions, isEmpty);
      await c.updateSettings(
        c.settings.copyWith(
          appearance: c.settings.appearance.copyWith(reduceMotion: true),
        ),
      );
      await t.pumpAndSettle();
      await mouse.moveTo(const Offset(30, 200));
      await t.pump();
      expect(painter().look, Offset.zero);
      expect(painter().reaction, '');
      await mouse.removePointer();
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'in-app logo selection is independent and survives settings roundtrip',
    (t) async {
      final settings = const AppSettings().copyWith(logoId: 'owl');
      expect(AppSettings.decode(settings.encode()).logoId, 'owl');
      final store = MemoryTaskStore()..settings = settings;
      final c = TaskController(
        store: store,
        clock: () => DateTime(2026, 11, 9),
      );
      await c.load();
      await t.pumpWidget(RealLifeRPGApp(controller: c));
      await t.pumpAndSettle();
      expect(c.data.life.companion, 'aion');
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  for (final page in ['skill_tree', 'weekly_review']) {
    testWidgets(
      '$page remains usable on a phone at 200 percent with readable text',
      (t) async {
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final store = MemoryTaskStore()
          ..settings = const AppSettings(
            uiScale: 2,
            textScale: 1.25,
            languageCode: 'tr',
            appearance: Appearance(font: 'dyslexic', reduceMotion: true),
          );
        final c = TaskController(
          store: store,
          clock: () => DateTime(2026, 11, 9),
        );
        await c.load();
        c.updateLife(
          c.data.life.copyWith(
            skillTree: SkillTreeData(
              nodes: [
                const SkillNode(id: 'g', title: 'Gitar öğrenme yolum'),
                const SkillNode(
                  id: 'a',
                  title: 'Akor alıştırmaları',
                  parentId: 'g',
                ),
              ],
            ),
          ),
        );
        await t.pumpWidget(RealLifeRPGApp(controller: c, initialPage: page));
        await t.pumpAndSettle();
        expect(c.settings.uiScale, 2);
        expect(c.profile.totalXp, 0);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        c.dispose();
      },
    );
  }
}
