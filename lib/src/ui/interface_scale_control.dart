import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/task_controller.dart';

/// Keep the track still while it is being dragged. The percentage and sample
/// update continuously; releasing applies the scale to the whole interface.
/// This also avoids queuing a settings-file write for every pointer movement.
class InterfaceScaleControl extends StatefulWidget {
  const InterfaceScaleControl({super.key, required this.controller});
  final TaskController controller;

  @override
  State<InterfaceScaleControl> createState() => _InterfaceScaleControlState();
}

class _InterfaceScaleControlState extends State<InterfaceScaleControl> {
  static const _minimum = 80;
  static const _maximum = 200;
  late int _percent = _savedPercent;
  late final _text = TextEditingController(text: '$_percent');
  final _focus = FocusNode();
  bool _dragging = false;
  String? _error;

  int get _savedPercent => (widget.controller.settings.safeScale * 100).round();

  @override
  void didUpdateWidget(InterfaceScaleControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && !_focus.hasFocus && _savedPercent != _percent) {
      _percent = _savedPercent;
      _text.text = '$_percent';
      _error = null;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _preview(int value) {
    setState(() {
      _percent = value;
      _text.text = '$value';
      _error = null;
    });
  }

  void _apply(int value) {
    _preview(value);
    if (_savedPercent != value) {
      unawaited(
        widget.controller.updateSettings(
          widget.controller.settings.copyWith(uiScale: value / 100),
        ),
      );
    }
  }

  int? _parse(String text) {
    final value = int.tryParse(text.trim());
    return value != null && value >= _minimum && value <= _maximum
        ? value
        : null;
  }

  void _applyText() {
    final value = _parse(_text.text);
    if (value == null) {
      setState(() => _error = '80–200 arasında tam sayı gir.');
      return;
    }
    _focus.unfocus();
    _apply(value);
  }

  void _reset() {
    _focus.unfocus();
    _dragging = false;
    _apply(100);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Arayüz ölçeği: %$_percent',
              key: const Key('scale-label'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Çubuğu sağa veya sola sürükle. Yüzde ve örnek görünüm anında '
              'değişir; bıraktığında tüm arayüze uygulanır ve kaydedilir.',
            ),
            const SizedBox(height: 14),
            Semantics(
              label: 'Arayüz ölçeği',
              identifier: 'interface-scale-track',
              container: true,
              child: Slider(
                key: const Key('interface-scale-slider'),
                min: _minimum.toDouble(),
                max: _maximum.toDouble(),
                divisions: _maximum - _minimum,
                value: _percent.toDouble(),
                label: '%$_percent',
                semanticFormatterCallback: (value) => 'Yüzde ${value.round()}',
                onChangeStart: (_) {
                  _focus.unfocus();
                  _dragging = true;
                },
                onChanged: (value) => _preview(value.round()),
                onChangeEnd: (value) {
                  _dragging = false;
                  _apply(value.round());
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('%$_minimum', style: theme.textTheme.bodySmall),
                Text('%$_maximum', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: 180,
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape): () {
                    _focus.unfocus();
                    _preview(_savedPercent);
                  },
                },
                child: TextField(
                  key: const Key('interface-scale-percent'),
                  controller: _text,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Tam yüzde',
                    suffixText: '%',
                    helperText: 'Yazıp Enter’a bas · %1 adım',
                    suffixIcon: IconButton(
                      key: const Key('interface-scale-apply'),
                      tooltip: 'Yüzdeyi uygula',
                      onPressed: _applyText,
                      icon: const Icon(Icons.check, size: 20),
                    ),
                    errorText: _error,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (text) {
                    final value = _parse(text);
                    setState(() {
                      _error = value == null
                          ? '80–200 arasında tam sayı gir.'
                          : null;
                      if (value != null) _percent = value;
                    });
                  },
                  onEditingComplete: _applyText,
                  onTapOutside: (_) => _focus.unfocus(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              key: const Key('interface-scale-preview'),
              height: 76,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 24 * _percent / 100,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Aa · Görevlerim',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 16 * _percent / 100,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yazı, simge ve düğmeler birlikte ölçeklenir. '
              'Dar ekranlarda büyütme ekrana göre sınırlandırılır.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              key: const Key('scale-reset'),
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Varsayılan boyuta dön (%100)'),
            ),
          ],
        ),
      ),
    );
  }
}
