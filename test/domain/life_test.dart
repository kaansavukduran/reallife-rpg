import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/app/focus_clock.dart';
import 'package:reallife_rpg/src/app/task_controller.dart';
import 'package:reallife_rpg/src/domain/assessment.dart';
import 'package:reallife_rpg/src/domain/codec.dart';
import 'package:reallife_rpg/src/domain/life.dart';
import 'package:reallife_rpg/src/domain/local_date.dart';
import 'package:reallife_rpg/src/domain/repeat_rule.dart';
import 'package:reallife_rpg/src/domain/task_data.dart';
import 'package:reallife_rpg/src/storage/memory_task_store.dart';

void main() {
  final now = DateTime(2026, 11, 9, 12);
  LifeData sample() => LifeData(
    name: 'Deneme kahramanı',
    profession: 'developer',
    companion: 'lavender',
    bio: 'Merak et.',
    projects: [
      const LifeProject(
        id: 'p',
        title: 'Bir uygulama geliştir',
        area: LifeArea.craft,
      ),
    ],
    links: {
      't': const TaskLink(
        area: LifeArea.craft,
        projectId: 'p',
        skillId: 'software',
      ),
    },
    health: {
      '2026-11-09': const HealthEntry(
        water: 3,
        sleep: 7.5,
        movement: 20,
        mood: 4,
        note: 'İyi geldi.',
      ),
    },
    sessions: [FocusSession(id: 'f', at: now, minutes: 25, taskId: 't')],
    milestones: [
      Milestone(
        id: 'm',
        title: 'İlk ürün',
        kind: 'İlkler',
        date: LocalDate.of(now),
      ),
    ],
    assessments: [
      AssessmentRecord(
        id: 'a',
        skill: 'software',
        at: now,
        score: 3,
        total: 5,
        method: 'Bilgi testi',
        feedback: 'Sınır durumlarına bak.',
        evidence: 'yanıt',
        rubric: 'bilgi-v1',
      ),
    ],
  );

  test('all personal records roundtrip in the task backup', () {
    final before = TaskData(life: sample());
    final after = decodeTaskData(encodeTaskData(before, savedAt: now));
    expect(after.life.toJson(), before.life.toJson());
    expect(after.life.health['2026-11-09']!.sleep, 7.5);
  });
  test('legacy v1 and v2 backups import without invented progress', () {
    for (final version in [1, 2]) {
      final data = decodeTaskData(
        jsonEncode({
          'app': 'gunluk_gorevler',
          'schema_version': version,
          'tasks': <Object?>[],
          'completions': <Object?>[],
        }),
      );
      expect(data.life.name, isEmpty);
      expect(data.life.sessions, isEmpty);
      expect(data.life.assessments, isEmpty);
    }
  });
  test('new backups with missing or unsupported life data are refused', () {
    final raw = jsonDecode(
      encodeTaskData(TaskData(life: sample()), savedAt: now),
    ) as Map<String, Object?>;
    raw.remove('life');
    expect(() => decodeTaskData(jsonEncode(raw)), throwsFormatException);
    raw['life'] = {'version': 99};
    expect(() => decodeTaskData(jsonEncode(raw)), throwsFormatException);
  });
  test('malformed health dates and impossible values are refused', () {
    for (final value in [-1, 41, '3']) {
      final raw = sample().toJson();
      raw['health'] = {
        '2026-11-09': {
          'water': value,
          'sleep': 7,
          'movement': 20,
          'mood': 3,
          'note': '',
        },
      };
      expect(() => LifeData.fromJson(raw), throwsFormatException);
    }
    final raw = sample().toJson();
    raw['health'] = {'2026-02-31': const HealthEntry().toJson()};
    expect(() => LifeData.fromJson(raw), throwsFormatException);
    expect(
      () => HealthEntry.fromJson({
        'water': 0,
        'sleep': 25,
        'movement': null,
        'mood': null,
        'note': '',
      }),
      throwsFormatException,
    );
  });
  test('collections cannot mutate snapshots behind the controller', () {
    final life = sample();
    expect(() => life.projects.clear(), throwsUnsupportedError);
    expect(() => life.health.clear(), throwsUnsupportedError);
  });
  test(
    'task edits, ticks, deletion and reload preserve personal data',
    () async {
      final store = MemoryTaskStore();
      final c = TaskController(store: store, clock: () => now);
      await c.load();
      c.updateLife(sample());
      final task = c.addTask(
        title: 'Öğren',
        rule: const DailyRule(),
        start: c.today,
      );
      c.toggle(task.id, c.today);
      expect(c.data.life.name, 'Deneme kahramanı');
      final next = c.data.withoutTask(task.id);
      expect(next.life.health.length, 1);
      expect(next.life.assessments.length, 1);
      await c.saved;
      final second = TaskController(store: store, clock: () => now);
      await second.load();
      expect(second.data.life.toJson(), c.data.life.toJson());
      c.dispose();
      second.dispose();
    },
  );
  test('knowledge tests reject incomplete or forged answers', () {
    final skill = skillCatalog.first;
    expect(skill.grade(skill.questions.map((q) => q.answer).toList()), 5);
    expect(
      () => skill.grade([null, null, null, null, null]),
      throwsFormatException,
    );
    expect(() => skill.grade([9, 0, 0, 0, 0]), throwsFormatException);
  });
  test(
    'focus uses deadline, supports pause and never records automatically',
    () {
      var time = now;
      final clock = FocusClock(now: () => time, tick: false);
      clock.configure(5);
      clock.start();
      time = time.add(const Duration(minutes: 2));
      expect(clock.remaining, 180);
      clock.pause();
      time = time.add(const Duration(minutes: 10));
      expect(clock.remaining, 180);
      clock.start();
      time = time.add(const Duration(minutes: 4));
      clock.refresh();
      expect(clock.completed, isTrue);
      expect(clock.remaining, 0);
      expect(clock.recorded, isFalse);
      clock.markRecorded();
      expect(clock.recorded, isTrue);
      clock.markRecorded();
      clock.reset();
      expect(clock.remaining, 300);
      expect(clock.recorded, isFalse);
      clock.dispose();
    },
  );
  test('focus cannot be recorded before completion', () {
    final clock = FocusClock(tick: false);
    clock.markRecorded();
    expect(clock.recorded, isFalse);
    clock.dispose();
  });
}
