import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/settings.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';
import 'package:reallife_rpg/src/ui/app.dart';
import 'package:reallife_rpg/src/ui/themes.dart';
import 'package:reallife_rpg/src/ui/wellness_widgets.dart';
import 'package:reallife_rpg/src/domain/local_date.dart';

Future<void> reach(WidgetTester t, Finder finder) async {
  await t.pumpAndSettle();
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await t.drag(find.byType(ListView).last, const Offset(0, -160));
    await t.pumpAndSettle();
  }
  await t.ensureVisible(finder);
  await t.pumpAndSettle();
}

Future<void> press(WidgetTester t, Finder f) async {
  await reach(t, f);
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'home never highlights Day as current; Open Day restores primary navigation',
    (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      t.view.padding = const FakeViewPadding(top: 24, bottom: 32);
      addTearDown(t.view.reset);
      final c = TaskController(store: MemoryTaskStore());
      await c.load();
      await t.pumpWidget(RealLifeRPGApp(controller: c, initialPage: 'maceram'));
      await t.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
      expect(
        t.getRect(find.byType(ListView).first).bottom,
        lessThanOrEqualTo(812.1),
      );
      expect(find.byIcon(Icons.menu), findsOneWidget);
      await press(t, find.text('Gün ekranını aç'));
      final nav = t.widget<NavigationBar>(find.byType(NavigationBar));
      expect(
        (nav.destinations[nav.selectedIndex] as NavigationDestination).label,
        'Gün',
      );
      expect(c.data.tasks, isEmpty);
      expect(c.data.completions, isEmpty);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'theme selection keeps reader accessibility preferences and persists',
    (t) async {
      t.view.physicalSize = const Size(1440, 1100);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final store = MemoryTaskStore()
        ..settings = const AppSettings(
          displayMode: 'light',
          appearance: Appearance(
            font: 'dyslexic',
            reduceMotion: true,
            lineHeight: 1.4,
            letterSpacing: 1,
            primary: 0xff005588,
          ),
        );
      final c = TaskController(store: store);
      await c.load();
      await t.pumpWidget(RealLifeRPGApp(controller: c, initialPage: 'ayarlar'));
      await t.pumpAndSettle();
      expect(
        Theme.of(t.element(find.byType(Scaffold).first)).brightness,
        Brightness.light,
      );
      await press(t, find.byKey(const Key('theme-orman')));
      expect(c.settings.themeId, 'orman');
      expect(c.settings.displayMode, 'preset');
      expect(c.settings.appearance.font, 'dyslexic');
      expect(c.settings.appearance.reduceMotion, isTrue);
      expect(c.settings.appearance.lineHeight, 1.4);
      expect(c.settings.appearance.letterSpacing, 1);
      expect(c.settings.appearance.primary, isNull);
      expect(c.data.tasks, isEmpty);
      expect(c.data.completions, isEmpty);
      final reopened = TaskController(store: store);
      await reopened.load();
      expect(reopened.settings.encode(), c.settings.encode());
      await t.pumpWidget(const SizedBox());
      c.dispose();
      reopened.dispose();
    },
  );
  test('new dark defaults preserve legacy themes and explicit reading choices', () {
    expect(const AppSettings().displayMode, 'dark');
    expect(AppSettings.decode('{}').displayMode, 'dark');
    final legacy = AppSettings.decode(
      '{"theme":"orman","appearance":{"font":"dyslexic","reduce_motion":true}}',
    );
    expect(legacy.displayMode, 'preset');
    expect(legacy.themeId, 'orman');
    expect(legacy.appearance.font, 'dyslexic');
    expect(legacy.appearance.reduceMotion, isTrue);
    for (final mode in ['light', 'system', 'dark', 'preset', 'contrast']) {
      final loaded = AppSettings.decode(
        legacy.copyWith(displayMode: mode).encode(),
      );
      expect(loaded.displayMode, mode);
      expect(loaded.appearance.font, 'dyslexic');
    }
  });
  for (final platform in TargetPlatform.values) {
    test(
      'system typography follows platform and explicit font wins ($platform)',
      () {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        final theme = buildTheme(appThemes.first);
        expect(
          theme.textTheme.bodyMedium!.fontFamily,
          ThemeData().textTheme.bodyMedium!.fontFamily,
        );
        for (final spec in appThemes) {
          final system = buildTheme(spec);
          expect(
            system.textTheme.titleLarge!.fontFamily,
            ThemeData().textTheme.titleLarge!.fontFamily,
          );
          expect(
            system.textTheme.titleLarge!.height,
            ThemeData().textTheme.titleLarge!.height,
          );
          final dyslexic = buildTheme(
            spec,
            appearance: const Appearance(font: 'dyslexic'),
          );
          expect(dyslexic.textTheme.titleLarge!.fontFamily, 'OpenDyslexic');
        }
      },
    );
  }
  for (final en in [false, true]) {
    testWidgets(
      'zoomed health/nutrition date input preserves historical range (en=$en)',
      (t) async {
        t.view.physicalSize = const Size(390, 844);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final store = MemoryTaskStore()
          ..settings = AppSettings(uiScale: 2, languageCode: en ? 'en' : 'tr');
        final c = TaskController(store: store);
        await c.load();
        await t.pumpWidget(
          RealLifeRPGApp(controller: c, initialPage: 'nutrition'),
        );
        await t.pumpAndSettle();
        await press(t, find.byKey(const Key('wellness-date')));
        final input = find.descendant(
          of: find.byKey(const Key('task-date-dialog')),
          matching: find.byType(TextField),
        );
        final loc = MaterialLocalizations.of(t.element(input));
        await t.enterText(input, loc.formatCompactDate(DateTime(1999, 12, 31)));
        await press(t, find.text(en ? 'Select' : 'Seç').last);
        expect(
          t.widget<WellnessDateBar>(find.byType(WellnessDateBar)).date,
          LocalDate(1999, 12, 31),
        );
        expect(c.data.tasks, isEmpty);
        expect(c.data.completions, isEmpty);
        expect(store.saved, isNull);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        c.dispose();
      },
    );

    for (final phone in [true, false]) {
      testWidgets(
        '200% UI reflows task form, rotation, time, settings and reload (en=$en,phone=$phone)',
        (t) async {
          final handler = FlutterError.onError;
          FlutterError.onError = (d) {
            debugPrint(d.toString());
            handler?.call(d);
          };
          addTearDown(() => FlutterError.onError = handler);
          t.view.physicalSize = phone
              ? const Size(390, 844)
              : const Size(1440, 1100);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          final store = MemoryTaskStore()
            ..settings = AppSettings(
              uiScale: 2,
              languageCode: en ? 'en' : 'tr',
              appearance: const Appearance(reduceMotion: true),
            );
          final c = TaskController(store: store);
          await c.load();
          await t.pumpWidget(
            RealLifeRPGApp(controller: c, initialPage: 'maceram'),
          );
          await t.pumpAndSettle();
          expect(
            Theme.of(t.element(find.byType(Scaffold).first)).brightness,
            Brightness.dark,
          );
          expect(
            find.byKey(const Key('interface-horizontal-scroll')),
            findsNothing,
          );
          expect(c.settings.uiScale, 2);
          expect(c.data.tasks, isEmpty);
          await press(t, find.text(en ? 'New task' : 'Yeni görev'));
          await press(t, find.byKey(const Key('editor-save')));
          expect(
            find.text(en ? 'Enter a task name.' : 'Görev adı yaz.'),
            findsOneWidget,
          );
          await t.enterText(
            find.byKey(const Key('editor-title')),
            'Özgün görev / Read one page',
          );
          await t.enterText(
            find.byKey(const Key('editor-note')),
            'Not korunur',
          );
          if (!phone) {
            await press(t, find.byKey(const Key('editor-time')));
            final desktopHours = find.descendant(
              of: find.byKey(const Key('task-time-dialog')),
              matching: find.byType(TextFormField),
            );
            await t.enterText(desktopHours.at(0), '22');
            await t.enterText(desktopHours.at(1), '15');
            await press(t, find.text(en ? 'Select' : 'Seç').last);
          }
          t.view.viewInsets = const FakeViewPadding(bottom: 240);
          await t.pumpAndSettle();
          await reach(t, find.byKey(const Key('editor-title')));
          expect(t.takeException(), isNull);
          t.view.viewInsets = const FakeViewPadding();
          t.view.physicalSize = const Size(844, 390);
          await t.pumpAndSettle();
          t.view.physicalSize = const Size(390, 844);
          await t.pumpAndSettle();
          await press(t, find.byKey(const Key('editor-start-date')));
          final dateField = find.descendant(
            of: find.byKey(const Key('task-date-dialog')),
            matching: find.byType(TextField),
          );
          final originalDate = t.widget<TextField>(dateField).controller!.text;
          await t.enterText(dateField, 'invalid');
          await press(t, find.text(en ? 'Select' : 'Seç').last);
          expect(find.byKey(const Key('task-date-dialog')), findsOneWidget);
          await t.enterText(dateField, originalDate);
          await press(t, find.text(en ? 'Select' : 'Seç').last);
          expect(find.byKey(const Key('task-date-dialog')), findsNothing);
          await press(t, find.byKey(const Key('editor-time')));
          final fields = find.descendant(
            of: find.byKey(const Key('task-time-dialog')),
            matching: find.byType(TextFormField),
          );
          await t.enterText(fields.at(0), '23');
          await t.enterText(fields.at(1), '45');
          await press(t, find.text(en ? 'Select' : 'Seç').last);
          await press(t, find.byKey(const Key('editor-save')));
          expect(c.data.tasks.single.title, 'Özgün görev / Read one page');
          expect(c.data.tasks.single.note, 'Not korunur');
          expect(c.data.tasks.single.time!.format(), '23:45');
          expect(c.data.completions, isEmpty);
          expect(t.takeException(), isNull);
          await press(t, find.byIcon(Icons.menu).first);
          final settings = find.byKey(const Key('nav-ayarlar'));
          await t.ensureVisible(settings);
          await t.pumpAndSettle();
          await t.tap(settings);
          await t.pumpAndSettle();
          await reach(t, find.byKey(const Key('interface-scale-percent')));
          expect(c.settings.uiScale, 2);
          expect(t.takeException(), isNull);
          await reach(t, find.byKey(const Key('scale-reset')));
          await t.tap(find.byKey(const Key('scale-reset')));
          await t.pumpAndSettle();
          expect(c.settings.uiScale, 1);
          expect(t.takeException(), isNull);
          final reopen = TaskController(store: store);
          await reopen.load();
          expect(reopen.data.tasks.single.title, c.data.tasks.single.title);
          expect(reopen.data.completions, isEmpty);
          expect(reopen.settings.displayMode, 'dark');
          await t.pumpWidget(const SizedBox());
          c.dispose();
          reopen.dispose();
        },
      );
    }
  }
}
