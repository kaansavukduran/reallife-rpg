import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Mouse: click and move. Touch: long press and move, keeping normal vertical
/// scrolling available on phones. A stationary click still reaches the card.
class TaskDragRegion extends StatelessWidget {
  const TaskDragRegion({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.grab,
    child: Listener(
      onPointerDown: (event) {
        if (event.buttons != kPrimaryButton) return;
        final list = SliverReorderableList.maybeOf(context);
        if (list == null) return;
        final recognizer = event.kind == PointerDeviceKind.mouse
            ? ImmediateMultiDragGestureRecognizer(debugOwner: this)
            : DelayedMultiDragGestureRecognizer(debugOwner: this);
        recognizer.gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
        list.startItemDragReorder(
          index: index,
          event: event,
          recognizer: recognizer,
        );
      },
      child: child,
    ),
  );
}
