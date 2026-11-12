import 'package:flutter/material.dart';

import '../domain/local_date.dart';
import '../domain/repeat_rule.dart';
import '../domain/task.dart';
import '../l10n/strings.dart';
import 'task_xp_control.dart';
import 'duration_input.dart';
import 'task_time_picker.dart';
import 'form_dialog.dart';

export 'task_time_picker.dart' show pickTaskTime;

/// What the editor returns.
class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.note,
    required this.rule,
    required this.start,
    this.difficulty = Difficulty.orta,
    this.baseXp = 20,
    this.durationMinutes,
    this.time,
    this.steps = const [],
  });

  final String title;
  final String note;
  final RepeatRule rule;
  final Difficulty difficulty;
  final int baseXp;
  final int? durationMinutes;
  final ClockTime? time;

  /// Step titles in order (empty lines dropped).
  final List<String> steps;

  /// First day (new tasks only; a one-off starts on its own date).
  final LocalDate start;
}

enum _Kind { daily, weekly, once }

Future<LocalDate?> pickDate(
  BuildContext context, {
  required LocalDate initial,
  String? help,
  DateTime? earliest,
  DateTime? latest,
}) async {
  if (MediaQuery.sizeOf(context).width < 360 ||
      MediaQuery.sizeOf(context).height < 400) {
    final form = GlobalKey<FormState>();
    DateTime? selected;
    return showDialog<LocalDate>(
      context: context,
      builder: (dialogContext) => FormDialog(
        key: const Key('task-date-dialog'),
        width: 320,
        title: help ?? MaterialLocalizations.of(context).datePickerHelpText,
        content: Form(
          key: form,
          child: InputDatePickerFormField(
            initialDate: DateTime(initial.year, initial.month, initial.day),
            firstDate: earliest ?? DateTime(2000),
            lastDate: latest ?? DateTime(2100, 12, 31),
            autofocus: true,
            onDateSaved: (date) => selected = date,
            onDateSubmitted: (date) => Navigator.pop(
              dialogContext,
              LocalDate(date.year, date.month, date.day),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.s('editorCancel')),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                form.currentState!.save();
                final date = selected!;
                Navigator.pop(
                  dialogContext,
                  LocalDate(date.year, date.month, date.day),
                );
              }
            },
            child: Text(context.s('select')),
          ),
        ],
      ),
    );
  }
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime(initial.year, initial.month, initial.day),
    firstDate: earliest ?? DateTime(2000),
    lastDate: latest ?? DateTime(2100, 12, 31),
    helpText: help,
    cancelText: context.s('editorCancel'),
    confirmText: context.s('select'),
  );
  if (picked == null) return null;
  return LocalDate(picked.year, picked.month, picked.day);
}

