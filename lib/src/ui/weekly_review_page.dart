import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/local_date.dart';
import '../domain/weekly_review.dart';
import '../l10n/strings.dart';
import 'companion_stage.dart';
import 'life_widgets.dart';
import 'wellness_widgets.dart';

class WeeklyReviewPage extends StatefulWidget {
  const WeeklyReviewPage({super.key, required this.controller});
  final TaskController controller;
  @override
  State<WeeklyReviewPage> createState() => _WeeklyReviewPageState();
}

class _WeeklyReviewPageState extends State<WeeklyReviewPage> {
  late LocalDate date = widget.controller.today;
  ReviewScope scope = ReviewScope.all;
  int variant = math.Random().nextInt(3);
  @override
  Widget build(BuildContext context) {
    final c = widget.controller, s = context.s;
    final review = WeeklyReview(c.data, date, c.now(), scope: scope);
    return LifePage(
      children: [
        PageHeading('RealLife RPG', s('weekly_review'), s('reviewIntro')),
        WellnessDateBar(
          date: date,
          today: c.today,
          onChanged: (v) => setState(() => date = v),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final value in ReviewScope.values)
              ChoiceChip(
                label: Text(s('review.${value.name}')),
                selected: scope == value,
                onSelected: (_) => setState(() => scope = value),
              ),
          ],
        ),
        LifeCard(
          child: Column(
            children: [
              Text(
                '${review.from.toIso()} → ${review.from.addDays(6).toIso()}',
              ),
              CompanionStage(
                character: c.data.life.companion,
                mood: review.mood,
                height: 240,
              ),
              Text(
                review.score == null
                    ? s('noReviewScore')
                    : '${review.score} / 10',
                key: const Key('weekly-score'),
                style: Theme.of(context).textTheme.displaySmall,
              ),
              Text(
                '${s('doneTask')}: ${review.done} · ${s('notDoneTask')}: ${review.missed} · ${s('pending')}: ${review.pending}',
              ),
              if (review.band != null) ...[
                const SizedBox(height: 12),
                Text(
                  s('review.${review.band}.$variant'),
                  textAlign: TextAlign.center,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(s('anotherMessage')),
                  onPressed: () => setState(
                    () =>
                        variant = (variant + 1 + math.Random().nextInt(2)) % 3,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(s('reviewFormula')),
            ],
          ),
        ),
      ],
    );
  }
}
