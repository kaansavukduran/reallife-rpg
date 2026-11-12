import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';

/// Integer base XP; changes are draft-only until the editor is saved.
class TaskXpControl extends StatefulWidget {
  const TaskXpControl({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<TaskXpControl> createState() => _TaskXpControlState();
}

class _TaskXpControlState extends State<TaskXpControl> {
  late final FocusNode focus = FocusNode(onKeyEvent: handleKey);
  late int current = widget.value;
  @override
  void didUpdateWidget(TaskXpControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    current = widget.value;
  }

  void change(int value) {
    current = value;
    widget.onChanged(value);
  }

  KeyEventResult handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.home) {
      change(0);
    } else if (key == LogicalKeyboardKey.end) {
      change(100);
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowDown) {
      change((current - 1).clamp(0, 100));
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp) {
      change((current + 1).clamp(0, 100));
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final onChanged = change;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              context.s('taskXp'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text('$value XP', key: const Key('editor-xp-value')),
          ],
        ),
        Slider(
          focusNode: focus,
          onChangeStart: (_) => focus.requestFocus(),
          key: const Key('editor-difficulty'),
          value: value.toDouble(),
          min: 0,
          max: 100,
          divisions: 100,
          label: '$value XP',
          semanticFormatterCallback: (v) => '${v.round()} XP',
          onChanged: (v) => onChanged(v.round()),
        ),
        const Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          runSpacing: 4,
          children: [Text('0 XP'), Text('100 XP')],
        ),
        const SizedBox(height: 4),
        Text(
          context.s('taskXpHelp'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
