import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Preserve the selected physical scale. Narrow screens keep a usable logical
/// width and explicitly scroll instead of silently reducing the user's choice.
class InterfaceScale extends StatefulWidget {
  const InterfaceScale({super.key, required this.scale, required this.child});
  final double scale;
  final Widget child;
  @override
  State<InterfaceScale> createState() => _InterfaceScaleState();
}

class _InterfaceScaleState extends State<InterfaceScale> {
  final ScrollController _horizontal = ScrollController();
  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = widget.scale;
      final width = math.max(360.0, constraints.maxWidth / scale);
      final size = Size(width, constraints.maxHeight / scale);
      final media = MediaQuery.of(context);
      final overflow = width * scale > constraints.maxWidth + .1;
      final content = SizedBox(
        width: width * scale,
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
              child: widget.child,
            ),
          ),
        ),
      );
      return Scrollbar(
        controller: _horizontal,
        thumbVisibility: overflow,
        notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
        child: SingleChildScrollView(
          key: const Key('interface-horizontal-scroll'),
          controller: _horizontal,
          scrollDirection: Axis.horizontal,
          physics: overflow ? null : const NeverScrollableScrollPhysics(),
          child: content,
        ),
      );
    },
  );
}
