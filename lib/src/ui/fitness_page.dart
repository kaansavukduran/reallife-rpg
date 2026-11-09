import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/exercise_catalog.dart';
import '../domain/fitness.dart';
import '../domain/local_date.dart';
import '../domain/life.dart';
import '../domain/routine.dart';
import 'routine_schedule.dart';
import '../l10n/strings.dart';
import 'companion_stage.dart';
import 'life_widgets.dart';
import 'muscle_map.dart';
import 'wellness_widgets.dart';

List<Exercise> allExercises(TaskController c) => [
  ...exerciseCatalog,
  ...c.data.life.fitness.custom,
];
Exercise? findExercise(TaskController c, String id) {
  for (final e in allExercises(c)) {
    if (e.id == id) return e;
  }
  return null;
}

class FitnessPage extends StatefulWidget {
  const FitnessPage({super.key, required this.controller});
  final TaskController controller;
  @override
  State<FitnessPage> createState() => _FitnessPageState();
}

class _FitnessPageState extends State<FitnessPage> {
  String _view = 'programs';
  String? _plan;
  late LocalDate _date = widget.controller.today;
  TaskController get c => widget.controller;
  void save(FitnessData f) => c.updateLife(c.data.life.copyWith(fitness: f));
  LifeData withPlan(TrainingPlan p) => c.data.life.copyWith(
    fitness: c.data.life.fitness.copyWith(
      plans: [
        for (final old in c.data.life.fitness.plans)
          if (old.id == p.id) p else old,
        if (!c.data.life.fitness.plans.any((old) => old.id == p.id)) p,
      ],
    ),
  );
  void updatePlan(TrainingPlan p) {
    final life = withPlan(p);
    c.updateLifeAndTasks(life, [
      for (final day in p.days)
        if (c.routineTask(
              RoutineBinding(
                kind: RoutineKind.training,
                entityId: p.id,
                dayId: day.id,
              ),
            )
            case final task?)
          task.copyWith(
            title: '${context.s('trainingTask')}: ${p.title} · ${day.title}',
            note: day.items
                .map(
                  (item) =>
                      '${findExercise(c, item.exerciseId)?.name(context.s.english) ?? item.exerciseId} ${item.sets} × ${item.reps}${item.kg == null ? '' : ' · ${item.kg} kg'}',
                )
                .join('\n'),
          ),
    ]);
  }

  void saveDay(TrainingPlan p, TrainingDayDraft draft) {
    final day = draft.day;
    final exists = p.days.any((d) => d.id == day.id);
    final next = p.copyWith(
      days: [
        for (final old in p.days)
          if (old.id == day.id) day else old,
        if (!exists) day,
      ],
    );
    c.updateLifeWithRoutine(
      withPlan(next),
      RoutineBinding(kind: RoutineKind.training, entityId: p.id, dayId: day.id),
      title: '${context.s('trainingTask')}: ${p.title} · ${day.title}',
      weekdays: draft.schedule.activeDays,
      time: draft.schedule.time,
      durationMinutes: draft.schedule.durationMinutes,
    );
  }

