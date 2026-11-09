import 'package:flutter/material.dart';

import '../l10n/strings.dart';

class DurationInput extends StatefulWidget {
  const DurationInput({super.key, this.initial, required this.onChanged});
  final int? initial;
  final ValueChanged<int?> onChanged;
  @override
  State<DurationInput> createState() => _DurationInputState();
}

class _DurationInputState extends State<DurationInput> {
  late final TextEditingController text;
  late String previous;
  @override
  void initState() {
    super.initState();
    previous = widget.initial?.toString() ?? '';
    text = TextEditingController(text: previous)..addListener(changed);
  }

  void changed() {
    if (text.text == previous) return;
    previous = text.text;
    final value = int.tryParse(text.text.trim());
    if (text.text.trim().isEmpty ||
        (value != null && value >= 1 && value <= 1440)) {
      widget.onChanged(value);
    }
    setState(() {});
  }

  @override
  void dispose() {
    text.removeListener(changed);
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = int.tryParse(text.text.trim());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: const Key('planned-duration'),
          controller: text,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.s('plannedDuration'),
            helperText: context.s('durationHelp'),
            helperMaxLines: 4,
          ),
          validator: (v) {
            if (v!.trim().isEmpty) return null;
            final n = int.tryParse(v.trim());
            return n == null || n < 1 || n > 1440
                ? context.s('invalidDuration')
                : null;
          },
        ),
        Slider(
          key: const Key('planned-duration-slider'),
          min: 1,
          max: 180,
          divisions: 179,
          value: (value ?? 30).clamp(1, 180).toDouble(),
          label: '${value ?? 30} ${context.s('minute')}',
          onChanged: (v) => text.text = v.round().toString(),
        ),
      ],
    );
  }
}
