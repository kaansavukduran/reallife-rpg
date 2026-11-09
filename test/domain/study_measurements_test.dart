import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reallife_rpg/src/domain/body_measurements.dart';
import 'package:reallife_rpg/src/domain/codec.dart';
import 'package:reallife_rpg/src/domain/fitness.dart';
import 'package:reallife_rpg/src/domain/life.dart';
import 'package:reallife_rpg/src/domain/study.dart';
import 'package:reallife_rpg/src/domain/task_data.dart';

void main() {
  test('course creation has no completion and unit rename preserves actual completion', () {
    final at = DateTime.utc(2026, 11, 9);
    final course = Course(
      id: 'c',
      title: 'Biyoloji',
      units: [
        const StudyUnit(id: 'u1'),
        StudyUnit(id: 'u2', title: 'Hücre', completedAt: at),
      ],
    );
    expect(course.completed, 1);
    expect(course.copyWith(title: 'Biology').units[1].completedAt, at);
    expect(course.units[1].rename('Cell').completedAt, at);
    expect(course.units[1].mark(null).completed, isFalse);
    expect(const StudyUnit(id: 'new').completed, isFalse);
    expect(() => course.units.clear(), throwsUnsupportedError);
  });
  test('BMI formula, adult boundary ranges and missing data are explicit', () {
    expect(bodyMassIndex(70, 175), closeTo(22.857142, 1e-5));
    expect(bodyMassIndex(null, 175), isNull);
    expect(bodyMassIndex(70, null), isNull);
    expect(bodyMassIndex(70, 0), isNull);
    expect(bodyMassIndex(double.nan, 175), isNull);
    final expected = {
      18.49: AdultBmiRange.underweight,
      18.5: AdultBmiRange.normal,
      24.99: AdultBmiRange.normal,
      25.0: AdultBmiRange.overweight,
      30.0: AdultBmiRange.obesity1,
      35.0: AdultBmiRange.obesity2,
      40.0: AdultBmiRange.obesity3,
    };
    expected.forEach((b, r) => expect(adultBmiRange(b), r));
    expect(const BodyMeasurements().adultReference, isFalse);
    expect(
      () =>
          BodyMeasurements.fromJson({'height_cm': 0, 'adult_reference': true}),
      throwsFormatException,
    );
  });
  test('courses and body measures survive backups and unrelated fitness/life changes', () {
    final life = LifeData(
      study: StudyData(
        courses: [
          Course(
            id: 'c',
            title: 'Türkçe',
            units: [StudyUnit(id: 'u', completedAt: DateTime.utc(2026, 11, 9))],
          ),
        ],
      ),
      measurements: const BodyMeasurements(heightCm: 175, adultReference: true),
      fitness: FitnessData(bodyKg: 70),
    );
    final modified = life.copyWith(
      fitness: life.fitness.copyWith(bodyKg: 72),
      name: 'İpek',
    );
    final json = encodeTaskData(
      TaskData(life: modified),
      savedAt: DateTime.utc(2026),
    );
    final restored = decodeTaskData(json);
    expect(restored.life.measurements.heightCm, 175);
    expect(restored.life.measurements.adultReference, isTrue);
    expect(restored.life.fitness.bodyKg, 72);
    expect(restored.life.study.courses.single.completed, 1);
    expect(restored.completions, isEmpty);
  });
  test('format 4 migrates without invented lessons, height or adult classification', () {
    final raw = jsonDecode(
      encodeTaskData(
        TaskData(life: LifeData(fitness: FitnessData(bodyKg: 70))),
        savedAt: DateTime.utc(2026),
      ),
    ) as Map<String, dynamic>;
    raw['schema_version'] = 4;
    final life = raw['life'] as Map<String, dynamic>;
    life['version'] = 2;
    life.remove('study');
    life.remove('measurements');
    final loaded = decodeTaskData(jsonEncode(raw));
    expect(loaded.life.study.courses, isEmpty);
    expect(loaded.life.measurements.heightCm, isNull);
    expect(loaded.life.measurements.adultReference, isFalse);
    expect(loaded.life.fitness.bodyKg, 70);
  });
  test('invalid and duplicated course units reject import rather than losing records', () {
    final course = Course(
      id: 'c',
      title: 'x',
      units: [const StudyUnit(id: 'u')],
    ).toJson();
    course['units'] = [];
    expect(() => Course.fromJson(course), throwsFormatException);
    course['units'] = [
      const StudyUnit(id: 'u').toJson(),
      const StudyUnit(id: 'u').toJson(),
    ];
    expect(() => Course.fromJson(course), throwsFormatException);
  });
}