  Future<void> _fromLibrary(Exercise exercise) async {
    final item = await editWorkoutItem(context, c, exercise);
    if (item == null || !mounted) return;
    final plans = c.data.life.fitness.plans;
    _ProgramDayChoice? target;
    if (plans.isEmpty) {
      target = const _ProgramDayChoice(null, null);
    } else {
      target = await showEditor<_ProgramDayChoice>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(context.s('chooseProgramDay')),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final plan in plans) ...[
                if (plan.days.isEmpty)
                  ListTile(
                    title: Text(plan.title),
                    subtitle: Text(context.s('newDay')),
                    onTap: () =>
                        Navigator.pop(dialog, _ProgramDayChoice(plan, null)),
                  ),
                for (final day in plan.days)
                  ListTile(
                    title: Text(plan.title),
                    subtitle: Text(day.title),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        Navigator.pop(dialog, _ProgramDayChoice(plan, day)),
                  ),
              ],
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(context.s('newProgram')),
                onPressed: () =>
                    Navigator.pop(dialog, const _ProgramDayChoice(null, null)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: Text(context.s('cancel')),
            ),
          ],
        ),
      );
    }
    if (target == null || !mounted) return;
    var plan = target.plan;
    if (plan == null) {
      final title = await editTitle(
        context,
        context.s('newProgram'),
        context.s('programName'),
      );
      if (title == null || !mounted) return;
      plan = TrainingPlan(id: c.newLifeId(), title: title);
    }
    if (target.day == null) {
      final draft = await editDay(context, c, planId: plan.id);
      if (draft == null || !mounted) return;
      saveDay(
        plan,
        TrainingDayDraft(draft.day.copyWith(items: [item]), draft.schedule),
      );
    } else {
      final day = target.day!;
      updatePlan(
        plan.copyWith(
          days: [
            for (final old in plan.days)
              if (old.id == day.id)
                old.copyWith(items: [...old.items, item])
              else
                old,
          ],
        ),
      );
    }
    if (mounted) {
      setState(() {
        _plan = plan!.id;
        _view = 'programs';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = c.data.life.fitness;
    final plans = f.plans;
    TrainingPlan? plan;
    for (final p in plans) {
      if (p.id == _plan) plan = p;
    }
    plan ??= plans.firstOrNull;
    return LifePage(
      children: [
        PageHeading(
          'RealLife RPG',
          s('fitness'),
          s('fitnessIntro'),
          action: OutlinedButton.icon(
            onPressed: () => _weight(context),
            icon: const Icon(Icons.monitor_weight_outlined),
            label: Text(
              '${s('bodyWeight')}: ${displayNumber(context, f.bodyKg)}',
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final key in ['programs', 'library', 'history'])
              ChoiceChip(
                key: Key('fitness-$key'),
                selected: _view == key,
                label: Text(s(key)),
                onSelected: (_) => setState(() => _view = key),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (_view == 'library')
          ExerciseLibrary(controller: c, onPick: _fromLibrary),
        if (_view == 'programs') ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const Key('new-program'),
                onPressed: () async {
                  final title = await editTitle(
                    context,
                    s('newProgram'),
                    s('programName'),
                  );
                  if (title == null || !mounted) return;
                  final p = TrainingPlan(id: c.newLifeId(), title: title);
                  save(
                    c.data.life.fitness.copyWith(
                      plans: [...c.data.life.fitness.plans, p],
                    ),
                  );
                  setState(() => _plan = p.id);
                },
                icon: const Icon(Icons.add),
                label: Text(s('newProgram')),
              ),
              OutlinedButton.icon(
                key: const Key('upper-lower-template'),
                onPressed: _template,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: Text(s('template')),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(s('templateHelp')),
          const SizedBox(height: 20),
          if (plan == null)
            LifeCard(child: Text(s('emptyProgram')))
          else ...[
            DropdownButtonFormField<String>(
              initialValue: plan.id,
              decoration: InputDecoration(labelText: s('programs')),
              isExpanded: true,
              items: [
                for (final p in plans)
                  DropdownMenuItem(
                    value: p.id,
                    child: Text(p.title, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _plan = v),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final current = plan!;
                    final title = await editTitle(
                      context,
                      s('edit'),
                      s('programName'),
                      current.title,
                    );
                    if (title != null) {
                      updatePlan(current.copyWith(title: title));
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(s('edit')),
                ),
                TextButton.icon(
                  onPressed: () {
                    final p = plan!;
                    final copy = TrainingPlan(
                      id: c.newLifeId(),
                      title: '${p.title} (${s('duplicate')})',
                      days: [
                        for (final d in p.days)
                          TrainingDay(
                            id: c.newLifeId(),
                            title: d.title,
                            weekdays: [],
                            items: [
                              for (final item in d.items)
                                WorkoutItem.fromJson({
                                  ...item.toJson(),
                                  'id': c.newLifeId(),
                                }),
                            ],
                          ),
                      ],
                    );
                    save(
                      c.data.life.fitness.copyWith(
                        plans: [...c.data.life.fitness.plans, copy],
                      ),
                    );
                    setState(() => _plan = copy.id);
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: Text(s('duplicate')),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final id = plan!.id;
                    if (await confirmRemoval(context, plan.title)) {
                      c.updateLifeEndingRoutines(
                        c.data.life.copyWith(
                          fitness: c.data.life.fitness.copyWith(
                            plans: c.data.life.fitness.plans
                                .where((p) => p.id != id)
                                .toList(),
                          ),
                        ),
                        RoutineKind.training,
                        id,
                      );
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: Text(s('delete')),
                ),
                FilledButton.tonalIcon(
                  key: const Key('new-training-day'),
                  onPressed: () async {
                    final p = plan!;
                    final d = await editDay(context, c, planId: p.id);
                    if (d != null) saveDay(p, d);
                  },
                  icon: const Icon(Icons.add),
                  label: Text(s('newDay')),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final day in plan.days) ...[
              _day(plan, day),
              const SizedBox(height: 16),
            ],
          ],
        ],
        if (_view == 'history') ...[
          WellnessDateBar(
            date: _date,
            today: c.today,
            onChanged: (d) => setState(() => _date = d),
          ),
          const SizedBox(height: 16),
          if (!f.logs.any((l) => l.date == _date))
            LifeCard(child: Text(s('emptyHistory'))),
          for (final log
              in f.logs.where((l) => l.date == _date).toList().reversed) ...[
            LifeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.exercise.name(s.english),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('${log.planTitle} · ${log.dayTitle}'),
                  Text(
                    '${displayNumber(context, log.minutes)} ${s('minutes')}',
                  ),
                  if (log.sets.isNotEmpty)
                    Text(
                      log.sets
                          .map(
                            (set) =>
                                '${set.reps} × ${displayNumber(context, set.kg)} kg',
                          )
                          .join('   /   '),
                    ),
                  if (log.speed != null)
                    Text('${s('speed')}: ${displayNumber(context, log.speed)}'),
                  if (log.incline != null)
                    Text(
                      '${s('incline')}: ${displayNumber(context, log.incline)}',
                    ),
                  Text(
                    '${s('estimated')}: ${log.kcal == null ? s('unknown') : '${displayNumber(context, log.kcal)} kcal'}',
                  ),
                  if (log.note.isNotEmpty) Text(log.note),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(s('energyMethod')),
                    children: [
                      Text(
                        s(
                          log.usesWalkingEquation
                              ? 'walkingMethod'
                              : 'metMethod',
                        ),
                      ),
                      Text(
                        '${s('met')}: ${displayNumber(context, log.effectiveMet)} · ${s('bodyWeight')}: ${displayNumber(context, log.bodyKg)}',
                      ),
                      Text(s('energyHelp')),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => _removeLog(log),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(s('delete')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  Widget _day(TrainingPlan p, TrainingDay d) {
    final s = context.s;
    return LifeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(d.title, style: Theme.of(context).textTheme.titleLarge),
          Text(
            scheduleLabel(
              context,
              scheduleFor(
                c,
                RoutineBinding(
                  kind: RoutineKind.training,
                  entityId: p.id,
                  dayId: d.id,
                ),
                fallback: d.weekdays,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final value = await editDay(context, c, planId: p.id, day: d);
                  if (value != null) saveDay(p, value);
                },
                icon: const Icon(Icons.edit_outlined),
                label: Text(s('edit')),
              ),
              TextButton.icon(
                onPressed: () async {
                  if (await confirmRemoval(context, d.title)) {
                    c.updateLifeEndingRoutines(
                      withPlan(
                        p.copyWith(
                          days: p.days.where((day) => day.id != d.id).toList(),
                        ),
                      ),
                      RoutineKind.training,
                      p.id,
                      dayId: d.id,
                    );
                  }
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(s('delete')),
              ),
              FilledButton.tonalIcon(
                key: Key('add-movement-${d.id}'),
                onPressed: () async {
                  final e = await pickExercise(context, c);
                  if (e == null || !mounted) return;
                  final item = await editWorkoutItem(context, c, e);
                  if (item != null) {
                    updatePlan(
                      p.copyWith(
                        days: [
                          for (final day in p.days)
                            if (day.id == d.id)
                              day.copyWith(items: [...day.items, item])
                            else
                              day,
                        ],
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(s('addMovement')),
              ),
            ],
          ),
          if (d.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(s('emptyDay')),
            ),
          for (int i = 0; i < d.items.length; i++) ...[
            const Divider(height: 25),
            _item(p, d, d.items[i], i),
          ],
        ],
      ),
    );
  }

  Widget _item(TrainingPlan p, TrainingDay d, WorkoutItem item, int index) {
    final s = context.s;
    final e = findExercise(c, item.exerciseId);
    if (e == null) return Text('${s('unknown')}: ${item.exerciseId}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${index + 1}. ${e.name(s.english)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          e.cardio == null
              ? '${item.sets} × ${item.reps} · ${displayNumber(context, item.kg)} kg · ${item.rest} s'
              : '${displayNumber(context, item.minutes)} min · ${s('speed')}: ${displayNumber(context, item.speed)} · ${s('incline')}: ${displayNumber(context, item.incline)}',
        ),
        if (item.note.isNotEmpty) Text(item.note),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            IconButton(
              tooltip: s('up'),
              onPressed: index == 0 ? null : () => _move(p, d, index, -1),
              icon: const Icon(Icons.arrow_upward),
            ),
            IconButton(
              tooltip: s('down'),
              onPressed: index == d.items.length - 1
                  ? null
                  : () => _move(p, d, index, 1),
              icon: const Icon(Icons.arrow_downward),
            ),
            IconButton(
              tooltip: s('edit'),
              onPressed: () async {
                final edited = await editWorkoutItem(context, c, e, item);
                if (edited != null) _replaceItem(p, d, item.id, edited);
              },
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: s('delete'),
              onPressed: () async {
                if (await confirmRemoval(context, e.name(s.english))) {
                  _replaceItem(p, d, item.id, null);
                }
              },
              icon: const Icon(Icons.delete_outline),
            ),
            OutlinedButton(
              onPressed: () => showExercise(context, c, e),
              child: Text(s('muscleMap')),
            ),
            FilledButton.tonalIcon(
              key: Key('record-${item.id}'),
              onPressed: () async {
                final log = await recordWorkout(
                  context,
                  c,
                  e,
                  item,
                  p.title,
                  d.title,
                );
                if (log == null || !mounted) return;
                save(
                  c.data.life.fitness.copyWith(
                    logs: [...c.data.life.fitness.logs, log],
                  ),
                );
                showSaved(context);
              },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(s('record')),
            ),
          ],
        ),
      ],
    );
  }

  void _replaceItem(
    TrainingPlan p,
    TrainingDay d,
    String id,
    WorkoutItem? value,
  ) => updatePlan(
    p.copyWith(
      days: [
        for (final old in p.days)
          if (old.id == d.id)
            old.copyWith(
              items: [
                for (final item in old.items)
                  if (item.id != id) item else ?value,
              ],
            )
          else
            old,
      ],
    ),
  );
  void _move(TrainingPlan p, TrainingDay d, int from, int delta) {
    final list = [...d.items];
    final item = list.removeAt(from);
    list.insert(from + delta, item);
    updatePlan(
      p.copyWith(
        days: [
          for (final old in p.days)
            if (old.id == d.id) old.copyWith(items: list) else old,
        ],
      ),
    );
  }

  void _removeLog(WorkoutLog log) {
    save(
      c.data.life.fitness.copyWith(
        logs: c.data.life.fitness.logs.where((l) => l.id != log.id).toList(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.s('deleted')),
        action: SnackBarAction(
          label: context.s('undo'),
          onPressed: () {
            if (!c.data.life.fitness.logs.any((e) => e.id == log.id)) {
              save(
                c.data.life.fitness.copyWith(
                  logs: [...c.data.life.fitness.logs, log],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _weight(BuildContext context) async {
    final text = TextEditingController(
      text: compactNumber(c.data.life.fitness.bodyKg).replaceAll('—', ''),
    );
    final key = GlobalKey<FormState>();
    final result = await showEditor<String>(
      context: context,
      builder: (context) => EditorDialog(
        title: context.s('bodyWeight'),
        formKey: key,
        children: [
          Text(context.s('bodyWeightHelp')),
          numberField(
            context,
            text,
            context.s('bodyWeight'),
            min: 20,
            max: 500,
          ),
        ],
        onSave: () => Navigator.pop(context, text.text),
      ),
    );
    if (result != null) {
      save(
        c.data.life.fitness.copyWith(
          bodyKg: parseDecimal(result),
          clearWeight: result.trim().isEmpty,
        ),
      );
    }
    text.dispose();
  }

  void _template() {
    final s = context.s;
    final p = TrainingPlan(
      id: c.newLifeId(),
      title: '${s('upper')} / ${s('lower')}',
      days: [
        TrainingDay(
          id: c.newLifeId(),
          title: s('upper'),
          weekdays: [],
          items: [
            for (final id in [
              'chest_press',
              'reverse_pec_deck',
              'shoulder_press',
              'lat_pulldown',
              'biceps_machine',
              'lateral_machine',
              'cable_row',
              'triceps_pushdown',
            ])
              WorkoutItem(id: c.newLifeId(), exerciseId: id, reps: 12),
          ],
        ),
        TrainingDay(
          id: c.newLifeId(),
          title: s('lower'),
          weekdays: [],
          items: [
            for (final id in [
              'leg_press',
              'seated_leg_curl',
              'leg_extension',
              'lying_leg_curl',
              'hip_abduction',
              'hip_adduction',
              'crunch_machine',
              'back_extension',
              'calf_dumbbell',
            ])
              WorkoutItem(id: c.newLifeId(), exerciseId: id, reps: 12),
          ],
        ),
      ],
    );
    save(
      c.data.life.fitness.copyWith(plans: [...c.data.life.fitness.plans, p]),
    );
    setState(() => _plan = p.id);
  }
}

class ExerciseLibrary extends StatefulWidget {
  const ExerciseLibrary({super.key, required this.controller, this.onPick});
  final TaskController controller;
  final ValueChanged<Exercise>? onPick;
  @override
  State<ExerciseLibrary> createState() => _ExerciseLibraryState();
}

class _ExerciseLibraryState extends State<ExerciseLibrary> {
  String query = '';
  Muscle? muscle;
  final equipment = <Equipment>{};
  ExerciseKind? kind;
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final candidates = allExercises(widget.controller)
        .where(
          (e) =>
              (kind == null || e.kind == kind) &&
              (muscle == null ||
                  e.primary.contains(muscle) ||
                  e.secondary.contains(muscle)) &&
              ('${e.tr} ${e.en} ${[...e.primary, ...e.secondary].map(s.muscle).join(' ')}'
                  .toLowerCase()
                  .contains(query.toLowerCase())),
        )
        .toList();
    final filtered = candidates
        .where((e) => equipment.isEmpty || equipment.contains(e.equipment))
        .toList();
    if (muscle != null) {
      filtered.sort((a, b) {
        final first = a.primary.contains(muscle) ? 0 : 1;
        final second = b.primary.contains(muscle) ? 0 : 1;
        return first.compareTo(second);
      });
    }
    final counts = {
      for (final eq in Equipment.values)
        eq: candidates.where((e) => e.equipment == eq).length,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MuscleMap(
          exercise: Exercise(
            id: 'selection',
            tr: '',
            en: '',
            equipment: Equipment.bodyweight,
            motion: Motion.idle,
            primary: muscle == null ? [] : [muscle!],
          ),
          onSelect: (value) => setState(() => muscle = value),
        ),
        Text(s('musclePickerHelp')),
        const SizedBox(height: 12),
        TextField(
          controller: search,
          key: const Key('exercise-search'),
          decoration: InputDecoration(
            labelText: s('searchExercise'),
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 250,
              child: DropdownButtonFormField<Muscle>(
                key: ValueKey('muscle-filter-${muscle?.name}'),
                initialValue: muscle,
                isExpanded: true,
                decoration: InputDecoration(labelText: s('allMuscles')),
                items: [
                  DropdownMenuItem(value: null, child: Text(s('allMuscles'))),
                  for (final m in Muscle.values)
                    DropdownMenuItem(value: m, child: Text(s.muscle(m))),
                ],
                onChanged: (v) => setState(() => muscle = v),
              ),
            ),
            OutlinedButton.icon(
              key: const Key('custom-exercise'),
              onPressed: () async {
                final e = await editExercise(context, widget.controller);
                if (e == null || !mounted) return;
                final c = widget.controller;
                c.updateLife(
                  c.data.life.copyWith(
                    fitness: c.data.life.fitness.copyWith(
                      custom: [...c.data.life.fitness.custom, e],
                    ),
                  ),
                );
                setState(() {});
              },
              icon: const Icon(Icons.add),
              label: Text(s('addExercise')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (muscle != null || query.trim().isNotEmpty) ...[
          Text(
            s('chooseEquipment'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilterChip(
                label: Text(s('allEquipment')),
                selected: equipment.isEmpty,
                onSelected: (_) => setState(equipment.clear),
              ),
              for (final eq in Equipment.values)
                FilterChip(
                  key: Key('equipment-${eq.name}'),
                  label: Text('${s('equipment.${eq.name}')} (${counts[eq]})'),
                  selected: equipment.contains(eq),
                  onSelected: counts[eq] == 0 && !equipment.contains(eq)
                      ? null
                      : (selected) => setState(
                          () => selected
                              ? equipment.add(eq)
                              : equipment.remove(eq),
                        ),
                ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilterChip(
                label: Text(s('allMovementKinds')),
                selected: kind == null,
                onSelected: (_) => setState(() => kind = null),
              ),
              for (final type in ExerciseKind.values)
                FilterChip(
                  key: Key('kind-${type.name}'),
                  label: Text(s('exerciseKind.${type.name}')),
                  selected: kind == type,
                  onSelected: (_) =>
                      setState(() => kind = kind == type ? null : type),
                ),
            ],
          ),
          TextButton.icon(
            onPressed: () => setState(() {
              muscle = null;
              equipment.clear();
              kind = null;
              query = '';
              search.clear();
            }),
            icon: const Icon(Icons.filter_alt_off),
            label: Text(s('clearFilters')),
          ),
          Text(
            '${filtered.length} / ${allExercises(widget.controller).length}',
          ),
        ] else
          Text(s('chooseMuscleFirst')),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(s('noResults')),
          ),
        for (final e
            in (muscle != null || query.trim().isNotEmpty
                ? filtered
                : <Exercise>[]))
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => widget.onPick != null
                        ? widget.onPick!(e)
                        : showExercise(context, widget.controller, e),
                    child: Text(
                      e.name(s.english),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${s('primary')}: ${e.primary.map(s.muscle).join(', ')}',
                  ),
                  Text(
                    '${s('equipment.${e.equipment.name}')} · ${s('exerciseKind.${e.kind.name}')}',
                  ),
                  if (e.secondary.isNotEmpty)
                    Text(
                      '${s('secondary')}: ${e.secondary.map(s.muscle).join(', ')}',
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () =>
                            showExercise(context, widget.controller, e),
                        child: Text(s('muscleMap')),
                      ),
                      if (widget.onPick != null)
                        FilledButton.tonal(
                          onPressed: () => widget.onPick!(e),
                          child: Text(s('select')),
                        ),
                      if (e.custom)
                        TextButton(
                          onPressed: () async {
                            final edited = await editExercise(
                              context,
                              widget.controller,
                              e,
                            );
                            if (edited == null || !mounted) return;
                            final c = widget.controller;
                            c.updateLife(
                              c.data.life.copyWith(
                                fitness: c.data.life.fitness.copyWith(
                                  custom: [
                                    for (final old
                                        in c.data.life.fitness.custom)
                                      if (old.id == e.id) edited else old,
                                  ],
                                ),
                              ),
                            );
                            setState(() {});
                          },
                          child: Text(s('edit')),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

Future<Exercise?> pickExercise(BuildContext context, TaskController c) =>
    showEditor<Exercise>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.s('addMovement')),
        content: SizedBox(
          width: 760,
          height: MediaQuery.sizeOf(context).height * .65,
          child: SingleChildScrollView(
            child: ExerciseLibrary(
              controller: c,
              onPick: (e) => Navigator.pop(context, e),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.s('cancel')),
          ),
        ],
      ),
    );
Future<void> showExercise(BuildContext context, TaskController c, Exercise e) =>
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(e.name(context.s.english)),
        scrollable: true,
        content: SizedBox(
          width: 800,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanionStage(
                character: c.data.life.companion,
                motion: e.motion,
                exerciseId: e.id,
                equipment: e.equipment,
                controls: true,
                autoplay: true,
              ),
              Text(context.s('schematic')),
              const SizedBox(height: 16),
              Text(
                (context.s.english ? e.cueEn : e.cueTr).isEmpty
                    ? context.s(
                        e.motion == Motion.reverseFly
                            ? 'cue.reverseFly'
                            : 'cue.default',
                      )
                    : context.s.english
                    ? e.cueEn
                    : e.cueTr,
              ),
              const SizedBox(height: 20),
              MuscleMap(exercise: e),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.s('close')),
          ),
        ],
      ),
    );

Future<String?> editTitle(
  BuildContext context,
  String title,
  String label, [
  String initial = '',
]) async {
  final text = TextEditingController(text: initial);
  final key = GlobalKey<FormState>();
  final result = await showEditor<String>(
    context: context,
    builder: (c) => EditorDialog(
      title: title,
      formKey: key,
      children: [textField(c, text, label)],
      onSave: () => Navigator.pop(c, text.text.trim()),
    ),
  );
  text.dispose();
  return result;
}

class _ProgramDayChoice {
  const _ProgramDayChoice(this.plan, this.day);
  final TrainingPlan? plan;
  final TrainingDay? day;
}

class TrainingDayDraft {
  const TrainingDayDraft(this.day, this.schedule);
  final TrainingDay day;
  final RoutineSchedule schedule;
}

Future<TrainingDayDraft?> editDay(
  BuildContext context,
  TaskController c, {
  required String planId,
  TrainingDay? day,
}) async {
  final text = TextEditingController(text: day?.title ?? '');
  var schedule = day == null
      ? RoutineSchedule(weekdays: [c.today.weekday])
      : scheduleFor(
          c,
          RoutineBinding(
            kind: RoutineKind.training,
            entityId: planId,
            dayId: day.id,
          ),
          fallback: day.weekdays,
        );
  final key = GlobalKey<FormState>();
  final result = await showEditor<TrainingDayDraft>(
    context: context,
    builder: (context) => EditorDialog(
      title: context.s('newDay'),
      formKey: key,
      children: [
        textField(context, text, context.s('dayName')),
        RoutineScheduleEditor(
          initial: schedule,
          onChanged: (v) => schedule = v,
        ),
      ],
      onSave: () => Navigator.pop(
        context,
        TrainingDayDraft(
          TrainingDay(
            id: day?.id ?? c.newLifeId(),
            title: text.text.trim(),
            weekdays: schedule.activeDays,
            items: day?.items ?? [],
          ),
          schedule,
        ),
      ),
    ),
  );
  text.dispose();
  return result;
}

Future<WorkoutItem?> editWorkoutItem(
  BuildContext context,
  TaskController c,
  Exercise e, [
  WorkoutItem? item,
]) async {
  final base = item ?? WorkoutItem(id: c.newLifeId(), exerciseId: e.id);
  final fields =
      [
            base.sets,
            base.reps,
            base.kg,
            base.rest,
            base.minutes,
            base.speed,
            base.incline,
            base.met,
          ]
          .map(
            (v) => TextEditingController(
              text: compactNumber(v).replaceAll('—', ''),
            ),
          )
          .toList();
  final note = TextEditingController(text: base.note);
  final key = GlobalKey<FormState>();
  final result = await showEditor<WorkoutItem>(
    context: context,
    builder: (context) => EditorDialog(
      title: e.name(context.s.english),
      formKey: key,
      children: [
        if (e.cardio == null) ...[
          countField(
            context,
            fields[0],
            context.s('sets'),
            id: 'sets',
            max: 30,
          ),
          countField(
            context,
            fields[1],
            context.s('reps'),
            id: 'reps',
            max: 500,
          ),
          numberField(
            context,
            fields[2],
            context.s('weight'),
            max: 2000,
            help: context.s('weightHelp'),
          ),
          numberField(
            context,
            fields[3],
            context.s('rest'),
            max: 3600,
            integer: true,
            required: true,
          ),
        ] else ...[
          numberField(
            context,
            fields[4],
            context.s('minutes'),
            min: .1,
            max: 1440,
            required: true,
          ),
          numberField(context, fields[5], context.s('speed'), max: 100),
          numberField(context, fields[6], context.s('incline'), max: 40),
          numberField(
            context,
            fields[7],
            context.s('met'),
            min: 1,
            max: 25,
            required: true,
          ),
          Text(context.s('metMethod')),
          Text(context.s('energyHelp')),
        ],
        textField(context, note, context.s('note'), required: false, lines: 3),
      ],
      onSave: () => Navigator.pop(
        context,
        WorkoutItem(
          id: base.id,
          exerciseId: e.id,
          sets: parseDecimal(fields[0].text)!.toInt(),
          reps: parseDecimal(fields[1].text)!.toInt(),
          kg: parseDecimal(fields[2].text),
          rest: parseDecimal(fields[3].text)!.toInt(),
          minutes: parseDecimal(fields[4].text)!,
          speed: parseDecimal(fields[5].text),
          incline: parseDecimal(fields[6].text),
          met: parseDecimal(fields[7].text)!,
          note: note.text.trim(),
        ),
      ),
    ),
  );
  for (final t in [...fields, note]) {
    t.dispose();
  }
  return result;
}

Future<Exercise?> editExercise(
  BuildContext context,
  TaskController c, [
  Exercise? original,
]) async {
  final tr = TextEditingController(text: original?.tr ?? ''),
      en = TextEditingController(text: original?.en ?? '');
  final cueTr = TextEditingController(text: original?.cueTr ?? ''),
      cueEn = TextEditingController(text: original?.cueEn ?? '');
  var equipment = original?.equipment ?? Equipment.machine,
      motion = original?.motion ?? Motion.reverseFly;
  var cardio = original?.cardio ?? Cardio.walking;
  final primary = {...?original?.primary},
      secondary = {...?original?.secondary};
  final key = GlobalKey<FormState>();
  String? error;
  final result = await showEditor<Exercise>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => EditorDialog(
        title: context.s(original == null ? 'addExercise' : 'editExercise'),
        formKey: key,
        children: [
          textField(context, tr, context.s('nameTr')),
          textField(context, en, context.s('nameEn')),
          DropdownButtonFormField<Equipment>(
            initialValue: equipment,
            isExpanded: true,
            decoration: InputDecoration(labelText: context.s('equipment')),
            items: [
              for (final eq in Equipment.values)
                DropdownMenuItem(
                  value: eq,
                  child: Text(context.s('equipment.${eq.name}')),
                ),
            ],
            onChanged: (v) => set(() => equipment = v!),
          ),
          DropdownButtonFormField<Motion>(
            initialValue: motion,
            isExpanded: true,
            decoration: InputDecoration(labelText: context.s('motion')),
            items: [
              for (final m in Motion.values.where(
                (m) => ![Motion.eat, Motion.read, Motion.idle].contains(m),
              ))
                DropdownMenuItem(
                  value: m,
                  child: Text(context.s('motion.${m.name}')),
                ),
            ],
            onChanged: (v) => set(() => motion = v!),
          ),
          if (equipment == Equipment.cardio)
            DropdownButtonFormField<Cardio>(
              initialValue: cardio,
              isExpanded: true,
              decoration: InputDecoration(labelText: context.s('fitness')),
              items: [
                for (final kind in Cardio.values)
                  DropdownMenuItem(
                    value: kind,
                    child: Text(
                      exerciseCatalog
                          .firstWhere((e) => e.cardio == kind)
                          .name(context.s.english),
                    ),
                  ),
              ],
              onChanged: (v) => set(() => cardio = v!),
            ),
          Text(context.s('primary')),
          Wrap(
            spacing: 5,
            children: [
              for (final m in Muscle.values)
                FilterChip(
                  label: Text(context.s.muscle(m)),
                  selected: primary.contains(m),
                  onSelected: (v) => set(() {
                    if (v) {
                      primary.add(m);
                      secondary.remove(m);
                    } else {
                      primary.remove(m);
                    }
                  }),
                ),
            ],
          ),
          Text(context.s('secondary')),
          Wrap(
            spacing: 5,
            children: [
              for (final m in Muscle.values)
                FilterChip(
                  label: Text(context.s.muscle(m)),
                  selected: secondary.contains(m),
                  onSelected: primary.contains(m)
                      ? null
                      : (v) => set(() {
                          if (v) {
                            secondary.add(m);
                          } else {
                            secondary.remove(m);
                          }
                        }),
                ),
            ],
          ),
          textField(
            context,
            cueTr,
            '${context.s('note')} · TR',
            required: false,
            lines: 3,
          ),
          textField(
            context,
            cueEn,
            '${context.s('note')} · EN',
            required: false,
            lines: 3,
          ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
        onSave: () {
          if (primary.isEmpty) {
            set(() => error = context.s('primary'));
            return;
          }
          Navigator.pop(
            context,
            Exercise(
              id: original?.id ?? 'custom-${c.newLifeId()}',
              tr: tr.text.trim(),
              en: en.text.trim(),
              equipment: equipment,
              motion: motion,
              primary: primary.toList(),
              secondary: secondary.toList(),
              cueTr: cueTr.text.trim(),
              cueEn: cueEn.text.trim(),
              custom: true,
              cardio: equipment == Equipment.cardio ? cardio : null,
            ),
          );
        },
      ),
    ),
  );
  for (final t in [tr, en, cueTr, cueEn]) {
    t.dispose();
  }
  return result;
}

Future<WorkoutLog?> recordWorkout(
  BuildContext context,
  TaskController c,
  Exercise e,
  WorkoutItem item,
  String plan,
  String day,
) async {
  final key = GlobalKey<FormState>();
  var date = c.today;
  final done = List.filled(item.sets, false);
  final reps = [for (int i = 0; i < item.sets; i++) TextEditingController()];
  final kg = [for (int i = 0; i < item.sets; i++) TextEditingController()];
  final minutes = TextEditingController(),
      speed = TextEditingController(),
      incline = TextEditingController(),
      met = TextEditingController(text: compactNumber(item.met)),
      note = TextEditingController();
  String? error;
  final result = await showEditor<WorkoutLog>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => EditorDialog(
        title: context.s('record'),
        formKey: key,
        children: [
          Text(
            e.name(context.s.english),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(context.s('recordHelp')),
          WellnessDateBar(
            date: date,
            today: c.today,
            onChanged: (v) => set(() => date = v),
          ),
          if (e.cardio == null)
            for (int i = 0; i < item.sets; i++)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        key: Key('performed-set-$i'),
                        contentPadding: EdgeInsets.zero,
                        title: Text('${i + 1}. ${context.s('actualSet')}'),
                        value: done[i],
                        onChanged: (v) => set(() => done[i] = v!),
                      ),
                      if (done[i]) ...[
                        numberField(
                          context,
                          reps[i],
                          context.s('reps'),
                          min: 1,
                          max: 500,
                          integer: true,
                          required: true,
                          key: Key('actual-reps-$i'),
                        ),
                        const SizedBox(height: 12),
                        numberField(
                          context,
                          kg[i],
                          context.s('weight'),
                          max: 2000,
                          help: context.s('weightHelp'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          numberField(
            context,
            minutes,
            context.s('actualMinutes'),
            min: .1,
            max: 1440,
            required: true,
            key: const Key('actual-minutes'),
          ),
          if (e.cardio != null) ...[
            numberField(context, speed, context.s('speed'), max: 100),
            numberField(context, incline, context.s('incline'), max: 40),
          ],
          numberField(
            context,
            met,
            context.s('met'),
            min: 1,
            max: 25,
            required: true,
          ),
          Text(context.s('metMethod')),
          Text(context.s('walkingMethod')),
          Text(context.s('energyHelp')),
          textField(
            context,
            note,
            context.s('note'),
            required: false,
            lines: 3,
          ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
        onSave: () {
          if (e.cardio == null && !done.any((e) => e)) {
            set(() => error = context.s('noSets'));
            return;
          }
          if (date.isAfter(c.today)) {
            set(() => error = context.s('date'));
            return;
          }
          Navigator.pop(
            context,
            WorkoutLog(
              id: c.newLifeId(),
              date: date,
              exercise: e,
              prescription: item,
              planTitle: plan,
              dayTitle: day,
              sets: [
                for (int i = 0; i < item.sets; i++)
                  if (e.cardio == null && done[i])
                    PerformedSet(
                      parseDecimal(reps[i].text)!.toInt(),
                      parseDecimal(kg[i].text),
                    ),
              ],
              minutes: parseDecimal(minutes.text)!,
              bodyKg: c.data.life.fitness.bodyKg,
              speed: parseDecimal(speed.text),
              incline: parseDecimal(incline.text),
              met: parseDecimal(met.text)!,
              note: note.text.trim(),
            ),
          );
        },
      ),
    ),
  );
  for (final text in [...reps, ...kg, minutes, speed, incline, met, note]) {
    text.dispose();
  }
  return result;
}
