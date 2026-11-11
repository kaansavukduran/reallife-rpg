import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/fitness.dart';
import '../l10n/strings.dart';
import 'companion_stage.dart';
import 'life_widgets.dart';

const _previews = <(String, Motion, Equipment, String)>[
  ('idle', Motion.idle, Equipment.bodyweight, 'motion.idle'),
  ('reverseFly', Motion.reverseFly, Equipment.machine, 'motion.reverseFly'),
  ('chest_press', Motion.press, Equipment.machine, 'chestPressMachine'),
  ('bench_press', Motion.press, Equipment.barbell, 'benchPressBarbell'),
  ('incline_press', Motion.press, Equipment.dumbbell, 'inclinePressDumbbell'),
  ('pec_deck', Motion.fly, Equipment.machine, 'pecDeck'),
  ('cable_fly', Motion.fly, Equipment.cable, 'cableFly'),
  (
    'reverse_dumbbell_fly',
    Motion.reverseFly,
    Equipment.dumbbell,
    'reverseDumbbellFly',
  ),
  ('face_pull', Motion.reverseFly, Equipment.cable, 'facePull'),
  ('shoulder_press', Motion.overhead, Equipment.machine, 'shoulderPress'),
  ('overhead_barbell', Motion.overhead, Equipment.barbell, 'barbellOverhead'),
  ('lateral_machine', Motion.lateralRaise, Equipment.machine, 'lateralMachine'),
  ('lateral_cable', Motion.lateralRaise, Equipment.cable, 'lateralCable'),
  ('front_raise', Motion.frontRaise, Equipment.dumbbell, 'frontRaise'),
  ('lat_pulldown', Motion.pulldown, Equipment.machine, 'latPulldown'),
  ('pull_up', Motion.pulldown, Equipment.bodyweight, 'pullUp'),
  ('assisted_pull_up', Motion.pulldown, Equipment.machine, 'assistedPullUp'),
  ('cable_row', Motion.row, Equipment.cable, 'cableRow'),
  ('machine_row', Motion.row, Equipment.machine, 'machineRow'),
  ('one_arm_row', Motion.row, Equipment.dumbbell, 'oneArmRow'),
  (
    'lateral_dumbbell',
    Motion.lateralRaise,
    Equipment.dumbbell,
    'lateralDumbbell',
  ),
  (
    'shoulder_dumbbell',
    Motion.overhead,
    Equipment.dumbbell,
    'shoulderDumbbell',
  ),
  ('push_up', Motion.press, Equipment.bodyweight, 'pushUp'),
  ('curl', Motion.curl, Equipment.dumbbell, 'motion.curl'),
  ('eat', Motion.eat, Equipment.bodyweight, 'motion.eat'),
  ('read', Motion.read, Equipment.bodyweight, 'motion.read'),
];

class CompanionsPage extends StatefulWidget {
  const CompanionsPage({super.key, required this.controller});
  final TaskController controller;
  @override
  State<CompanionsPage> createState() => _CompanionsPageState();
}

class _CompanionsPageState extends State<CompanionsPage> {
  String _preview = 'idle';
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final life = widget.controller.data.life;
    final selected = _previews.firstWhere((p) => p.$1 == _preview);
    return LifePage(
      children: [
        PageHeading('RealLife RPG', s('companions'), s('companionIntro')),
        LifeCard(
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final p in _previews)
                    ChoiceChip(
                      key: ValueKey('preview-${p.$1}'),
                      label: Text(s(p.$4)),
                      selected: _preview == p.$1,
                      onSelected: (_) => setState(() => _preview = p.$1),
                    ),
                ],
              ),
              CompanionStage(
                key: ValueKey('${life.companion}-$_preview'),
                character: life.companion,
                motion: selected.$2,
                exerciseId: selected.$1,
                equipment: selected.$3,
                controls: true,
                autoplay: selected.$2 != Motion.idle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (c, b) => Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final id in companionIds)
                SizedBox(
                  width: b.maxWidth >= 660 ? (b.maxWidth - 16) / 2 : b.maxWidth,
                  child: LifeCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CompanionStage(character: id, height: 220),
                        Text(
                          s(id),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(s('${id}Desc')),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          key: Key('choose-$id'),
                          onPressed: () => widget.controller.updateLife(
                            widget.controller.data.life.copyWith(companion: id),
                          ),
                          icon: Icon(
                            companionId(life.companion) == id
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                          ),
                          label: Text(
                            s(
                              companionId(life.companion) == id
                                  ? 'selected'
                                  : 'select',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
