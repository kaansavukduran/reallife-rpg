import 'package:flutter/material.dart';

/// Shares hover coordinates without rebuilding task/food lists or storing data.
class AppPointer extends InheritedWidget {
  const AppPointer({super.key, required this.position, required super.child});
  final ValueNotifier<Offset?> position;
  static ValueNotifier<Offset?>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppPointer>()?.position;
  @override
  bool updateShouldNotify(AppPointer old) => old.position != position;
}

class PointerTracking extends StatefulWidget {
  const PointerTracking({super.key, required this.child});
  final Widget child;
  @override
  State<PointerTracking> createState() => _PointerTrackingState();
}

class _PointerTrackingState extends State<PointerTracking> {
  final position = ValueNotifier<Offset?>(null);
  @override
  void dispose() {
    position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPointer(
    position: position,
    child: MouseRegion(
      opaque: false,
      onHover: (e) => position.value = e.position,
      onExit: (_) => position.value = null,
      child: widget.child,
    ),
  );
}
