import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/life.dart';
import 'game_widgets.dart';
import 'life_widgets.dart';
import 'companion_stage.dart';
import '../l10n/strings.dart';
import 'task_actions.dart';
import 'today_task_card.dart';

class AdventurePage extends StatelessWidget {
  const AdventurePage({super.key, required this.controller, required this.go});
  final TaskController controller;
  final void Function(String) go;
  @override
  Widget build(BuildContext context) {
    final life = controller.data.life;
    final s = context.s;
    final profile = controller.profile;
    final tasks = controller.data.tasksOn(controller.today);
    final done = tasks
        .where((t) => controller.data.isDone(t.id, controller.today))
        .length;
    final health = life.health[controller.today.toIso()];
    final firstName = life.name.trim().split(' ').first;
    final game = controller.settings.gameMode;
    return LifePage(
      children: [
        PageHeading(
          s('newBeginning'),
          firstName.isEmpty
              ? s(game ? 'heroTitle' : 'yourDayTitle')
              : '${s('welcome')}, $firstName.',
          s(game ? 'heroSubtitle' : 'simpleDaySubtitle'),
          action: FilledButton.icon(
            onPressed: () =>
                addTaskWithEditor(context, controller, start: controller.today),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(s('newTask')),
          ),
        ),
        LayoutBuilder(
          builder: (context, c) {
            final main = TodayTaskCard(
              controller: controller,
              openDay: () => go('gun'),
            );
            final side = Column(
              children: [
                if (game)
                  LifeCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                '${s('level')} ${profile.level}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        XpBar(profile: profile, height: 8),
                        const SizedBox(height: 8),
                        Text(
                          '${profile.xpIntoLevel} / ${profile.xpForNext} XP',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s('realProgressHelp'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                LifeCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite_border_rounded,
                            color: Color(0xFFBD8065),
                            size: 20,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              s('careQuestion'),
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${s('water')}  ${health?.water ?? '—'} ${s('glassUnit')} · ${s('sleep')}  ${health?.sleep ?? '—'} ${s('hourUnit')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => go('saglik'),
                        child: Text(s('openHealthLog')),
                      ),
                    ],
                  ),
                ),
              ],
            );
            return c.maxWidth < 800
                ? Column(children: [main, const SizedBox(height: 16), side])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: main),
                      const SizedBox(width: 20),
                      Expanded(flex: 4, child: side),
                    ],
                  );
          },
        ),
        const SizedBox(height: 24),
        if (game)
          LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 650;
              final message = Padding(
                padding: EdgeInsets.fromLTRB(narrow ? 22 : 32, 28, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.eco_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 7),
                        Text(
                          s('firstPage'),
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s('heroInvestment'),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(height: 1.35, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s('heroDescription'),
                      style: TextStyle(height: 1.7, fontSize: 13),
                    ),
                    const SizedBox(height: 19),
                    OutlinedButton.icon(
                      onPressed: () => go('karakter'),
                      icon: const Icon(Icons.person_outline_rounded, size: 17),
                      label: Text(
                        life.name.isEmpty
                            ? s('createCharacter')
                            : s('myCharacter'),
                      ),
                    ),
                  ],
                ),
              );
              final art = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CompanionScene(
                    color: life.companion,
                    height: narrow ? 205 : 265,
                  ),
                  Text(
                    s(companionId(life.companion)),
                    key: const Key('hero-companion-name'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                    child: OutlinedButton.icon(
                      key: const Key('hero-change-companion'),
                      onPressed: () => go('companions'),
                      icon: const Icon(Icons.pets_outlined, size: 17),
                      label: Text(s('changeCompanion')),
                    ),
                  ),
                ],
              );
              return Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: narrow
                    ? Column(children: [message, art])
                    : Row(
                        children: [
                          Expanded(flex: 6, child: message),
                          Expanded(flex: 5, child: art),
                        ],
                      ),
              );
            },
          ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, c) {
            final cols = c.maxWidth > 850 ? 4 : 2;
            final width = (c.maxWidth - (cols - 1) * 14) / cols;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: width,
                  child: MiniMetric(
                    icon: Icons.check_circle_outline_rounded,
                    label: s('todaySteps'),
                    value: '$done / ${tasks.length}',
                    detail: tasks.isEmpty
                        ? s('firstTask')
                        : s('completedTasks'),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: MiniMetric(
                    icon: game
                        ? Icons.auto_awesome_outlined
                        : Icons.event_available_outlined,
                    label: s(game ? 'experiencePoints' : 'totalCompletions'),
                    value: game
                        ? '${profile.totalXp} XP'
                        : '${profile.totalDone}',
                    detail: game
                        ? '${s('today')} +${profile.xpToday} XP'
                        : s('completedTaskDays'),
                    color: const Color(0xFFB48E4A),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: MiniMetric(
                    icon: Icons.local_fire_department_outlined,
                    label: s('longestStreak'),
                    value: '${profile.endurance} ${s('dayUnit')}',
                    detail: s('smallStepsAddUp'),
                    color: const Color(0xFFBD8065),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: MiniMetric(
                    icon: Icons.timelapse_rounded,
                    label: s('focusTime'),
                    value:
                        '${life.sessions.where((s) => s.at.toLocal().year == controller.today.year && s.at.toLocal().month == controller.today.month && s.at.toLocal().day == controller.today.day).fold(0, (sum, s) => sum + s.minutes)} ${s('minuteUnit')}',
                    detail: s('confirmedSessionsToday'),
                    color: const Color(0xFF8A79B1),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(
              child: Text(
                s('skill_tree'),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () => go('skill_tree'),
              child: Text(s('explore')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth > 800
                ? 5
                : c.maxWidth > 430
                ? 3
                : 2;
            final width = (c.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final area in LifeArea.values)
                  SizedBox(
                    width: width,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => go('skill_tree'),
                      child: LifeCard(
                        padding: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              areaIcon(area),
                              color: areaColor(area),
                              size: 25,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              s('area.${area.name}'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${controller.data.life.links.entries.where((e) => e.value.area == area).fold(0, (sum, e) => sum + (controller.data.completions[e.key]?.length ?? 0))} ${s('stepUnit')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        Center(
          child: Text(
            s('personalProgressMotto'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
