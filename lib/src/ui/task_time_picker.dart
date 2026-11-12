import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/task.dart';
import '../l10n/strings.dart';

Future<ClockTime?> pickTaskTime(BuildContext context, {ClockTime? initial}) {
  // Material's input picker has fixed heights that overflow with large text.
  // Keep the requested text size and use a scrollable form instead.
  if (MediaQuery.textScalerOf(context).scale(14) > 18) {
    return showDialog<ClockTime>(
      context: context,
      builder: (_) => _LargeTextTimePicker(initial: initial ?? ClockTime(9, 0)),
    );
  }
  return _materialTime(
    context,
    initial: initial,
    mode: TimePickerEntryMode.input,
  );
}

Future<ClockTime?> _materialTime(
  BuildContext context, {
  ClockTime? initial,
  required TimePickerEntryMode mode,
}) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(
      hour: initial?.hour ?? 9,
      minute: initial?.minute ?? 0,
    ),
    initialEntryMode: mode,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
    cancelText: context.s('cancel'),
    confirmText: context.s('select'),
    hourLabelText: context.s('hour'),
    minuteLabelText: context.s('minute'),
    helpText: context.s('taskTimeHelp'),
    errorInvalidText: context.s('invalidTime'),
  );
  return picked == null ? null : ClockTime(picked.hour, picked.minute);
}

class _LargeTextTimePicker extends StatefulWidget {
  const _LargeTextTimePicker({required this.initial});
  final ClockTime initial;

  @override
  State<_LargeTextTimePicker> createState() => _LargeTextTimePickerState();
}

class _LargeTextTimePickerState extends State<_LargeTextTimePicker> {
  final _form = GlobalKey<FormState>();
  final _hourAnchor = GlobalKey<FormFieldState<String>>();
  final _minuteAnchor = GlobalKey<FormFieldState<String>>();
  final _hourFocus = FocusNode();
  final _minuteFocus = FocusNode();
  late final _hour = TextEditingController(
    text: widget.initial.hour.toString().padLeft(2, '0'),
  );
  late final _minute = TextEditingController(
    text: widget.initial.minute.toString().padLeft(2, '0'),
  );

  @override
  void dispose() {
    _hour.dispose();
    _minute.dispose();
    _hourFocus.dispose();
    _minuteFocus.dispose();
    super.dispose();
  }

  int? _number(String? text, int max) {
    final n = int.tryParse(text?.trim() ?? '');
    return n != null && n >= 0 && n <= max ? n : null;
  }

  void _submit() {
    if (!_form.currentState!.validate()) {
      final hourInvalid = _number(_hour.text, 23) == null;
      (hourInvalid ? _hourFocus : _minuteFocus).requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final anchor = hourInvalid ? _hourAnchor : _minuteAnchor;
        if (anchor.currentContext == null) return;
        Scrollable.ensureVisible(anchor.currentContext!, alignment: .15);
      });
      return;
    }
    Navigator.pop(
      context,
      ClockTime(int.parse(_hour.text), int.parse(_minute.text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      key: const Key('task-time-dialog'),
      scrollable: true,
      title: Text(s('taskTimeHelp')),
      content: SizedBox(
        width: 320,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: _hourAnchor,
                controller: _hour,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                focusNode: _hourFocus,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: InputDecoration(
                  labelText: s('hour'),
                  helperText: '00–23',
                  errorMaxLines: 5,
                ),
                validator: (v) =>
                    _number(v, 23) == null ? s('editorHourError') : null,
                onFieldSubmitted: (_) => _minuteFocus.requestFocus(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: _minuteAnchor,
                controller: _minute,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                focusNode: _minuteFocus,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: InputDecoration(
                  labelText: s('minute'),
                  helperText: '00–59',
                  errorMaxLines: 5,
                ),
                validator: (v) =>
                    _number(v, 59) == null ? s('editorMinuteError') : null,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: s('editorClockFace'),
          icon: const Icon(Icons.schedule),
          onPressed: () async {
            final initial = ClockTime(
              _number(_hour.text, 23) ?? widget.initial.hour,
              _number(_minute.text, 59) ?? widget.initial.minute,
            );
            final picked = await _materialTime(
              context,
              initial: initial,
              mode: TimePickerEntryMode.dialOnly,
            );
            if (picked != null && context.mounted) {
              Navigator.pop(context, picked);
            }
          },
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s('cancel')),
        ),
        FilledButton(onPressed: _submit, child: Text(s('select'))),
      ],
    );
  }
}
