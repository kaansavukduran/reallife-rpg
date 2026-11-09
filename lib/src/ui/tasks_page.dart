import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/local_date.dart';
import '../domain/repeat_rule.dart';
import '../domain/task.dart';
import '../domain/turkish_dates.dart';
import '../l10n/strings.dart';
import 'game_widgets.dart';
import 'task_actions.dart';
import 'task_drag_region.dart';
import 'task_editor.dart';

enum _Filter { active, ended, all }

/// Every task: edit, end, restart, delete, reorder.
class TasksPage extends StatefulWidget {
  const TasksPage({super.key, required this.controller});

  final TaskController controller;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  _Filter _filter = _Filter.active;
  LocalDate? _selectedDay;

  TaskController get controller => widget.controller;

  bool _shown(Task t) {
    final active = t.hasFutureOn(controller.today);
    return switch (_filter) {
      _Filter.active => active,
      _Filter.ended => !active,
      _Filter.all => true,
    };
  }

  void _reorder(List<Task> shown, int oldIndex, int newIndex) {
    controller.reorderVisible(
      shown.map((t) => t.id).toList(),
      oldIndex,
      newIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = _selectedDay ?? controller.today;
    final tasks = [
      for (final t in controller.data.tasks)
        if (_shown(t)) t,
    ];
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: CustomScrollView(
          slivers: [
            SliverList.list(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Tüm görevler',
                        style: theme.textTheme.headlineSmall,
                      ),
                      SegmentedButton<_Filter>(
                        key: const Key('tasks-filter'),
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: _Filter.active,
                            label: Text('Süren'),
                          ),
                          ButtonSegment(
                            value: _Filter.ended,
                            label: Text('Biten'),
                          ),
                          ButtonSegment(
                            value: _Filter.all,
                            label: Text('Tümü'),
                          ),
                        ],
                        selected: {_filter},
                        onSelectionChanged: (s) =>
                            setState(() => _filter = s.first),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('tasks-completion-date'),
                        icon: const Icon(Icons.event_outlined),
                        label: Text(
                          '${context.s('tickDate')}: ${day == controller.today ? context.s('today') : '${shortDate(day)} ${day.year}'}',
                        ),
                        onPressed: () async {
                          final picked = await pickDate(
                            context,
                            initial: day,
                            help: context.s('tickDate'),
                          );
                          if (picked != null && mounted) {
                            setState(() => _selectedDay = picked);
                          }
                        },
                      ),
                      if (day != controller.today)
                        TextButton(
                          key: const Key('tasks-today'),
                          onPressed: () => setState(() => _selectedDay = null),
                          child: Text(context.s('today')),
                        ),
                      Text(
                        context.s('taskTickHelp'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Fareyle görev kartını tutup yukarı/aşağı sürükle. Telefonda basılı tut. Tek tık düzenler; sıra otomatik kaydedilir.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (tasks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(switch (_filter) {
                    _Filter.active => 'Süren görev yok.',
                    _Filter.ended => 'Biten görev yok.',
                    _Filter.all => 'Henüz görev yok.',
                  }, style: theme.textTheme.titleMedium),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 96),
                sliver: SliverReorderableList(
                  itemCount: tasks.length,
                  onReorderItem: (a, b) => _reorder(tasks, a, b),
                  itemBuilder: (context, i) => TaskDragRegion(
                    index: i,
                    key: ValueKey(tasks[i].id),
                    child: _TaskCard(
                      controller: controller,
                      task: tasks[i],
                      day: day,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.controller,
    required this.task,
    required this.day,
  });

  final TaskController controller;
  final Task task;
  final LocalDate day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = controller.today;
    final data = controller.data;
    final done = data.isDone(task.id, day);
    final future = day.isAfter(today);
    final active = task.hasFutureOn(today);
    final rule = task.ruleOn(today) ?? task.lastRule;
    final stats = data.statsFor(
      task,
      from: today.addDays(-29),
      to: today,
      today: today,
    );
    final small = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final String state;
    if (task.isEndedOn(today)) {
      final end = task.schedule
          .lastWhere((s) => s.rule == null && !s.from.isAfter(today))
          .from;
      state = '${shortDate(end)} gününden beri sonlandırılmış';
    } else if (!active) {
      state = 'Günü geçti';
    } else if (rule is OnceRule) {
      state = rule.date == today ? 'Bugün' : 'Henüz gelmedi';
    } else if (task.startDate.isAfter(today)) {
      state = '${shortDate(task.startDate)} gününde başlayacak';
    } else {
      state =
          '${shortDate(task.startDate)} ${task.startDate.year} gününden beri';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            controller.settings.appearance.radius ?? 14,
          ),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('task-card-${task.id}'),
          onTap: () => editTask(context, controller, task),
          onSecondaryTapUp: (d) =>
              showTaskMenuAt(context, controller, task, d.globalPosition),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Tooltip(
                    message: 'Tut ve yukarı/aşağı sürükle',
                    child: Icon(Icons.drag_indicator_rounded),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: active ? null : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (rule != null) describeRule(rule),
                          state,
                          if (task.time != null) 'Saat ${task.time!.format()}',
                        ].join('  ·  '),
                        style: small,
                      ),
                      if (task.note.isNotEmpty) Text(task.note, style: small),
                      const SizedBox(height: 4),
                      Text(
                        stats.settled == 0
                            ? 'Son 30 gün: henüz sonuçlanan gün yok'
                            : 'Son 30 gün: ${stats.settled} günün ${stats.done} gününde yapıldı'
                                  '${stats.streak > 0 ? '  ·  seri ${stats.streak} gün' : ''}',
                        key: Key('task-stats-${task.id}'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: future
                      ? context.s('futureTick')
                      : context.s(done ? 'untickTask' : 'tickTask'),
                  child: Checkbox(
                    key: Key('tasks-check-${task.id}'),
                    value: done,
                    semanticLabel:
                        '${task.title}: ${context.s(done ? 'taskDone' : 'tickTask')} · ${day.toIso()}',
                    onChanged: future
                        ? null
                        : (_) {
                            final before = controller.data;
                            withGameFeedback(
                              context,
                              controller,
                              () => controller.toggle(task.id, day),
                            );
                            if (done) {
                              showUndoSnack(
                                context,
                                '${task.title}: ${context.s('untickTask')}',
                                onUndo: () => controller.restore(before),
                              );
                            }
                          },
                  ),
                ),
                TaskMenu(controller: controller, task: task),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
