import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/task_controller.dart';
import '../domain/fitness.dart';
import 'food_browser.dart';
export 'food_catalog.dart' show loadFoods;
import 'meal_templates.dart';
import '../domain/local_date.dart';
import '../domain/nutrition.dart';
import '../l10n/strings.dart';
import 'companion_stage.dart';
import 'life_widgets.dart';
import 'wellness_widgets.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key, required this.controller});
  final TaskController controller;
  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  late LocalDate date = widget.controller.today;
  bool eatenView = true;
  TaskController get c => widget.controller;
  void save(NutritionData n) =>
      c.updateLife(c.data.life.copyWith(nutrition: n));
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final n = c.data.life.nutrition;
    final entries = n.entriesOn(date);
    final totals = entries.where((e) => !eatenView || e.eaten).toList();
    return LifePage(
      children: [
        PageHeading(
          'Besin Matriksi × RealLife RPG',
          s('nutrition'),
          s('nutritionIntro'),
        ),
        WellnessDateBar(
          date: date,
          today: c.today,
          onChanged: (v) => setState(() => date = v),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              key: const Key('add-meal'),
              onPressed: () => _add(),
              icon: const Icon(Icons.add),
              label: Text(s('addFood')),
            ),
            OutlinedButton.icon(
              key: const Key('custom-food'),
              onPressed: () async {
                final f = await editFood(context, c);
                if (f == null) return;
                save(
                  c.data.life.nutrition.copyWith(
                    custom: [...c.data.life.nutrition.custom, f],
                  ),
                );
              },
              icon: const Icon(Icons.edit_note),
              label: Text(s('customFood')),
            ),
            TextButton.icon(
              onPressed: () => _targets(),
              icon: const Icon(Icons.tune),
              label: Text(s('targets')),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LifeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(s('eaten')),
                    selected: eatenView,
                    onSelected: (_) => setState(() => eatenView = true),
                  ),
                  ChoiceChip(
                    label: Text('${s('planned')} + ${s('eaten')}'),
                    selected: !eatenView,
                    onSelected: (_) => setState(() => eatenView = false),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final key in [
                    'energy',
                    'protein',
                    'carb',
                    'fat',
                    'fiber',
                  ])
                    SizedBox(
                      width: 165,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s(key),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          Text(
                            '${totals.isEmpty ? '—' : displayNumber(context, nutrientTotal(totals, key).known)} ${nutrientUnit(key)}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${s('coverage')}: ${nutrientTotal(totals, key).covered}/${totals.length}',
                          ),
                          if (n.targets[key] != null)
                            Text(
                              '${s('target')}: ${displayNumber(context, n.targets[key])} ${nutrientUnit(key)}',
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(s('missing')),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (entries.isEmpty) LifeCard(child: Text(s('emptyMeals'))),
        for (final meal in Meal.values)
          if (entries.any((e) => e.meal == meal)) ...[
            Text(s(meal.name), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final entry in entries.where((e) => e.meal == meal)) ...[
              LifeCard(
                padding: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CheckboxListTile(
                      key: Key('eaten-${entry.id}'),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(entry.food.name(s.english)),
                      subtitle: Text(
                        '${displayNumber(context, entry.grams)} g · ${s(entry.eaten ? 'eaten' : 'planned')}',
                      ),
                      value: entry.eaten,
                      onChanged: date.isAfter(c.today)
                          ? null
                          : (v) => _replace(entry.copyWith(eaten: v)),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () async {
                            final changed = await editMeal(
                              context,
                              c,
                              entry.food,
                              date,
                              entry,
                            );
                            if (changed != null) _replace(changed);
                          },
                          child: Text(s('edit')),
                        ),
                        TextButton(
                          onPressed: () => _remove(entry),
                          child: Text(s('delete')),
                        ),
                        TextButton(
                          onPressed: () => foodDetails(context, entry.food),
                          child: Text(s('per100')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 14),
          ],
        MealTemplates(controller: c, date: date, entries: entries),
        ExpansionTile(
          key: const Key('nutrient-matrix'),
          title: Text(s('matrix')),
          children: [
            // Horizontal scrolling is explicit; text and the chosen UI scale stay intact.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text(s('matrix'))),
                  for (final entry in totals)
                    DataColumn(
                      label: SizedBox(
                        width: 130,
                        child: Text(
                          '${entry.food.name(s.english)}\n${displayNumber(context, entry.grams)} g',
                        ),
                      ),
                    ),
                  DataColumn(label: Text(s('total'))),
                ],
                rows: [
                  for (final key in nutrientKeys)
                    DataRow(
                      cells: [
                        DataCell(Text('${s(key)} (${nutrientUnit(key)})')),
                        for (final entry in totals)
                          DataCell(
                            Text(
                              displayNumber(
                                context,
                                entry.food.values[key] == null
                                    ? null
                                    : entry.food.values[key]! *
                                          entry.grams /
                                          100,
                              ),
                            ),
                          ),
                        DataCell(
                          Text(
                            '${totals.isEmpty ? '—' : displayNumber(context, nutrientTotal(totals, key).known)} · ${nutrientTotal(totals, key).covered}/${totals.length}',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        LifeCard(
          child: Column(
            children: [
              CompanionStage(
                character: c.data.life.companion,
                motion: Motion.eat,
                autoplay: true,
                height: 240,
                controls: true,
              ),
              Text(s('catalogSource')),
              TextButton(
                onPressed: () async {
                  final notice = await rootBundle.loadString(
                    'assets/data/NOTICE.txt',
                  );
                  if (!context.mounted) return;
                  await showDialog<void>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: Text(c.s('source')),
                      scrollable: true,
                      content: SelectableText(notice),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: Text(c.s('close')),
                        ),
                      ],
                    ),
                  );
                },
                child: Text(s('source')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _replace(MealEntry e) => save(
    c.data.life.nutrition.copyWith(
      entries: [
        ...c.data.life.nutrition.entries.where((old) => old.id != e.id),
        e,
      ],
    ),
  );
  Future<void> _add() async {
    final food = await pickFood(context, c);
    if (food == null || !mounted) return;
    final entry = await editMeal(context, c, food, date);
    if (entry == null || !mounted) return;
    save(
      c.data.life.nutrition.copyWith(
        entries: [...c.data.life.nutrition.entries, entry],
      ),
    );
    showSaved(context);
  }

  void _remove(MealEntry entry) {
    save(
      c.data.life.nutrition.copyWith(
        entries: c.data.life.nutrition.entries
            .where((e) => e.id != entry.id)
            .toList(),
        omitted: {
          ...c.data.life.nutrition.omitted,
          if (entry.id.startsWith('template:')) entry.id,
        },
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.s('deleted')),
        action: SnackBarAction(
          label: context.s('undo'),
          onPressed: () {
            if (!c.data.life.nutrition.entries.any((e) => e.id == entry.id)) {
              save(
                c.data.life.nutrition.copyWith(
                  entries: [...c.data.life.nutrition.entries, entry],
                  omitted: c.data.life.nutrition.omitted
                      .where((id) => id != entry.id)
                      .toSet(),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _targets() async {
    final keys = ['energy', 'protein', 'carb', 'fat', 'fiber'];
    final fields = {
      for (final key in keys)
        key: TextEditingController(
          text: compactNumber(c.data.life.nutrition.targets[key])
              .replaceAll('—', ''),
        ),
    };
    final form = GlobalKey<FormState>();
    final values = await showEditor<Map<String, double>>(
      context: context,
      builder: (context) => EditorDialog(
        title: context.s('targets'),
        formKey: form,
        children: [
          Text(context.s('targetsHelp')),
          for (final k in keys)
            numberField(
              context,
              fields[k]!,
              '${context.s(k)} (${nutrientUnit(k)})',
              min: .1,
              max: k == 'energy' ? 15000 : 2000,
            ),
        ],
        onSave: () => Navigator.pop(context, <String, double>{
          for (final key in keys)
            if (fields[key]!.text.trim().isNotEmpty)
              key: parseDecimal(fields[key]!.text)!,
        }),
      ),
    );
    if (values != null) save(c.data.life.nutrition.copyWith(targets: values));
    for (final field in fields.values) {
      field.dispose();
    }
  }
}

Future<Food?> pickFood(BuildContext context, TaskController c) =>
    showEditor<Food>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.s('addFood')),
        content: SizedBox(
          width: 740,
          height: MediaQuery.sizeOf(context).height * .65,
          child: FoodBrowser(controller: c),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.s('cancel')),
          ),
        ],
      ),
    );

Future<MealEntry?> editMeal(
  BuildContext context,
  TaskController c,
  Food food,
  LocalDate date, [
  MealEntry? old,
]) async {
  final grams = TextEditingController(
    text: old == null ? '100' : compactNumber(old.grams),
  );
  var kilograms = false;
  var meal = old?.meal ?? Meal.breakfast;
  final eaten = old?.eaten ?? !date.isAfter(c.today);
  final key = GlobalKey<FormState>();
  final result = await showEditor<MealEntry>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => ValueListenableBuilder<TextEditingValue>(
        valueListenable: grams,
        builder: (context, value, _) {
          final input = parseDecimal(value.text);
          final amount = input == null ? null : input * (kilograms ? 1000 : 1);
          final max = amount != null && amount > 1000 ? 10000.0 : 1000.0;
          return EditorDialog(
            title: food.name(context.s.english),
            formKey: key,
            children: [
              numberField(
                context,
                grams,
                kilograms ? '${context.s('amount')} (kg)' : context.s('grams'),
                min: kilograms ? .0001 : .1,
                max: kilograms ? 10 : 10000,
                required: true,
                key: const Key('meal-grams'),
              ),
              SegmentedButton<bool>(
                key: const Key('meal-unit'),
                segments: const [
                  ButtonSegment(value: false, label: Text('g')),
                  ButtonSegment(value: true, label: Text('kg')),
                ],
                selected: {kilograms},
                onSelectionChanged: (v) => set(() {
                  final canonical = parseDecimal(grams.text);
                  final oldMultiplier = kilograms ? 1000 : 1;
                  kilograms = v.first;
                  if (canonical != null) {
                    grams.text =
                        (canonical * oldMultiplier / (kilograms ? 1000 : 1))
                            .toString();
                  }
                }),
              ),
              Text(
                '${context.s('portionPreview')}: ${displayNumber(context, amount)} g',
              ),
              Slider(
                key: const Key('meal-grams-slider'),
                min: .1,
                max: max,
                divisions: max == 1000 ? 9999 : 99999,
                value: amount != null && amount.isFinite
                    ? amount.clamp(.1, max)
                    : 100,
                label: '${displayNumber(context, amount)} g',
                onChanged: (v) => grams.text = kilograms
                    ? (double.parse(v.toStringAsFixed(1)) / 1000).toString()
                    : v.toStringAsFixed(1),
              ),
              if (amount != null &&
                  amount.isFinite &&
                  amount > 0 &&
                  amount <= 10000)
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    for (final k in ['energy', 'protein', 'carb', 'fat'])
                      Text(
                        '${context.s(k)}: ${displayNumber(context, food.values[k] == null ? null : food.values[k]! * amount / 100)} ${nutrientUnit(k)}',
                      ),
                  ],
                ),
              DropdownButtonFormField<Meal>(
                initialValue: meal,
                decoration: InputDecoration(labelText: context.s('meal')),
                items: [
                  for (final m in Meal.values)
                    DropdownMenuItem(value: m, child: Text(context.s(m.name))),
                ],
                onChanged: (v) => set(() => meal = v!),
              ),
              Text(context.s(eaten ? 'manualMealEaten' : 'mealStaysPlanned')),
              Text(food.source),
            ],
            onSave: () => Navigator.pop(
              context,
              MealEntry(
                id: old?.id ?? c.newLifeId(),
                date: date,
                food: food,
                grams: parseDecimal(grams.text)! * (kilograms ? 1000 : 1),
                meal: meal,
                eaten: eaten,
              ),
            ),
          );
        },
      ),
    ),
  );
  grams.dispose();
  return result;
}

Future<Food?> editFood(BuildContext context, TaskController c) async {
  final tr = TextEditingController(), en = TextEditingController();
  final fields = {for (final key in nutrientKeys) key: TextEditingController()};
  final key = GlobalKey<FormState>();
  final result = await showEditor<Food>(
    context: context,
    builder: (context) => EditorDialog(
      title: context.s('customFood'),
      formKey: key,
      children: [
        textField(context, tr, context.s('nameTr')),
        textField(context, en, context.s('nameEn')),
        Text(context.s('per100')),
        Text(context.s('missing')),
        for (final k in nutrientKeys.take(5))
          numberField(
            context,
            fields[k]!,
            '${context.s(k)} (${nutrientUnit(k)})',
            max: k == 'energy' ? 1000 : 100,
          ),
        ExpansionTile(
          title: Text(context.s('matrix')),
          children: [
            for (final k in nutrientKeys.skip(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: numberField(
                  context,
                  fields[k]!,
                  '${context.s(k)} (${nutrientUnit(k)})',
                  max: nutrientUnit(k) == 'g' ? 100 : 1000000,
                ),
              ),
          ],
        ),
      ],
      onSave: () => Navigator.pop(
        context,
        Food(
          id: 'food-${c.newLifeId()}',
          tr: tr.text.trim(),
          en: en.text.trim(),
          source: 'Manual label / user entry',
          values: {
            for (final k in nutrientKeys)
              if (fields[k]!.text.trim().isNotEmpty)
                k: parseDecimal(fields[k]!.text)!,
          },
        ),
      ),
    ),
  );
  for (final field in [tr, en, ...fields.values]) {
    field.dispose();
  }
  return result;
}

Future<void> foodDetails(BuildContext context, Food f) => showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(f.name(context.s.english)),
    scrollable: true,
    content: SizedBox(
      width: 500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(f.source),
          const SizedBox(height: 12),
          Text(context.s('per100')),
          for (final key in nutrientKeys)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(
                '${context.s(key)}: ${displayNumber(context, f.values[key])} ${nutrientUnit(key)}',
              ),
            ),
          Text(context.s('missing')),
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
