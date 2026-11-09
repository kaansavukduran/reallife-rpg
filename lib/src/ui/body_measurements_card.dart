import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/body_measurements.dart';
import '../l10n/strings.dart';
import 'companion_stage.dart';
import 'life_widgets.dart';
import 'wellness_widgets.dart';

class BodyMeasurementsCard extends StatelessWidget {
  const BodyMeasurementsCard({super.key, required this.controller});
  final TaskController controller;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final life = controller.data.life;
    final kg = life.fitness.bodyKg, cm = life.measurements.heightCm;
    final bmi = bodyMassIndex(kg, cm);
    final adult = life.measurements.adultReference;
    return LifeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s('bodyMeasurements'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          CompanionStage(character: life.companion, height: 175),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              Text('${s('height')}: ${displayNumber(context, cm)} cm'),
              Text('${s('bodyWeight')}: ${displayNumber(context, kg)} kg'),
            ],
          ),
          const SizedBox(height: 10),
          if (adult && bmi != null) ...[
            Text(
              '${s('bmi')}: ${displayNumber(context, bmi)} kg/m²',
              key: const Key('bmi-value'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              s('bmi.${adultBmiRange(bmi).name}'),
              key: const Key('bmi-range'),
            ),
          ] else
            Text(s(adult ? 'bmiMissing' : 'adultBmiHelp')),
          const SizedBox(height: 8),
          Text(s('bmiHelp')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('edit-body-measurements'),
            onPressed: () => _edit(context),
            icon: const Icon(Icons.straighten),
            label: Text(s('editMeasurements')),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final life = controller.data.life;
    final height = TextEditingController(
          text: compactNumber(life.measurements.heightCm).replaceAll('—', ''),
        ),
        kg = TextEditingController(
          text: compactNumber(life.fitness.bodyKg).replaceAll('—', ''),
        );
    var adult = life.measurements.adultReference;
    final key = GlobalKey<FormState>();
    final saved = await showEditor<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, set) => EditorDialog(
          title: context.s('bodyMeasurements'),
          formKey: key,
          children: [
            numberField(
              context,
              height,
              '${context.s('height')} (cm)',
              min: 50,
              max: 250,
              key: const Key('body-height'),
            ),
            numberField(
              context,
              kg,
              context.s('bodyWeight'),
              min: 20,
              max: 500,
              key: const Key('body-weight'),
            ),
            CheckboxListTile(
              key: const Key('adult-reference'),
              contentPadding: EdgeInsets.zero,
              value: adult,
              title: Text(context.s('adultBmi')),
              subtitle: Text(context.s('adultBmiHelp')),
              onChanged: (v) => set(() => adult = v!),
            ),
            Text(context.s('bodyWeightHelp')),
            Text(context.s('bmiHelp')),
          ],
          onSave: () => Navigator.pop(context, true),
        ),
      ),
    );
    if (saved == true) {
      final latest = controller.data.life;
      controller.updateLife(
        latest.copyWith(
          measurements: BodyMeasurements(
            heightCm: parseDecimal(height.text),
            adultReference: adult,
          ),
          fitness: latest.fitness.copyWith(
            bodyKg: parseDecimal(kg.text),
            clearWeight: kg.text.trim().isEmpty,
          ),
        ),
      );
    }
    height.dispose();
    kg.dispose();
  }
}
