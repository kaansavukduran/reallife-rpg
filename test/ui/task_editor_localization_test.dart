import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/settings.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/domain/local_date.dart';
import 'package:reallife_rpg/src/domain/repeat_rule.dart';
import 'package:reallife_rpg/src/domain/task.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';
import 'package:reallife_rpg/src/ui/app.dart';

Future<void> reveal(WidgetTester t, Finder f) async {
  await t.pumpAndSettle();
  for (var i = 0; i < 12 && f.evaluate().isEmpty; i++) {
    await t.drag(find.byType(ListView).last, const Offset(0, -180));
    await t.pumpAndSettle();
  }
  await t.ensureVisible(f);
  await t.pumpAndSettle();
}

Future<void> click(WidgetTester t, Finder f) async {
  await reveal(t, f);
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  for (final en in [false, true]) {
    for (final phone in [false, true]) {
      testWidgets(
        'editor create + errors preserve input (en=$en, phone=$phone)',
        (t) async {
          t.view.physicalSize = phone
              ? const Size(390, 844)
              : const Size(1440, 1100);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          final store = MemoryTaskStore()
            ..settings = AppSettings(
              languageCode: en ? 'en' : 'tr',
              textScale: phone ? 2 : 1,
              gameMode: false,
              displayMode: phone ? 'dark' : 'light',
            );
          final c = TaskController(
            store: store,
            clock: () => DateTime(2026, 11, 12, 14),
          );
          await c.load();
          await t.pumpWidget(
            RealLifeRPGApp(controller: c, initialPage: 'maceram'),
          );
          await t.pumpAndSettle();
          await click(t, find.text(en ? 'New task' : 'Yeni görev'));
          expect(find.text(en ? 'Task name' : 'Görev adı'), findsOneWidget);
          if (phone) {
            t.view.viewInsets = const FakeViewPadding(bottom: 250);
            await t.pumpAndSettle();
          }
          await click(t, find.byKey(const Key('editor-save')));
          expect(
            find.text(en ? 'Enter a task name.' : 'Görev adı yaz.'),
            findsOneWidget,
          );
          expect(
            t
                .widget<TextField>(
                  find.descendant(
                    of: find.byKey(const Key('editor-title')),
                    matching: find.byType(TextField),
                  ),
                )
                .focusNode!
                .hasFocus,
            isTrue,
          );
          expect(c.data.tasks, isEmpty);
          expect(store.saved, isNull);
          await t.enterText(
            find.byKey(const Key('editor-title')),
            'Kullanıcının özgün görevi',
          );
          await t.enterText(
            find.byKey(const Key('editor-note')),
            'Özel not — do not translate',
          );
          await t.enterText(
            find.byKey(const Key('editor-steps')),
            'İlk adım\nSecond step',
          );
          t.view.viewInsets = const FakeViewPadding();
          await t.pumpAndSettle();
          if (phone) {
            t.view.physicalSize = const Size(844, 390);
            await t.pumpAndSettle();
            expect(
              t
                  .widget<TextField>(
                    find.descendant(
                      of: find.byKey(const Key('editor-title')),
                      matching: find.byType(TextField),
                    ),
                  )
                  .controller!
                  .text,
              'Kullanıcının özgün görevi',
            );
            t.view.physicalSize = const Size(390, 844);
            await t.pumpAndSettle();
          }
          await click(t, find.text(en ? 'Selected days' : 'Belirli günler'));
          for (var d = 1; d <= 5; d++) {
            await click(t, find.byKey(Key('editor-weekday-$d')));
          }
          expect(
            t
                .widget<FilterChip>(find.byKey(const Key('editor-weekday-1')))
                .tooltip,
            en ? 'Monday' : 'Pazartesi',
          );
          await click(t, find.byKey(const Key('editor-save')));
          expect(
            find.text(en ? 'Choose at least one day.' : 'En az bir gün seç.'),
            findsOneWidget,
          );
          expect(
            t
                .widget<TextField>(find.byKey(const Key('editor-note')))
                .controller!
                .text,
            'Özel not — do not translate',
          );
          expect(c.data.tasks, isEmpty);
          await click(t, find.text(en ? 'Weekend' : 'Hafta sonu'));
          expect(find.byKey(const Key('editor-error')), findsNothing);
          await reveal(t, find.byKey(const Key('editor-start-date')));
          expect(
            find.textContaining(en ? 'November' : 'Kasım'),
            findsOneWidget,
          );
          await click(t, find.byKey(const Key('editor-save')));
          final task = c.data.tasks.single;
          expect(task.title, 'Kullanıcının özgün görevi');
          expect(task.note, 'Özel not — do not translate');
          expect(task.steps.map((s) => s.title), ['İlk adım', 'Second step']);
          expect(task.lastRule, WeeklyRule({6, 7}));
          expect(c.data.completions, isEmpty);
          expect(c.profile.totalXp, 0);
          await c.saved;
          await t.pumpWidget(const SizedBox());
          final reopened = TaskController(
            store: store,
            clock: () => DateTime(2026, 11, 12, 14),
          );
          await reopened.load();
          expect(reopened.data.tasks.single.toJson(), task.toJson());
          expect(t.takeException(), isNull);
          c.dispose();
          reopened.dispose();
        },
      );
    }

    for (final phone in [false, true]) {
      testWidgets(
        'editor date/time, cancel and editing preserve history (en=$en, phone=$phone)',
        (t) async {
          t.view.physicalSize = phone
              ? const Size(390, 844)
              : const Size(1440, 1200);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          final store = MemoryTaskStore()
            ..settings = AppSettings(
              languageCode: en ? 'en' : 'tr',
              textScale: phone ? 2 : 1,
              gameMode: false,
            );
          final c = TaskController(
            store: store,
            clock: () => DateTime(2026, 11, 12, 14),
          );
          await c.load();
          final task = c.addTask(
            title: 'Original title',
            note: 'Original note',
            rule: const DailyRule(),
            start: LocalDate(2026, 11, 1),
            baseXp: 7,
            time: ClockTime(9, 5),
            durationMinutes: 30,
            steps: ['Original step'],
          );
          c.toggle(task.id, c.today.addDays(-1));
          await c.saved;
          final timestamp = c.data.doneAt(task.id, c.today.addDays(-1));
          final beforeXp = c.profile.totalXp;
          await t.pumpWidget(
            RealLifeRPGApp(controller: c, initialPage: 'maceram'),
          );
          await t.pumpAndSettle();
          await click(t, find.byKey(ValueKey('adventure-edit-${task.id}')));
          expect(
            find.text(en ? 'Edit task' : 'Görevi düzenle'),
            findsOneWidget,
          );
          expect(
            find.textContaining(
              en ? 'Earlier days keep' : 'önceki günler eski kurala',
            ),
            findsOneWidget,
          );
          await t.enterText(
            find.byKey(const Key('editor-title')),
            'Discard this title',
          );
          await click(t, find.text(en ? 'Cancel' : 'İptal'));
          expect(c.data.taskById(task.id)!.title, 'Original title');
          await click(t, find.byKey(ValueKey('adventure-edit-${task.id}')));
          await click(t, find.byKey(const Key('editor-time')));
          final fields = find.descendant(
            of: phone
                ? find.byKey(const Key('task-time-dialog'))
                : find.byType(TimePickerDialog),
            matching: find.byType(TextField),
          );
          expect(fields, findsNWidgets(2));
          expect(find.text(en ? 'Hour' : 'Saat'), findsWidgets);
          expect(find.text(en ? 'Minute' : 'Dakika'), findsWidgets);
          final hour = fields.at(0);
          final minute = fields.at(1);
          if (phone) {
            t.view.viewInsets = const FakeViewPadding(bottom: 220);
            await t.pumpAndSettle();
            await t.enterText(hour, '24');
            await t.enterText(minute, '60');
            await click(t, find.text(en ? 'Select' : 'Seç').last);
            expect(
              find.text(
                en
                    ? 'Enter an hour from 00 to 23.'
                    : '00–23 arasında saat gir.',
              ),
              findsOneWidget,
            );
            expect(
              find.text(
                en
                    ? 'Enter a minute from 00 to 59.'
                    : '00–59 arasında dakika gir.',
              ),
              findsOneWidget,
            );
            expect(c.data.taskById(task.id)!.time!.format(), '09:05');
            t.view.viewInsets = const FakeViewPadding();
            await t.pumpAndSettle();
            await click(
              t,
              find.byTooltip(en ? 'Use clock face' : 'Kadrandan seç'),
            );
            expect(find.byType(TimePickerDialog), findsOneWidget);
            await click(t, find.text(en ? 'Cancel' : 'Vazgeç').last);
            expect(t.widget<TextField>(hour).controller!.text, '24');
          }
          await t.enterText(hour, '23');
          await t.enterText(minute, '45');
          await click(t, find.text(en ? 'Select' : 'Seç').last);
          await t.enterText(find.byKey(const Key('planned-duration')), '0');
          await click(t, find.byKey(const Key('editor-save')));
          expect(
            find.text(
              en
                  ? 'Enter 1–1440 minutes or leave empty.'
                  : '1–1440 dakika gir veya boş bırak.',
            ),
            findsOneWidget,
          );
          expect(c.data.taskById(task.id)!.time!.format(), '09:05');
          await t.enterText(find.byKey(const Key('planned-duration')), '45');
          await t.enterText(
            find.byKey(const Key('editor-title')),
            'Yeni başlık',
          );
          await click(t, find.text(en ? 'One-off' : 'Tek sefer'));
          await click(t, find.byKey(const Key('editor-once-date')));
          await click(t, find.text('15').last);
          await click(t, find.text(en ? 'Select' : 'Seç').last);
          await click(t, find.byKey(const Key('editor-save')));
          final edited = c.data.taskById(task.id)!;
          expect(edited.title, 'Yeni başlık');
          expect(edited.note, 'Original note');
          expect(edited.steps.single.title, 'Original step');
          expect(edited.time!.format(), '23:45');
          expect(edited.durationMinutes, 45);
          expect(edited.lastRule, OnceRule(LocalDate(2026, 11, 15)));
          expect(c.data.doneAt(task.id, c.today.addDays(-1)), timestamp);
          expect(c.data.rewardXp[task.id]![c.today.addDays(-1)], 7);
          expect(c.profile.totalXp, beforeXp);
          await c.saved;
          await t.pumpWidget(const SizedBox());
          final reopened = TaskController(
            store: store,
            clock: () => DateTime(2026, 11, 12, 14),
          );
          await reopened.load();
          expect(reopened.data.taskById(task.id)!.toJson(), edited.toJson());
          expect(reopened.data.doneAt(task.id, c.today.addDays(-1)), timestamp);
          expect(t.takeException(), isNull);
          c.dispose();
          reopened.dispose();
        },
      );
    }
  }
}
