import 'package:flutter/material.dart';

/// Keep the selected physical scale and let pages reflow in the available width.
/// Ordinary content must not acquire a whole-app horizontal scroll viewport.
class InterfaceScale extends StatelessWidget {
  const InterfaceScale({super.key, required this.scale, required this.child});
  final double scale;
  final Widget child;

  static double of(BuildContext context) =>
      context.findAncestorWidgetOfExactType<InterfaceScale>()?.scale ?? 1;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(
        constraints.maxWidth / scale,
        constraints.maxHeight / scale,
      );
      final media = MediaQuery.of(context);
      final theme = Theme.of(context);
      return SizedBox(
        key: const Key('interface-reflow'),
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        child: FittedBox(
          fit: BoxFit.fill,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: MediaQuery(
              data: media.copyWith(
                size: size,
                padding: media.padding / scale,
                viewPadding: media.viewPadding / scale,
                viewInsets: media.viewInsets / scale,
              ),
              child: Theme(
                data: size.width < 360
                    ? theme.copyWith(
                        dialogTheme: theme.dialogTheme.copyWith(
                          constraints: const BoxConstraints(minWidth: 0),
                          insetPadding: const EdgeInsets.all(12),
                        ),
                      )
                    : theme,
                child: child,
              ),
            ),
          ),
        ),
      );
    },
  );
}
