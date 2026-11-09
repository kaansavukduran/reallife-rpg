import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/study.dart';
import '../domain/routine.dart';
import 'routine_schedule.dart';
import '../l10n/strings.dart';
import 'companion_stage.dart';
import '../domain/fitness.dart';
import 'life_widgets.dart';
import 'wellness_widgets.dart';

class StudyPage extends StatefulWidget {
  const StudyPage({super.key, required this.controller});
  final TaskController controller;
  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  TaskController get c => widget.controller;
  void save(List<Course> courses) =>
      c.updateLife(c.data.life.copyWith(study: StudyData(courses: courses)));
  void replace(Course value) => save([
    for (final old in c.data.life.study.courses)
      if (old.id == value.id) value else old,
  ]);
  void markUnit(String courseId, String unitId, DateTime? at) => save([
    for (final course in c.data.life.study.courses)
      if (course.id == courseId)
        course.copyWith(
          units: [
            for (final unit in course.units)
              if (unit.id == unitId) unit.mark(at) else unit,
          ],
        )
      else
        course,
  ]);
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final courses = c.data.life.study.courses;
    return LifePage(
      children: [
        PageHeading(
          'RealLife RPG',
          s('courses'),
          s('coursesIntro'),
          action: FilledButton.icon(
            key: const Key('add-course'),
            onPressed: () async {
              final course = await createCourse(context, c);
              if (course != null) {
                c.updateLifeWithRoutine(
                  c.data.life.copyWith(
                    study: StudyData(
                      courses: [...c.data.life.study.courses, course.course],
                    ),
                  ),
                  RoutineBinding(
                    kind: RoutineKind.course,
                    entityId: course.course.id,
                  ),
                  title: '${s('studyTask')}: ${course.course.title}',
                  weekdays: course.schedule.activeDays,
                  time: course.schedule.time,
                  durationMinutes: course.schedule.durationMinutes,
                  note: s('courseProgressHelp'),
                );
              }
            },
            icon: const Icon(Icons.add),
            label: Text(s('addCourse')),
          ),
        ),
        if (courses.isEmpty)
          LifeCard(
            child: Column(
              children: [
                CompanionStage(
                  character: c.data.life.companion,
                  motion: Motion.read,
                  autoplay: true,
                  height: 180,
                ),
                Text(s('emptyCourses')),
              ],
            ),
          ),
        for (final course in courses) ...[
          LifeCard(
            padding: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  course.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  scheduleLabel(
                    context,
                    scheduleFor(
                      c,
                      RoutineBinding(
                        kind: RoutineKind.course,
                        entityId: course.id,
                      ),
                    ),
                  ),
                ),
                Text(
                  '${course.completed} / ${course.units.length} ${s('unitsCompleted')}',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: course.completed / course.units.length,
                  semanticsLabel: s('courseProgress'),
                  semanticsValue:
                      '${(course.completed / course.units.length * 100).round()}%',
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final binding = RoutineBinding(
                          kind: RoutineKind.course,
                          entityId: course.id,
                        );
                        final choice = await editRoutineSchedule(
                          context,
                          scheduleFor(c, binding),
                        );
                        if (choice != null) {
                          c.updateLifeWithRoutine(
                            c.data.life,
                            binding,
                            title: '${s('studyTask')}: ${course.title}',
                            weekdays: choice.activeDays,
                            time: choice.time,
                            durationMinutes: choice.durationMinutes,
                          );
                        }
                      },
                      icon: const Icon(Icons.schedule),
                      label: Text(s('editSchedule')),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final title = await _rename(
                          context,
                          s('courseName'),
                          course.title,
                        );
                        if (title != null) {
                          final updated = course.copyWith(title: title);
                          final task = c.routineTask(
                            RoutineBinding(
                              kind: RoutineKind.course,
                              entityId: course.id,
                            ),
                          );
                          c.updateLifeAndTasks(
                            c.data.life.copyWith(
                              study: StudyData(
                                courses: [
                                  for (final old in c.data.life.study.courses)
                                    if (old.id == course.id) updated else old,
                                ],
                              ),
                            ),
                            [
                              if (task != null)
                                task.copyWith(
                                  title: '${s('studyTask')}: $title',
                                ),
                            ],
                          );
                        }
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(s('edit')),
                    ),
                    TextButton.icon(
                      key: Key('add-unit-${course.id}'),
                      onPressed: course.units.length >= 200
                          ? null
                          : () {
                              replace(
                                course.copyWith(
                                  units: [
                                    ...course.units,
                                    StudyUnit(id: c.newLifeId()),
                                  ],
                                ),
                              );
                            },
                      icon: const Icon(Icons.add),
                      label: Text(s('addUnit')),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        if (!await confirmRemoval(
                          context,
                          '${course.title}\n${s('deleteCourseHelp')}',
                        )) {
                          return;
                        }
                        final previousSchedule = scheduleFor(
                          c,
                          RoutineBinding(
                            kind: RoutineKind.course,
                            entityId: course.id,
                          ),
                        );
                        c.updateLifeEndingRoutines(
                          c.data.life.copyWith(
                            study: StudyData(
                              courses: c.data.life.study.courses
                                  .where((e) => e.id != course.id)
                                  .toList(),
                            ),
                          ),
                          RoutineKind.course,
                          course.id,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(s('deleted')),
                            action: SnackBarAction(
                              label: s('undo'),
                              onPressed: () {
                                if (!c.data.life.study.courses.any(
                                  (e) => e.id == course.id,
                                )) {
                                  c.updateLifeWithRoutine(
                                    c.data.life.copyWith(
                                      study: StudyData(
                                        courses: [
                                          ...c.data.life.study.courses,
                                          course,
                                        ],
                                      ),
                                    ),
                                    RoutineBinding(
                                      kind: RoutineKind.course,
                                      entityId: course.id,
                                    ),
                                    title: '${s('studyTask')}: ${course.title}',
                                    weekdays: previousSchedule.activeDays,
                                    time: previousSchedule.time,
                                    durationMinutes:
                                        previousSchedule.durationMinutes,
                                    note: s('courseProgressHelp'),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: Text(s('delete')),
                    ),
                  ],
                ),
                ExpansionTile(
                  key: Key('course-units-${course.id}'),
                  tilePadding: EdgeInsets.zero,
                  title: Text(s('units')),
                  initiallyExpanded: true,
                  children: [
                    for (int i = 0; i < course.units.length; i++)
                      Column(
                        children: [
                          CheckboxListTile(
                            key: Key('unit-${course.units[i].id}'),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              course.units[i].title.isEmpty
                                  ? '${s('unit')} ${i + 1}'
                                  : '${i + 1}. ${course.units[i].title}',
                            ),
                            subtitle: Text(
                              s(
                                course.units[i].completed
                                    ? 'unitDone'
                                    : 'unitPending',
                              ),
                            ),
                            value: course.units[i].completed,
                            onChanged: (v) => markUnit(
                              course.id,
                              course.units[i].id,
                              v == true ? c.now() : null,
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () async {
                                  final title = await _rename(
                                    context,
                                    s('unitName'),
                                    course.units[i].title,
                                    optional: true,
                                  );
                                  if (title != null) {
                                    replace(
                                      course.copyWith(
                                        units: [
                                          for (final unit in course.units)
                                            if (unit.id == course.units[i].id)
                                              unit.rename(title)
                                            else
                                              unit,
                                        ],
                                      ),
                                    );
                                  }
                                },
                                child: Text(s('unitName')),
                              ),
                              if (course.units.length > 1)
                                TextButton(
                                  onPressed: () async {
                                    if (await confirmRemoval(
                                      context,
                                      '${s('unit')} ${i + 1}: ${course.units[i].title}',
                                    )) {
                                      replace(
                                        course.copyWith(
                                          units: course.units
                                              .where(
                                                (u) =>
                                                    u.id != course.units[i].id,
                                              )
                                              .toList(),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(s('delete')),
                                ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        const SizedBox(height: 16),
        Text(s('courseProgressHelp')),
      ],
    );
  }
}

Future<String?> _rename(
  BuildContext context,
  String label,
  String initial, {
  bool optional = false,
}) async {
  final text = TextEditingController(text: initial);
  final key = GlobalKey<FormState>();
  final result = await showEditor<String>(
    context: context,
    builder: (c) => EditorDialog(
      title: label,
      formKey: key,
      children: [textField(c, text, label, required: !optional)],
      onSave: () => Navigator.pop(c, text.text.trim()),
    ),
  );
  text.dispose();
  return result;
}

class CourseDraft {
  const CourseDraft(this.course, this.schedule);
  final Course course;
  final RoutineSchedule schedule;
}

Future<CourseDraft?> createCourse(
  BuildContext context,
  TaskController c,
) async {
  final name = TextEditingController(),
      countText = TextEditingController(text: '1');
  final names = List.generate(200, (_) => TextEditingController());
  final key = GlobalKey<FormState>();
  var schedule = const RoutineSchedule();
  final result = await showEditor<CourseDraft>(
    context: context,
    builder: (context) => ValueListenableBuilder<TextEditingValue>(
      valueListenable: countText,
      builder: (context, value, _) {
        final n = parseDecimal(value.text);
        final count =
            n != null &&
                n.isFinite &&
                n >= 1 &&
                n <= 200 &&
                n == n.roundToDouble()
            ? n.toInt()
            : 1;
        return EditorDialog(
          title: context.s('addCourse'),
          formKey: key,
          children: [
            textField(
              context,
              name,
              context.s('courseName'),
              key: const Key('course-name'),
            ),
            numberField(
              context,
              countText,
              context.s('unitCount'),
              min: 1,
              max: 200,
              integer: true,
              required: true,
              key: const Key('course-unit-count'),
            ),
            Slider(
              key: const Key('course-unit-slider'),
              min: 1,
              max: 200,
              divisions: 199,
              value: count.toDouble(),
              label: '$count',
              onChanged: (v) => countText.text = '${v.round()}',
            ),
            ExpansionTile(
              key: const Key('course-unit-names'),
              title: Text(context.s('optionalUnitNames')),
              children: [
                for (int i = 0; i < count; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: textField(
                      context,
                      names[i],
                      '${context.s('unit')} ${i + 1}',
                      required: false,
                      key: Key('course-unit-name-$i'),
                    ),
                  ),
              ],
            ),
            RoutineScheduleEditor(
              initial: schedule,
              onChanged: (v) => schedule = v,
            ),
            Text(context.s('courseProgressHelp')),
          ],
          onSave: () => Navigator.pop(
            context,
            CourseDraft(
              Course(
                id: c.newLifeId(),
                title: name.text.trim(),
                units: [
                  for (
                    int i = 0;
                    i < parseDecimal(countText.text)!.toInt();
                    i++
                  )
                    StudyUnit(id: c.newLifeId(), title: names[i].text.trim()),
                ],
              ),
              schedule,
            ),
          ),
        );
      },
    ),
  );
  for (final text in [name, countText, ...names]) {
    text.dispose();
  }
  return result;
}
