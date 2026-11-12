import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../l10n/strings.dart';
import 'life_widgets.dart';
import 'task_actions.dart';

/// A stable preview: completing a row never removes the focused control.
class TodayTaskCard extends StatelessWidget {
  const TodayTaskCard({
    super.key,
    required this.controller,
    required this.openDay,
  });

  final TaskController controller;
  final VoidCallback openDay;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final date = controller.today;
    final tasks = controller.data.tasksOn(date);
    final done = tasks.where((t) => controller.data.isDone(t.id, date)).length;
    return LifeCard(
      key: const Key('adventure-today'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            header: true,
            child: Text(
              s('todayTasks'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tasks.isEmpty
                ? s(
                    controller.data.tasks.isEmpty
                        ? 'firstTaskHelp'
                        : 'noTasksToday',
                  )
                : s('todayTaskHelp'),
          ),
          if (tasks.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              s('taskProgress')
                  .replaceAll('{done}', '$done')
                  .replaceAll('{total}', '${tasks.length}'),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: done / tasks.length,
              semanticsLabel: s('todayTasks'),
              borderRadius: BorderRadius.circular(8),
              minHeight: 6,
            ),
            const SizedBox(height: 12),
            for (final task in tasks.take(4))
              Padding(
                key: ValueKey(task.id),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Material(
                  color: scheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: scheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Semantics(
                        container: true,
                        identifier: 'adventure-checkbox-${task.id}',
                        child: Checkbox(
                          key: ValueKey('adventure-check-${task.id}'),
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          semanticLabel: '${task.title} · ${s('markDone')}',
                          value: controller.data.isDone(task.id, date),
                          onChanged: (_) {
                            final before = controller.data;
                            final checked = controller.toggle(task.id, date);
                            final after = controller.data;
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
                              SnackBar(
                                duration: const Duration(seconds: 8),
                                content: Text(
                                  s(checked ? 'taskMarked' : 'taskUnmarked'),
                                ),
                                action: SnackBarAction(
                                  label: s('undo'),
                                  onPressed: () {
                                    if (!controller.undoTick(
                                      task.id,
                                      date,
                                      before: before,
                                      after: after,
                                    )) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(s('tickUndoExpired')),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          key: ValueKey('adventure-edit-${task.id}'),
                          style: TextButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            foregroundColor: scheme.onSurface,
                            minimumSize: const Size(48, 64),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () => editTask(context, controller, task),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s(
                                  controller.data.isDone(task.id, date)
                                      ? 'taskDoneState'
                                      : 'taskPendingState',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (done == tasks.length)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(s('todayComplete')),
              ),
            if (tasks.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  s('taskPreviewCount')
                      .replaceAll('{total}', '${tasks.length}'),
                ),
              ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: openDay,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(s('openToday')),
          ),
        ],
      ),
    );
  }
}
