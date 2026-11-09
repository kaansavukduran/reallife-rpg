import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/fitness.dart';
import '../l10n/strings.dart';
import 'companion_stage.dart';
import 'life_widgets.dart';

class CompanionsPage extends StatefulWidget {
  const CompanionsPage({super.key, required this.controller});
  final TaskController controller;
  @override
  State<CompanionsPage> createState() => _CompanionsPageState();
}

class _CompanionsPageState extends State<CompanionsPage> {
  Motion _motion = Motion.idle;
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final life = widget.controller.data.life;
    return LifePage(
      children: [
        PageHeading('RealLife RPG', s('companions'), s('companionIntro')),
        LifeCard(
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final m in [
                    Motion.idle,
                    Motion.reverseFly,
                    Motion.curl,
                    Motion.cycle,
                    Motion.eat,
                    Motion.read,
                  ])
                    ChoiceChip(
                      label: Text(s('motion.${m.name}')),
                      selected: _motion == m,
                      onSelected: (_) => setState(() => _motion = m),
                    ),
                ],
              ),
              CompanionStage(
                key: ValueKey('${life.companion}-$_motion'),
                character: life.companion,
                motion: _motion,
                equipment: _motion == Motion.reverseFly
                    ? Equipment.machine
                    : _motion == Motion.curl
                    ? Equipment.dumbbell
                    : Equipment.bodyweight,
                controls: true,
                autoplay: _motion != Motion.idle,
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
