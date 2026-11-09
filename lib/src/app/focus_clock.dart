import 'dart:async';

import 'package:flutter/foundation.dart';

/// Wall-clock deadlines survive throttled timers and tab changes. Finishing
/// only enables confirmation; it never checks a task or grants game points.
class FocusClock extends ChangeNotifier {
  FocusClock({DateTime Function()? now, bool tick = true})
    : _now = now ?? DateTime.now {
    if (tick) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => refresh());
    }
  }
  final DateTime Function() _now;
  Timer? _timer;
  DateTime? _deadline;
  int minutes = 25;
  int _remaining = 25 * 60;
  bool completed = false;
  bool recorded = false;
  String taskId = '';
  bool get running => _deadline != null;
  int get remaining => _deadline == null
      ? _remaining
      : ((_deadline!.difference(_now()).inMilliseconds / 1000).ceil()).clamp(
          0,
          minutes * 60,
        );
  void configure(int value) {
    if (running || value < 1 || value > 90) return;
    minutes = value;
    reset();
  }

  void start() {
    if (running || completed) return;
    _deadline = _now().add(Duration(seconds: _remaining));
    notifyListeners();
  }

  void pause() {
    _remaining = remaining;
    _deadline = null;
    if (_remaining == 0) completed = true;
    notifyListeners();
  }

  void refresh() {
    if (!running) return;
    if (remaining == 0) {
      _remaining = 0;
      _deadline = null;
      completed = true;
    }
    notifyListeners();
  }

  void markRecorded() {
    if (!completed || recorded) return;
    recorded = true;
    notifyListeners();
  }

  void reset() {
    _deadline = null;
    _remaining = minutes * 60;
    completed = false;
    recorded = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
