import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/repeat_rule.dart';
import '../domain/routine.dart';
import '../domain/task.dart';
import '../l10n/strings.dart';
import 'task_editor.dart';
import 'duration_input.dart';
import 'wellness_widgets.dart';

class RoutineSchedule {
  const RoutineSchedule({
    this.enabled = true,
    this.weekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.time,
    this.durationMinutes,
  });
  final bool enabled;
  final List<int> weekdays;
  final ClockTime? time;
  final int? durationMinutes;
  List<int> get activeDays => enabled ? weekdays : const [];
}

RoutineSchedule scheduleFor(
  TaskController c,
  RoutineBinding binding, {
  List<int> fallback = const [],
}) {
  final task = c.routineTask(binding);
  if (task == null) {
    return RoutineSchedule(enabled: fallback.isNotEmpty, weekdays: fallback);
  }
  final rule = task.ruleOn(c.today);
  return RoutineSchedule(
    enabled: rule != null,
    weekdays: rule is WeeklyRule
        ? rule.sortedDays
        : rule is DailyRule
        ? const [1, 2, 3, 4, 5, 6, 7]
        : rule is OnceRule
        ? [rule.date.weekday]
        : fallback,
    time: task.time,
    durationMinutes: task.durationMinutes,
  );
}

String scheduleLabel(BuildContext context, RoutineSchedule plan) =>
    !plan.enabled
    ? context.s('unscheduled')
    : '${plan.weekdays.map(context.s.weekday).join(' · ')} · ${plan.time?.format() ?? context.s('anyTime')}';

class RoutineScheduleEditor extends StatelessWidget {
  const RoutineScheduleEditor({
    super.key,
    required this.initial,
    required this.onChanged,
  });
  final RoutineSchedule initial;
  final ValueChanged<RoutineSchedule> onChanged;
  @override
  Widget build(BuildContext context) => FormField<RoutineSchedule>(
    initialValue: initial,
    validator: (value) => value!.enabled && value.weekdays.isEmpty
        ? context.s('chooseDay')
        : null,
    builder: (field) {
      final value = field.value!;
      void change(RoutineSchedule next) {
        field.didChange(next);
        onChanged(next);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            key: const Key('routine-enabled'),
            contentPadding: EdgeInsets.zero,
            title: Text(context.s('showInDay')),
            subtitle: Text(context.s('routineHelp')),
            value: value.enabled,
            onChanged: (v) => change(
              RoutineSchedule(
                enabled: v,
                weekdays: value.weekdays,
                time: value.time,
                durationMinutes: value.durationMinutes,
              ),
            ),
          ),
          if (value.enabled) ...[
            Text(context.s('weekdays')),
            Wrap(
              spacing: 6,
              children: [
                for (int day = 1; day <= 7; day++)
                  FilterChip(
                    key: Key('routine-day-$day'),
                    label: Text(context.s.weekday(day)),
                    selected: value.weekdays.contains(day),
                    onSelected: (v) {
                      final days = {...value.weekdays};
                      v ? days.add(day) : days.remove(day);
                      change(
                        RoutineSchedule(
                          weekdays: days.toList()..sort(),
                          time: value.time,
                          durationMinutes: value.durationMinutes,
                        ),
                      );
                    },
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  key: const Key('routine-time'),
                  onPressed: () async {
                    final time = await pickTaskTime(
                      context,
                      initial: value.time,
                    );
                    if (time != null) {
                      change(
                        RoutineSchedule(
                          weekdays: value.weekdays,
                          time: time,
                          durationMinutes: value.durationMinutes,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.schedule),
                  label: Text(value.time?.format() ?? context.s('addTime')),
                ),
                if (value.time != null)
                  IconButton(
                    tooltip: context.s('removeTime'),
                    onPressed: () =>
                        change(RoutineSchedule(weekdays: value.weekdays)),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            if (value.time != null)
              DurationInput(
                initial: value.durationMinutes,
                onChanged: (v) => change(
                  RoutineSchedule(
                    weekdays: value.weekdays,
                    time: value.time,
                    durationMinutes: v,
                  ),
                ),
              ),
          ],
          if (field.errorText != null)
            Text(
              field.errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      );
    },
  );
}

Future<RoutineSchedule?> editRoutineSchedule(
  BuildContext context,
  RoutineSchedule initial,
) async {
  var value = initial;
  final key = GlobalKey<FormState>();
  return showEditor<RoutineSchedule>(
    context: context,
    builder: (context) => EditorDialog(
      title: context.s('editSchedule'),
      formKey: key,
      children: [
        RoutineScheduleEditor(initial: initial, onChanged: (v) => value = v),
      ],
      onSave: () => Navigator.pop(context, value),
    ),
  );
}
