import 'food_catalog.dart';

import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/local_date.dart';
import '../domain/meal_template.dart';
import '../domain/nutrition.dart';
import '../l10n/strings.dart';
import 'wellness_widgets.dart';

class MealTemplates extends StatelessWidget {
  const MealTemplates({
    super.key,
    required this.controller,
    required this.date,
    required this.entries,
  });
  final TaskController controller;
  final LocalDate date;
  final List<MealEntry> entries;
  void save(List<MealTemplate> values) => controller.updateLife(
    controller.data.life.copyWith(
      nutrition: controller.data.life.nutrition.copyWith(templates: values),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final c = controller;
    return ExpansionTile(
      key: const Key('meal-templates'),
      title: Text(context.s('mealTemplates')),
      children: [
        Text(context.s('mealTemplateHelp')),
        for (final meal in Meal.values)
          if (entries.any((e) => e.meal == meal))
            TextButton.icon(
              key: Key('repeat-meal-${meal.name}'),
              icon: const Icon(Icons.repeat),
              label: Text(
                '${context.s('repeatMeal')}: ${context.s(meal.name)}',
              ),
              onPressed: () async {
                final value = await editMealTemplate(
                  context,
                  c,
                  meal: meal,
                  source: entries.where((e) => e.meal == meal).toList(),
                  date: date,
                );
                if (value != null) {
                  save([...c.data.life.nutrition.templates, value]);
                }
              },
            ),
        for (final template in c.data.life.nutrition.templates.where(
          (t) => t.until == null || !t.until!.isBefore(c.today),
        ))
          ListTile(
            title: Text(template.title),
            subtitle: Text(
              '${template.weekdays.map(context.s.weekday).join(' · ')} · ${template.start.toIso()} · ${template.foods.length} ${context.s('foods')}',
            ),
            trailing: Wrap(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: context.s('edit'),
                  onPressed: () async {
                    final replacement = await editMealTemplate(
                      context,
                      c,
                      meal: template.meal,
                      source: template.plannedOn(template.start).isEmpty
                          ? [
                              for (final f in template.foods)
                                MealEntry(
                                  id: f.id,
                                  date: c.today,
                                  food: f.food,
                                  grams: f.grams,
                                  meal: template.meal,
                                ),
                            ]
                          : template.plannedOn(template.start),
                      date: c.today,
                      old: template,
                    );
                    if (replacement != null) {
                      save([
                        for (final t in c.data.life.nutrition.templates)
                          if (t.id == template.id)
                            t.copyWith(until: c.today)
                          else
                            t,
                        replacement,
                      ]);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: context.s('delete'),
                  onPressed: () async {
                    if (await confirmRemoval(context, template.title)) {
                      save([
                        for (final t in c.data.life.nutrition.templates)
                          if (t.id == template.id)
                            t.copyWith(until: c.today)
                          else
                            t,
                      ]);
                    }
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

Future<MealTemplate?> editMealTemplate(
  BuildContext context,
  TaskController c, {
  required Meal meal,
  required List<MealEntry> source,
  required LocalDate date,
  MealTemplate? old,
}) async {
  final name = TextEditingController(text: old?.title ?? context.s(meal.name));
  final days = {
    ...old?.weekdays ?? const [1, 2, 3, 4, 5, 6, 7],
  };
  final key = GlobalKey<FormState>();
  final first = (date.isBefore(c.today) ? c.today : date).addDays(1);
  final result = await showEditor<MealTemplate>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => EditorDialog(
        title: context.s('repeatMeal'),
        formKey: key,
        children: [
          textField(context, name, context.s('templateName')),
          Text('${context.s('start')}: ${first.toIso()}'),
          FormField<bool>(
            validator: (_) => days.isEmpty ? context.s('chooseDay') : null,
            builder: (f) => Column(
              children: [
                Wrap(
                  spacing: 6,
                  children: [
                    for (var d = 1; d <= 7; d++)
                      FilterChip(
                        label: Text(context.s.weekday(d)),
                        selected: days.contains(d),
                        onSelected: (v) =>
                            set(() => v ? days.add(d) : days.remove(d)),
                      ),
                  ],
                ),
                if (f.errorText != null)
                  Text(
                    f.errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
          for (final e in source)
            Text(
              '${foodDisplayName(e.food, context.s.english)} · ${e.grams} g',
            ),
          Text(context.s('mealTemplateHelp')),
        ],
        onSave: () => Navigator.pop(
          context,
          MealTemplate(
            id: c.newLifeId(),
            title: name.text.trim(),
            meal: meal,
            start: first,
            weekdays: days.toList()..sort(),
            foods: [
              for (final e in source)
                TemplateFood(id: c.newLifeId(), food: e.food, grams: e.grams),
            ],
          ),
        ),
      ),
    ),
  );
  name.dispose();
  return result;
}
