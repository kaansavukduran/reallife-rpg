import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/food_search.dart';
import '../l10n/strings.dart';
import 'food_catalog.dart';
import 'wellness_widgets.dart';

class FoodBrowser extends StatefulWidget {
  const FoodBrowser({super.key, required this.controller});
  final TaskController controller;
  @override
  State<FoodBrowser> createState() => _FoodBrowserState();
}

class _FoodBrowserState extends State<FoodBrowser> {
  late Future<FoodCatalog> catalog = loadFoodCatalog();
  final search = TextEditingController();
  final scroll = ScrollController();
  void top() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && scroll.hasClients) scroll.jumpTo(0);
  });
  void selectFamily(String? value) {
    setState(() {
      family = value;
      part = null;
      form = null;
    });
    top();
  }

  String? category, family, part, form;
  void chooseCategory(String? value) {
    setState(() {
      category = value;
      family = null;
      part = null;
      form = null;
      search.clear();
    });
    top();
  }

  @override
  void dispose() {
    scroll.dispose();
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return FutureBuilder<FoodCatalog>(
      future: catalog,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Column(
            children: [
              Text(s('foodLoadError')),
              TextButton(
                onPressed: () => setState(() => catalog = loadFoodCatalog()),
                child: Text(s('retry')),
              ),
            ],
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final entries = [
          ...widget.controller.data.life.nutrition.custom.map(
            CatalogFood.custom,
          ),
          ...data.entries,
        ];
        final children = <Widget>[
          Wrap(
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed: () => chooseCategory(null),
                child: Text(s('foodGroups')),
              ),
              if (category != null) ...[
                const Icon(Icons.chevron_right, size: 18),
                TextButton(
                  onPressed: () => chooseCategory(category),
                  child: Text(s('foodCategory.$category')),
                ),
              ],
              if (family != null)
                IconButton(
                  tooltip: s(part == null ? 'backToFoods' : 'backToFoodParts'),
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => selectFamily(part == null ? null : family),
                ),
            ],
          ),
          TextField(
            key: const Key('food-search'),
            controller: search,
            enabled: category != null,
            decoration: InputDecoration(
              labelText: s('searchFood'),
              helperText: category == null ? s('chooseFoodCategory') : null,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: s('clearFilters'),
                      onPressed: () => setState(search.clear),
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
        ];
        if (category == null) {
          for (final id in data.categories.where(
            (id) => entries.any((e) => e.category == id),
          )) {
            final items = entries.where((e) => e.category == id).toList();
            final count = items.map((e) => e.family).toSet().length;
            children.add(
              Card(
                child: ListTile(
                  key: Key('food-category-$id'),
                  leading: const Icon(Icons.restaurant_outlined),
                  title: Text(s('foodCategory.$id')),
                  subtitle: Text(
                    '$count ${s('foodFamilies')} · ${items.length} ${s('foodForms')}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => chooseCategory(id),
                ),
              ),
            );
          }
        } else {
          final selected = entries
              .where(
                (e) =>
                    e.category == category &&
                    (family == null || e.family == family) &&
                    (part == null || e.part == part) &&
                    (foodMatches(e.food, search.text) ||
                        [
                          e.familyTr,
                          e.familyEn,
                          e.partTr ?? '',
                          e.partEn ?? '',
                        ].any(
                          (label) =>
                              normalizedFoodText(label)
                                  .contains(normalizedFoodText(search.text)),
                        )),
              )
              .toList();
          if (family == null) {
            final groups = <String, List<CatalogFood>>{};
            for (final entry in selected) {
              groups.putIfAbsent(entry.family, () => []).add(entry);
            }
            final keys = groups.keys.toList()
              ..sort(
                (a, b) => groups[a]!.first
                    .familyName(s.english)
                    .compareTo(groups[b]!.first.familyName(s.english)),
              );
            for (final id in keys) {
              final items = groups[id]!;
              children.add(
                ListTile(
                  key: Key('food-family-$id'),
                  title: Text(items.first.familyName(s.english)),
                  subtitle: Text('${items.length} ${s('foodForms')}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => selectFamily(id),
                ),
              );
            }
            if (keys.isEmpty) children.add(Text(s('noResults')));
          } else if (part == null && selected.any((e) => e.part != null)) {
            children.add(
              Text(
                '${selected.first.familyName(s.english)} · ${s('chooseFoodPart')}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
            final groups = <String, List<CatalogFood>>{};
            for (final entry in selected) {
              groups.putIfAbsent(entry.part!, () => []).add(entry);
            }
            final keys = groups.keys.toList()
              ..sort(
                (a, b) => groups[a]!.first
                    .partName(s.english)
                    .compareTo(groups[b]!.first.partName(s.english)),
              );
            for (final id in keys) {
              final items = groups[id]!;
              children.add(
                ListTile(
                  key: Key('food-part-$id'),
                  title: Text(items.first.partName(s.english)),
                  subtitle: Text('${items.length} ${s('foodForms')}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    setState(() {
                      part = id;
                      form = null;
                    });
                    top();
                  },
                ),
              );
            }
          } else {
            final forms = selected.map((e) => e.form).toSet();
            final results = selected
                .where((e) => form == null || e.form == form)
                .toList();
            children.addAll([
              Text(
                selected.isEmpty
                    ? ''
                    : [
                        selected.first.familyName(s.english),
                        if (part != null) selected.first.partName(s.english),
                      ].join(' · '),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  FilterChip(
                    label: Text(s('allForms')),
                    selected: form == null,
                    onSelected: (_) => setState(() => form = null),
                  ),
                  for (final type in forms)
                    FilterChip(
                      key: Key('food-form-$type'),
                      label: Text(s('foodForm.$type')),
                      selected: form == type,
                      onSelected: (_) =>
                          setState(() => form = form == type ? null : type),
                    ),
                ],
              ),
              if (results.isEmpty) Text(s('noResults')),
              for (final entry in results)
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        key: Key('food-choice-${entry.food.id}'),
                        title: Text(entry.food.name(s.english)),
                        subtitle: Text(
                          '${displayNumber(context, entry.food.values['energy'])} kcal / 100 g',
                        ),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () => Navigator.pop(context, entry.food),
                      ),
                      ExpansionTile(
                        title: Text(s('foodSourceDetails')),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: SelectableText(
                              '${entry.food.en}\n${entry.food.source}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ]);
          }
        }
        return ListView(
          controller: scroll,
          key: const Key('food-browser-scroll'),
          children: children,
        );
      },
    );
  }
}
