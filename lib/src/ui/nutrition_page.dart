import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/task_controller.dart';
import '../domain/fitness.dart';
import '../domain/local_date.dart';
import '../domain/nutrition.dart';
import '../l10n/strings.dart';
import 'companion_stage.dart';
import 'life_widgets.dart';
import 'wellness_widgets.dart';

Future<List<Food>>? _foods;
Future<List<Food>> loadFoods() => _foods ??= rootBundle
    .loadString('assets/data/foods.json')
    .then((s) => (jsonDecode(s) as List).map(Food.fromJson).toList())
    .catchError((Object error) {
      _foods = null;
      throw error;
    });

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
    final entries = n.entries.where((e) => e.date == date).toList();
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
        for (final old in c.data.life.nutrition.entries)
          if (old.id == e.id) e else old,
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
          child: _FoodPicker(controller: c),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.s('cancel')),
          ),
        ],
      ),
    );

class _FoodPicker extends StatefulWidget {
  const _FoodPicker({required this.controller});
  final TaskController controller;
  @override
  State<_FoodPicker> createState() => _FoodPickerState();
}

class _FoodPickerState extends State<_FoodPicker> {
  String query = '';
  late Future<List<Food>> foods = loadFoods();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(
        key: const Key('food-search'),
        decoration: InputDecoration(
          labelText: context.s('searchFood'),
          prefixIcon: const Icon(Icons.search),
        ),
        onChanged: (v) => setState(() => query = v),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: FutureBuilder<List<Food>>(
          future: foods,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(context.s('foodLoadError')),
                  TextButton(
                    onPressed: () => setState(() => foods = loadFoods()),
                    child: Text(context.s('retry')),
                  ),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final list =
                [
                      ...widget.controller.data.life.nutrition.custom,
                      ...snapshot.data!,
                    ]
                    .where(
                      (f) => '${f.tr} ${f.en}'.toLowerCase().contains(
                        query.toLowerCase(),
                      ),
                    )
                    .toList();
            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) {
                final f = list[i];
                return ListTile(
                  title: Text(f.name(context.s.english)),
                  subtitle: Text(
                    '${displayNumber(context, f.values['energy'])} kcal / 100 g · ${f.source}',
                  ),
                  onTap: () => Navigator.pop(context, f),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}

Future<MealEntry?> editMeal(
  BuildContext context,
  TaskController c,
  Food food,
  LocalDate date, [
  MealEntry? old,
]) async {
  final grams = TextEditingController(
    text: old == null ? '' : compactNumber(old.grams),
  );
  var meal = old?.meal ?? Meal.breakfast;
  var eaten = old?.eaten ?? false;
  final key = GlobalKey<FormState>();
  final result = await showEditor<MealEntry>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => EditorDialog(
        title: food.name(context.s.english),
        formKey: key,
        children: [
          numberField(
            context,
            grams,
            context.s('grams'),
            min: .1,
            max: 10000,
            required: true,
            key: const Key('meal-grams'),
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
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: eaten,
            title: Text(context.s('markEaten')),
            onChanged: date.isAfter(c.today)
                ? null
                : (v) => set(() => eaten = v!),
          ),
          Text(food.source),
        ],
        onSave: () => Navigator.pop(
          context,
          MealEntry(
            id: old?.id ?? c.newLifeId(),
            date: date,
            food: food,
            grams: parseDecimal(grams.text)!,
            meal: meal,
            eaten: eaten,
          ),
        ),
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