/// Opens the add/edit dialog. [existing] null means a new task.
Future<TaskDraft?> showTaskEditor(
  BuildContext context, {
  Task? existing,
  required LocalDate defaultStart,
  required LocalDate today,
  String initialTitle = '',
  RepeatRule? initialRule,
  ClockTime? initialTime,
  LocalDate? effectiveFrom,
  String? heading,
}) => showDialog<TaskDraft>(
  context: context,
  builder: (_) => _TaskEditor(
    existing: existing,
    defaultStart: defaultStart,
    today: today,
    initialTitle: initialTitle,
    initialRule: initialRule,
    initialTime: initialTime,
    effectiveFrom: effectiveFrom,
    heading: heading,
  ),
);

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({
    required this.existing,
    required this.defaultStart,
    required this.today,
    required this.initialTitle,
    required this.initialRule,
    this.initialTime,
    required this.effectiveFrom,
    required this.heading,
  });

  final Task? existing;
  final LocalDate defaultStart;
  final LocalDate today;
  final String initialTitle;
  final RepeatRule? initialRule;
  final ClockTime? initialTime;
  final LocalDate? effectiveFrom;
  final String? heading;

  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late _Kind _kind;
  late Set<int> _weekdays;
  late LocalDate _onceDate;
  late LocalDate _start;
  late int _baseXp;
  int? _durationMinutes;
  final _durationKey = GlobalKey<FormState>();
  ClockTime? _time;
  late final TextEditingController _steps;
  String? _error;
  final _titleFocus = FocusNode();
  final _weekdaysFocus = FocusNode();
  final _durationFocus = FocusNode();
  final _titleAnchor = GlobalKey<FormFieldState<String>>();
  final _weekdaysAnchor = GlobalKey();

  void _reveal(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || key.currentContext == null) return;
      Scrollable.ensureVisible(
        key.currentContext!,
        alignment: .25,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
      );
    });
  }

  String _dateLabel(LocalDate date) =>
      MaterialLocalizations.of(context)
          .formatFullDate(DateTime(date.year, date.month, date.day));

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _title = TextEditingController(text: t?.title ?? widget.initialTitle);
    _note = TextEditingController(text: t?.note ?? '');
    _baseXp = t?.baseXp ?? Difficulty.orta.baseXp;
    _durationMinutes = t?.durationMinutes;
    _time = t?.time ?? widget.initialTime;
    _steps = TextEditingController(
      text: t?.steps.map((s) => s.title).join('\n') ?? '',
    );
    final rule =
        widget.initialRule ??
        (t == null
            ? const DailyRule()
            : (t.ruleOn(widget.today) ?? t.lastRule)) ??
        const DailyRule();
    _start = widget.defaultStart;
    _weekdays = {1, 2, 3, 4, 5};
    _onceDate = widget.defaultStart;
    switch (rule) {
      case DailyRule():
        _kind = _Kind.daily;
      case WeeklyRule(:final weekdays):
        _kind = _Kind.weekly;
        _weekdays = {...weekdays};
      case OnceRule(:final date):
        _kind = _Kind.once;
        _onceDate = date;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _steps.dispose();
    _titleFocus.dispose();
    _weekdaysFocus.dispose();
    _durationFocus.dispose();
    super.dispose();
  }

  RepeatRule? _rule() => switch (_kind) {
    _Kind.daily => const DailyRule(),
    _Kind.weekly => _weekdays.isEmpty ? null : WeeklyRule(_weekdays),
    _Kind.once => OnceRule(_onceDate),
  };

  void _submit() {
    final title = _title.text.trim();
    if (!(_titleAnchor.currentState?.validate() ?? false)) {
      _titleFocus.requestFocus();
      _reveal(_titleAnchor);
      return;
    }
    final rule = _rule();
    if (rule == null) {
      setState(() => _error = 'chooseDay');
      _weekdaysFocus.requestFocus();
      _reveal(_weekdaysAnchor);
      return;
    }
    if (!(_durationKey.currentState?.validate() ?? true)) {
      _durationFocus.requestFocus();
      _reveal(_durationKey);
      return;
    }
    Navigator.of(context).pop(
      TaskDraft(
        title: title,
        note: _note.text.trim(),
        rule: rule,
        start: _start,
        difficulty: _baseXp <= 10
            ? Difficulty.kolay
            : _baseXp < 35
            ? Difficulty.orta
            : Difficulty.zor,
        baseXp: _baseXp,
        durationMinutes: _time == null ? null : _durationMinutes,
        time: _time,
        steps: [
          for (final l in _steps.text.split('\n'))
            if (l.trim().isNotEmpty) l.trim(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = context.s;
    return FormDialog(
      title: widget.heading ?? s(_isNew ? 'newTask' : 'editorEdit'),
      content: SizedBox(
        width: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            KeyedSubtree(
              key: const Key('editor-title'),
              child: TextFormField(
                key: _titleAnchor,
                controller: _title,
                focusNode: _titleFocus,
                autofocus: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) => value == null || value.trim().isEmpty
                    ? s('editorTitleRequired')
                    : null,
                decoration: InputDecoration(
                  labelText: s('editorTaskName'),
                  hintText: s('editorTaskHint'),
                  hintMaxLines: 2,
                  errorMaxLines: 3,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('editor-note'),
              controller: _note,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: s('editorNote'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TaskXpControl(
              value: _baseXp,
              onChanged: (value) => setState(() => _baseXp = value),
            ),
            const SizedBox(height: 16),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(s('editorTaskTime')),
                ),
                OutlinedButton.icon(
                  key: const Key('editor-time'),
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(_time?.format() ?? s('editorAddTime')),
                  onPressed: () async {
                    final picked = await pickTaskTime(context, initial: _time);
                    if (picked != null) {
                      setState(() => _time = picked);
                    }
                  },
                ),
                if (_time != null)
                  IconButton(
                    key: const Key('editor-time-clear'),
                    tooltip: s('removeTime'),
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _time = null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_time != null) ...[
              Form(
                key: _durationKey,
                child: DurationInput(
                  initial: _durationMinutes,
                  label: s('editorDuration'),
                  focusNode: _durationFocus,
                  onChanged: (v) => _durationMinutes = v,
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              key: const Key('editor-steps'),
              controller: _steps,
              minLines: 1,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: s('editorSteps'),
                helperText: s('editorStepsHelp'),
                helperMaxLines: 3,
                hintText: s('editorStepsHint'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text(s('editorWhen'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              key: const Key('editor-kind'),
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final kind in _Kind.values)
                  ChoiceChip(
                    label: Text(
                      s(switch (kind) {
                        _Kind.daily => 'editorDaily',
                        _Kind.weekly => 'editorWeekly',
                        _Kind.once => 'editorOnce',
                      }),
                    ),
                    selected: _kind == kind,
                    onSelected: (_) => setState(() {
                      _kind = kind;
                      _error = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_kind == _Kind.weekly)
              KeyedSubtree(key: _weekdaysAnchor, child: _weekdayPicker(theme)),
            if (_kind == _Kind.once)
              _dateRow(
                key: const Key('editor-once-date'),
                label: s('editorDate'),
                date: _onceDate,
                onPick: (d) => setState(() => _onceDate = d),
              ),
            if (_isNew && _kind != _Kind.once)
              _dateRow(
                key: const Key('editor-start-date'),
                label: s('editorStart'),
                date: _start,
                onPick: (d) => setState(() => _start = d),
              ),
            if (!_isNew && widget.effectiveFrom != null && _kind != _Kind.once)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  s('editorEffectiveHelp')
                      .replaceAll('{date}', _dateLabel(widget.effectiveFrom!)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s('editorCancel')),
        ),
        FilledButton(
          key: const Key('editor-save'),
          onPressed: _submit,
          child: Text(s(_isNew ? 'editorAdd' : 'save')),
        ),
      ],
    );
  }

  Widget _weekdayPicker(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var d = 1; d <= 7; d++)
            FilterChip(
              key: Key('editor-weekday-$d'),
              label: Text(context.s.weekday(d)),
              tooltip: context.s('weekdayFull.$d'),
              focusNode: d == 1 ? _weekdaysFocus : null,
              selected: _weekdays.contains(d),
              onSelected: (on) => setState(() {
                on ? _weekdays.add(d) : _weekdays.remove(d);
                _error = null;
              }),
            ),
        ],
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 4,
        children: [
          TextButton(
            onPressed: () => setState(() {
              _weekdays = {1, 2, 3, 4, 5};
              _error = null;
            }),
            child: Text(context.s('editorWeekdays')),
          ),
          TextButton(
            onPressed: () => setState(() {
              _weekdays = {6, 7};
              _error = null;
            }),
            child: Text(context.s('editorWeekend')),
          ),
        ],
      ),
      if (_error == 'chooseDay')
        Semantics(
          liveRegion: true,
          child: Text(
            context.s(_error!),
            key: const Key('editor-error'),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      const SizedBox(height: 4),
    ],
  );

  Widget _dateRow({
    required Key key,
    required String label,
    required LocalDate date,
    required ValueChanged<LocalDate> onPick,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          key: key,
          icon: const Icon(Icons.calendar_today_rounded, size: 18),
          label: Text(_dateLabel(date)),
          onPressed: () async {
            final picked = await pickDate(context, initial: date, help: label);
            if (picked != null) onPick(picked);
          },
        ),
      ],
    ),
  );
}
