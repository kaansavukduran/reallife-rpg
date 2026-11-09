import 'package:flutter/material.dart';

import '../domain/local_date.dart';
import '../l10n/strings.dart';

/// Keep externally owned form controllers alive until the dialog has finished
/// its exit transition, including when validation just rebuilt the fields.
Future<T?> showEditor<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  final route = DialogRoute<T>(context: context, builder: builder);
  final result = await Navigator.of(context, rootNavigator: true).push(route);
  await route.completed;
  return result;
}

double? parseDecimal(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));
String compactNumber(num? value) => value == null
    ? '—'
    : value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
String displayNumber(BuildContext c, num? value) => c.s.english
    ? compactNumber(value)
    : compactNumber(value).replaceAll('.', ',');
Widget numberField(
  BuildContext context,
  TextEditingController controller,
  String label, {
  double min = 0,
  double max = 1000000,
  bool required = false,
  bool integer = false,
  Key? key,
  String? help,
}) => TextFormField(
  key: key,
  controller: controller,
  keyboardType: TextInputType.numberWithOptions(decimal: !integer),
  decoration: InputDecoration(
    labelText: label,
    helperText: help ?? '$min–$max',
    helperMaxLines: 4,
  ),
  validator: (v) {
    if ((v ?? '').trim().isEmpty) {
      return required ? context.s('required') : null;
    }
    final n = parseDecimal(v!);
    return n == null ||
            !n.isFinite ||
            n < min ||
            n > max ||
            (integer && n != n.roundToDouble())
        ? context.s('invalid')
        : null;
  },
);
Widget textField(
  BuildContext context,
  TextEditingController controller,
  String label, {
  bool required = true,
  int lines = 1,
  Key? key,
}) => TextFormField(
  key: key,
  controller: controller,
  maxLength: lines == 1 ? 200 : 2000,
  maxLines: lines,
  decoration: InputDecoration(labelText: label),
  validator: (v) =>
      required && (v ?? '').trim().isEmpty ? context.s('required') : null,
);

class WellnessDateBar extends StatelessWidget {
  const WellnessDateBar({
    super.key,
    required this.date,
    required this.today,
    required this.onChanged,
  });
  final LocalDate date, today;
  final ValueChanged<LocalDate> onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      IconButton(
        tooltip: context.s('previous'),
        onPressed: () => onChanged(date.addDays(-1)),
        icon: const Icon(Icons.chevron_left),
      ),
      TextButton.icon(
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(date.year, date.month, date.day),
            firstDate: DateTime(1900),
            lastDate: DateTime(2200),
          );
          if (picked != null) {
            onChanged(LocalDate(picked.year, picked.month, picked.day));
          }
        },
        icon: const Icon(Icons.calendar_month_outlined),
        label: Text(
          MaterialLocalizations.of(context)
              .formatMediumDate(DateTime(date.year, date.month, date.day)),
        ),
      ),
      IconButton(
        tooltip: context.s('next'),
        onPressed: () => onChanged(date.addDays(1)),
        icon: const Icon(Icons.chevron_right),
      ),
      TextButton(
        onPressed: () => onChanged(today),
        child: Text(context.s('today')),
      ),
    ],
  );
}

Future<bool> confirmRemoval(BuildContext context, String name) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.s('delete')),
        content: Text(name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(c.s('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(c.s('delete')),
          ),
        ],
      ),
    ) ??
    false;
void showSaved(BuildContext c) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(c.s('saved'))));

class EditorDialog extends StatelessWidget {
  const EditorDialog({
    super.key,
    required this.title,
    required this.formKey,
    required this.children,
    required this.onSave,
  });
  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    scrollable: true,
    content: SizedBox(
      width: 620,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final w in children)
              Padding(padding: const EdgeInsets.only(bottom: 16), child: w),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.s('cancel')),
      ),
      FilledButton(
        key: const Key('editor-save'),
        onPressed: () {
          if (formKey.currentState!.validate()) onSave();
        },
        child: Text(context.s('save')),
      ),
    ],
  );
}
