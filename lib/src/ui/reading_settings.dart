import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../l10n/strings.dart';

class ReadingSettings extends StatelessWidget {
  const ReadingSettings({super.key, required this.controller});
  final TaskController controller;
  @override
  Widget build(BuildContext context) {
    final s = context.s,
        settings = controller.settings,
        a = settings.appearance;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s('accessibility'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(s('deviceOnly')),
            DropdownButtonFormField<String>(
              key: const Key('display-mode'),
              initialValue: settings.displayMode,
              isExpanded: true,
              decoration: InputDecoration(labelText: s('appearance')),
              items: [
                for (final id in [
                  'preset',
                  'system',
                  'light',
                  'dark',
                  'contrast',
                ])
                  DropdownMenuItem(value: id, child: Text(s('mode.$id'))),
              ],
              onChanged: (v) =>
                  controller.updateSettings(settings.copyWith(displayMode: v)),
            ),
            const SizedBox(height: 16),
            Text('${s('textSize')}: ${(settings.textScale * 100).round()}%'),
            Slider(
              key: const Key('text-scale-slider'),
              min: .8,
              max: 2,
              divisions: 24,
              value: settings.textScale,
              label: '${(settings.textScale * 100).round()}%',
              onChanged: (v) =>
                  controller.updateSettings(settings.copyWith(textScale: v)),
            ),
            TextButton(
              onPressed: () =>
                  controller.updateSettings(settings.copyWith(textScale: 1)),
              child: Text(s('textReset')),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('reader-font'),
              initialValue: a.font,
              isExpanded: true,
              decoration: InputDecoration(labelText: s('font')),
              items: [
                for (final id in ['system', 'serif', 'mono', 'dyslexic'])
                  DropdownMenuItem(value: id, child: Text(s('font.$id'))),
              ],
              onChanged: (v) => controller.updateSettings(
                settings.copyWith(appearance: a.copyWith(font: v)),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s('reduceMotion')),
              value: a.reduceMotion,
              onChanged: (v) => controller.updateSettings(
                settings.copyWith(appearance: a.copyWith(reduceMotion: v)),
              ),
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(s('readingDetails')),
              children: [
                Text('${s('lineHeight')}: ${a.lineHeight.toStringAsFixed(1)}×'),
                Slider(
                  min: 1,
                  max: 1.6,
                  divisions: 6,
                  value: a.lineHeight,
                  onChanged: (v) => controller.updateSettings(
                    settings.copyWith(appearance: a.copyWith(lineHeight: v)),
                  ),
                ),
                Text(
                  '${s('letterSpacing')}: ${a.letterSpacing.toStringAsFixed(1)}',
                ),
                Slider(
                  min: 0,
                  max: 3,
                  divisions: 12,
                  value: a.letterSpacing,
                  onChanged: (v) => controller.updateSettings(
                    settings.copyWith(appearance: a.copyWith(letterSpacing: v)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
