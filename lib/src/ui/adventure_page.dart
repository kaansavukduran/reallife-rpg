import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/life.dart';
import 'game_widgets.dart';
import 'life_widgets.dart';
import 'task_actions.dart';

class AdventurePage extends StatelessWidget {
  const AdventurePage({super.key, required this.controller, required this.go});
  final TaskController controller;
  final void Function(String) go;
  @override
  Widget build(BuildContext context) {
    final life = controller.data.life;
    final profile = controller.profile;
    final tasks = controller.data.tasksOn(controller.today);
    final done = tasks
        .where((t) => controller.data.isDone(t.id, controller.today))
        .length;
    final pending = tasks
        .where((t) => !controller.data.isDone(t.id, controller.today))
        .take(4)
        .toList();
    final health = life.health[controller.today.toIso()];
    final firstName = life.name.trim().split(' ').first;
    final game = controller.settings.gameMode;
    return LifePage(
      children: [
        PageHeading(
          'Her gün yeni bir başlangıç',
          firstName.isEmpty
              ? 'Kendi hikâyenin kahramanı ol.'
              : 'İyi ki geldin, $firstName.',
          'Küçük adımlar. Gerçek gelişim. Sana ait bir macera.',
          action: FilledButton.icon(
            onPressed: () =>
                addTaskWithEditor(context, controller, start: controller.today),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Yeni görev'),
          ),
        ),
        if (game)
          LayoutBuilder(
            builder: (context, c) {
              final narrow = c.maxWidth < 650;
              final message = Padding(
                padding: EdgeInsets.fromLTRB(narrow ? 22 : 32, 28, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.eco_outlined, size: 16, color: sage),
                        SizedBox(width: 7),
                        Text(
                          'MACERANIN İLK SAYFASI',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w800,
                            color: sage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'En iyi yatırımın,\nkendine ayırdığın zaman.',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(height: 1.35, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bir sayfa oku, biraz hareket et, yeni bir şey öğren.\nHer küçük adım karakterinin bir parçası.',
                      style: TextStyle(height: 1.7, fontSize: 13),
                    ),
                    const SizedBox(height: 19),
                    OutlinedButton.icon(
                      onPressed: () => go('karakter'),
                      icon: const Icon(Icons.person_outline_rounded, size: 17),
                      label: Text(
                        life.name.isEmpty
                            ? 'Karakterini oluştur'
                            : 'Karakterime git',
                      ),
                    ),
                  ],
                ),
              );
              final art = CompanionScene(
                color: life.companion,
                height: narrow ? 205 : 265,
              );
              return Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFFEDF1E5)
                      : const Color(0xFF26382D),
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
                    label: 'Bugünün adımları',
                    value: '$done / ${tasks.length}',
                    detail: tasks.isEmpty
                        ? 'İlk görevini ekle'
                        : 'Tamamlanan görev',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: MiniMetric(
                    icon: game
                        ? Icons.auto_awesome_outlined
                        : Icons.event_available_outlined,
                    label: game ? 'Deneyim puanı' : 'Toplam başarı',
                    value: game
                        ? '${profile.totalXp} XP'
                        : '${profile.totalDone}',
                    detail: game
                        ? 'Bugün +${profile.xpToday} XP'
                        : 'Tamamlanan görev günleri',
                    color: const Color(0xFFB48E4A),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: MiniMetric(
                    icon: Icons.local_fire_department_outlined,
                    label: 'En uzun seri',
                    value: '${profile.endurance} gün',
                    detail: 'Küçük adımlar birikir',
                    color: const Color(0xFFBD8065),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: MiniMetric(
                    icon: Icons.timelapse_rounded,
                    label: 'Odak zamanı',
                    value:
                        '${life.sessions.where((s) => s.at.toLocal().year == controller.today.year && s.at.toLocal().month == controller.today.month && s.at.toLocal().day == controller.today.day).fold(0, (sum, s) => sum + s.minutes)} dk',
                    detail: 'Bugün onayladığın seanslar',
                    color: const Color(0xFF8A79B1),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, c) {
            final main = LifeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.wb_sunny_outlined,
                        size: 20,
                        color: sage,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bugünün küçük maceraları',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Günlük listeyi aç',
                        onPressed: () => go('gun'),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      ),
                    ],
                  ),
                  Text(
                    '$done / ${tasks.length} görev tamamlandı',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 15),
                  LinearProgressIndicator(
                    value: tasks.isEmpty ? 0 : done / tasks.length,
                    borderRadius: BorderRadius.circular(8),
                    minHeight: 5,
                  ),
                  const SizedBox(height: 13),
                  if (tasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Büyük bir başlangıç gerekmiyor.\nBugün kendin için tek bir görev seç.',
                        style: TextStyle(height: 1.8),
                      ),
                    ),
                  if (tasks.isNotEmpty && pending.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'Bugünün adımlarını tamamladın. Dinlenmenin tadını çıkar!',
                      ),
                    ),
                  for (final task in pending)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Checkbox(
                            value: false,
                            onChanged: (_) =>
                                controller.toggle(task.id, controller.today),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => editTask(context, controller, task),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (controller
                                                .data
                                                .life
                                                .links[task.id]
                                                ?.area ??
                                            LifeArea.mind)
                                        .label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (game)
                            Text(
                              '+${task.difficulty.baseXp} XP',
                              style: const TextStyle(
                                color: sage,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => go('gun'),
                    child: const Text('Tüm günlük görevleri gör →'),
                  ),
                ],
              ),
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
                            const Icon(
                              Icons.shield_outlined,
                              color: sage,
                              size: 20,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Seviye ${profile.level} · ${profile.title}',
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
                          'Gerçek hayatta attığın her adım burada iz bırakır.',
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
                          const Expanded(
                            child: Text(
                              'Kendine nasıl bakıyorsun?',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Su  ${health?.water ?? 0} bardak     Uyku  ${health?.sleep ?? '—'} saat',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => go('saglik'),
                        child: const Text('Bugünün kaydını ekle →'),
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
        const SizedBox(height: 25),
        Row(
          children: [
            Expanded(
              child: Text(
                'Hayatının yetenek ağacı',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () => go('yetenekler'),
              child: const Text('Keşfet →'),
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
                      onTap: () => go('yetenekler'),
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
                              area.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${controller.data.life.links.entries.where((e) => e.value.area == area).fold(0, (sum, e) => sum + (controller.data.completions[e.key]?.length ?? 0))} adım',
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
            'Bir başkasıyla değil, dünkü kendinle.  ✧',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
