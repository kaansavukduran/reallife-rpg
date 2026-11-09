import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/daily_summary.dart';
import '../domain/local_date.dart';
import '../domain/nutrition.dart';
import '../l10n/strings.dart';
import 'life_widgets.dart';
import 'wellness_widgets.dart';

class DailySummaryPage extends StatefulWidget {
  const DailySummaryPage({super.key, required this.controller});
  final TaskController controller;
  @override
  State<DailySummaryPage> createState() => _DailySummaryPageState();
}

class _DailySummaryPageState extends State<DailySummaryPage> {
  late LocalDate day = widget.controller.today;
  bool weekly = false;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final from = weekly ? day.addDays(1 - day.weekday) : day;
    final to = weekly ? from.addDays(6) : day;
    final summary = PeriodSummary(
      widget.controller.data,
      from,
      to,
      now: widget.controller.now(),
    );
    final intake = summary.nutrient('energy');
    final difference = summary.recordedDifference;
    return LifePage(
      children: [
        PageHeading('RealLife RPG', s('daily_summary'), s('summaryIntro')),
        WellnessDateBar(
          date: day,
          today: widget.controller.today,
          onChanged: (v) => setState(() => day = v),
        ),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(s('daily')),
              selected: !weekly,
              onSelected: (_) => setState(() => weekly = false),
            ),
            ChoiceChip(
              label: Text(s('weekly')),
              selected: weekly,
              onSelected: (_) => setState(() => weekly = true),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('${from.toIso()} → ${to.toIso()}'),
        const SizedBox(height: 18),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _metric(
              s('recordedFoodEnergy'),
              summary.foods.isEmpty
                  ? '—'
                  : '${displayNumber(context, intake.known)} kcal',
              '${s('coverage')}: ${intake.covered}/${summary.foods.length}',
            ),
            _metric(
              s('recordedExerciseEnergy'),
              summary.workouts.isEmpty
                  ? '0 kcal'
                  : '${displayNumber(context, summary.knownExerciseKcal)} kcal',
              '${s('coverage')}: ${summary.energyCovered}/${summary.workouts.length}',
            ),
            _metric(
              s('recordArithmetic'),
              difference == null
                  ? s('incompleteData')
                  : '${difference > 0 ? '+' : ''}${displayNumber(context, difference)} kcal',
              s('foodMinusExercise'),
            ),
            _metric(
              s('trainingMinutes'),
              '${displayNumber(context, summary.minutes)} min',
              '${summary.workouts.length} ${s('movementRecords')}',
            ),
            _metric(
              s('foodRecords'),
              '${summary.foods.length} / ${summary.plannedFoods}',
              s('eatenVsPlanned'),
            ),
            _metric(
              s('studyOutcomes'),
              '${summary.studyDone} 👍 / ${summary.studyNotDone} 👎',
              '${s('pending')}: ${summary.studyPending} / ${summary.studyPlanned}',
            ),
          ],
        ),
        const SizedBox(height: 18),
        LifeCard(child: Text(s('summaryLimits'))),
        const SizedBox(height: 18),
        Text(s('matrix'), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        LifeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final key in nutrientKeys)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    '${s(key)}: ${summary.foods.isEmpty ? '—' : displayNumber(context, summary.nutrient(key).known)} ${nutrientUnit(key)} · ${summary.nutrient(key).covered}/${summary.foods.length}',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metric(String title, String value, String detail) => SizedBox(
    width: 255,
    child: LifeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(detail),
        ],
      ),
    ),
  );
}
