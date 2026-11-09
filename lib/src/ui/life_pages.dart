import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../app/focus_clock.dart';
import '../domain/life.dart';
import '../domain/local_date.dart';
import '../domain/repeat_rule.dart';
import 'life_widgets.dart';
import 'companion_stage.dart';
import '../l10n/strings.dart';
import 'task_editor.dart';

class IdentityCard extends StatelessWidget {
  const IdentityCard({super.key, required this.controller});
  final TaskController controller;
  @override
  Widget build(BuildContext context) {
    final life = controller.data.life;
    return LifeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.s('yourStory'),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 2,
              color: sage,
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      life.name.isEmpty ? context.s('unnamedHero') : life.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      context.s(
                        'profession.${professions.containsKey(life.profession) ? life.profession : 'explorer'}',
                      ),
                    ),
                    if (life.bio.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(life.bio),
                      ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => _editIdentity(context, controller),
                      icon: const Icon(Icons.tune_rounded, size: 17),
                      label: Text(context.s('customizeCharacter')),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: MediaQuery.sizeOf(context).width > 600 ? 190 : 100,
                child: CompanionScene(color: life.companion, height: 155),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _editIdentity(
  BuildContext context,
  TaskController controller,
) async {
  final life = controller.data.life;
  final name = TextEditingController(text: life.name),
      bio = TextEditingController(text: life.bio);
  var profession = professions.containsKey(life.profession)
      ? life.profession
      : 'explorer';
  var companion = companionId(life.companion);
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, set) => AlertDialog(
        title: Text(context.s('createCharacter')),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  maxLength: 60,
                  decoration: InputDecoration(
                    labelText: context.s('characterName'),
                    hintText: context.s('nameHint'),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: profession,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.s('profession'),
                  ),
                  items: professions.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(context.s('profession.${e.key}')),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => set(() => profession = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bio,
                  maxLength: 280,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.s('story'),
                    hintText: context.s('storyHint'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(context.s('companions')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final id in companionIds)
                      ChoiceChip(
                        label: Text(context.s(id)),
                        selected: companion == id,
                        onSelected: (_) => set(() => companion = id),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.s('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.s('save')),
          ),
        ],
      ),
    ),
  );
  if (saved == true) {
    controller.updateLife(
      controller.data.life.copyWith(
        name: name.text.trim(),
        bio: bio.text.trim(),
        profession: profession,
        companion: companion,
      ),
    );
  }
  // Dialog routes finish their reverse animation before controllers are released.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  name.dispose();
  bio.dispose();
}

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key, required this.controller});
  final TaskController controller;
  @override
  Widget build(BuildContext context) {
    final life = controller.data.life;
    return LifePage(
      children: [
        PageHeading(
          'Büyük hedef, küçük adımlar',
          'Hayat projelerin',
          'Bir dil öğren, bir ürün geliştir, ilk maratonuna hazırlan.',
          action: FilledButton.icon(
            onPressed: () => _project(context),
            icon: const Icon(Icons.add),
            label: const Text('Yeni proje'),
          ),
        ),
        if (life.projects.isEmpty)
          const LifeCard(
            child: Text(
              'Henüz bir projen yok. Kendine anlamlı gelen bir hedefle başla.',
            ),
          ),
        for (final project in life.projects)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: LifeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        areaIcon(project.area),
                        color: areaColor(project.area),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          project.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Projeyi düzenle',
                        onPressed: () => _project(context, existing: project),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: project.archived
                            ? 'Arşivden çıkar'
                            : 'Arşivle',
                        onPressed: () => controller.updateLife(
                          life.copyWith(
                            projects: [
                              for (final p in life.projects)
                                p.id == project.id
                                    ? LifeProject(
                                        id: p.id,
                                        title: p.title,
                                        area: p.area,
                                        note: p.note,
                                        archived: !p.archived,
                                      )
                                    : p,
                            ],
                          ),
                        ),
                        icon: Icon(
                          project.archived
                              ? Icons.unarchive_outlined
                              : Icons.archive_outlined,
                        ),
                      ),
                    ],
                  ),
                  if (project.note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(project.note),
                    ),
                  Text(
                    project.archived
                        ? 'Arşivde · geçmiş korunuyor'
                        : project.area.description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  for (final task in controller.data.tasks.where(
                    (t) => life.links[t.id]?.projectId == project.id,
                  ))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(task.title),
                      subtitle: Text(
                        '${controller.data.completions[task.id]?.length ?? 0} tamamlanan gün',
                      ),
                      trailing: IconButton(
                        tooltip: 'Proje bağlantısını kaldır',
                        onPressed: () {
                          final links = {...life.links};
                          final old = links[task.id]!;
                          links[task.id] = TaskLink(
                            area: old.area,
                            skillId: old.skillId,
                          );
                          controller.updateLife(life.copyWith(links: links));
                        },
                        icon: const Icon(Icons.link_off_rounded),
                      ),
                    ),
                  if (!project.archived)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _addTask(context, project),
                          icon: const Icon(Icons.add, size: 17),
                          label: const Text('Proje görevi ekle'),
                        ),
                        TextButton.icon(
                          onPressed: () => _linkTask(context, project),
                          icon: const Icon(Icons.link, size: 17),
                          label: const Text('Mevcut görevi bağla'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _project(BuildContext context, {LifeProject? existing}) async {
    final title = TextEditingController(text: existing?.title),
        note = TextEditingController(text: existing?.note);
    var area = existing?.area ?? LifeArea.craft;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, set) => AlertDialog(
          title: Text(
            existing == null ? 'Yeni hayat projesi' : 'Projeyi düzenle',
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    maxLength: 100,
                    decoration: const InputDecoration(labelText: 'Hedefin'),
                  ),
                  TextField(
                    controller: note,
                    maxLength: 1000,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Neden önemli?',
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<LifeArea>(
                    initialValue: area,
                    decoration: const InputDecoration(labelText: 'Yaşam alanı'),
                    items: LifeArea.values
                        .map(
                          (a) =>
                              DropdownMenuItem(value: a, child: Text(a.label)),
                        )
                        .toList(),
                    onChanged: (v) => set(() => area = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                if (title.text.trim().isNotEmpty) Navigator.pop(context, true);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      final p = LifeProject(
        id: existing?.id ?? controller.newLifeId(),
        title: title.text.trim(),
        note: note.text.trim(),
        area: area,
        archived: existing?.archived ?? false,
      );
      controller.updateLife(
        controller.data.life.copyWith(
          projects: [
            ...controller.data.life.projects.where((e) => e.id != p.id),
            p,
          ],
        ),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    title.dispose();
    note.dispose();
  }

  Future<void> _addTask(BuildContext context, LifeProject project) async {
    final draft = await showTaskEditor(
      context,
      defaultStart: controller.today,
      today: controller.today,
      initialRule: OnceRule(controller.today),
    );
    if (draft == null) return;
    final t = controller.addTask(
      title: draft.title,
      note: draft.note,
      rule: draft.rule,
      start: draft.start,
      difficulty: draft.difficulty,
      time: draft.time,
      steps: draft.steps,
    );
    controller.updateLife(
      controller.data.life.copyWith(
        links: {
          ...controller.data.life.links,
          t.id: TaskLink(area: project.area, projectId: project.id),
        },
      ),
    );
  }

  Future<void> _linkTask(BuildContext context, LifeProject project) async {
    final id = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Bir görev seç'),
        children: [
          if (controller.data.tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Önce günlük listene görev ekle.'),
            ),
          for (final t in controller.data.tasks)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, t.id),
              child: Text(t.title),
            ),
        ],
      ),
    );
    if (id != null) {
      final life = controller.data.life;
      controller.updateLife(
        life.copyWith(
          links: {
            ...life.links,
            id: TaskLink(
              area: project.area,
              projectId: project.id,
              skillId: life.links[id]?.skillId ?? '',
            ),
          },
        ),
      );
    }
  }
}

class HealthPage extends StatefulWidget {
  const HealthPage({super.key, required this.controller});
  final TaskController controller;
  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  late LocalDate day = widget.controller.today;
  @override
  Widget build(BuildContext context) {
    final c = widget.controller,
        life = c.data.life,
        entry = life.health[day.toIso()] ?? const HealthEntry();
    void save(HealthEntry e) => c.updateLife(
      c.data.life.copyWith(health: {...c.data.life.health, day.toIso(): e}),
    );
    HealthEntry update({
      int? water,
      double? sleep,
      int? movement,
      int? mood,
      String? note,
    }) => HealthEntry(
      water: water ?? entry.water,
      sleep: sleep ?? entry.sleep,
      movement: movement ?? entry.movement,
      mood: mood ?? entry.mood,
      note: note ?? entry.note,
    );
    return LifePage(
      children: [
        PageHeading(
          'Kendine iyi bak',
          'Bedenin de seninle büyüsün.',
          'Bu günlük kişisel gözlemlerindir; sağlık puanı veya tıbbi değerlendirme üretmez.',
          action: OutlinedButton.icon(
            onPressed: () async {
              final picked = await pickDate(
                context,
                initial: day,
                help: 'Kayıt günü',
              );
              if (picked != null && !picked.isAfter(c.today)) {
                setState(() => day = picked);
              }
            },
            icon: const Icon(Icons.calendar_today_outlined, size: 17),
            label: Text(day.toIso()),
          ),
        ),
        LifeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Su molası',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bardak sayını kaydet. İhtiyacın kişiden kişiye değişir.',
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Bir bardak azalt',
                    onPressed: entry.water == 0
                        ? null
                        : () => save(update(water: entry.water - 1)),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '${entry.water}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  IconButton(
                    tooltip: 'Bir bardak su ekle',
                    onPressed: entry.water >= 40
                        ? null
                        : () => save(update(water: entry.water + 1)),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  const SizedBox(width: 8),
                  const Text('bardak'),
                ],
              ),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: List.generate(
                  entry.water.clamp(0, 16),
                  (i) => const Icon(
                    Icons.water_drop_rounded,
                    color: Color(0xFF6F9DB6),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        LifeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dinlenme ve hareket',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 20,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<double>(
                      key: ValueKey('sleep-$day-${entry.sleep}'),
                      initialValue: entry.sleep,
                      decoration: const InputDecoration(
                        labelText: 'Uyku süresi',
                      ),
                      items:
                          {
                                for (var i = 0; i <= 48; i++) i / 2,
                                if (entry.sleep != null) entry.sleep!,
                              }
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('$v saat'),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => save(update(sleep: v)),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('move-$day-${entry.movement}'),
                      initialValue: entry.movement,
                      decoration: const InputDecoration(
                        labelText: 'Hareket süresi',
                      ),
                      items:
                          {
                                0,
                                10,
                                15,
                                20,
                                30,
                                45,
                                60,
                                90,
                                120,
                                if (entry.movement != null) entry.movement!,
                              }
                              .toList()
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('$v dakika'),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => save(update(movement: v)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Bugün nasıl hissediyorsun?'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (v, label) in [
                    (1, 'Zor'),
                    (2, 'Düşük'),
                    (3, 'Dengeli'),
                    (4, 'İyi'),
                    (5, 'Harika'),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: entry.mood == v,
                      onSelected: (_) => save(update(mood: v)),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                key: ValueKey('note-$day'),
                initialValue: entry.note,
                maxLength: 2000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Kendine bir not',
                  hintText: 'Sana iyi gelen neydi?',
                ),
                onChanged: (v) => save(update(note: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('Son kayıtların', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (life.health.isEmpty)
          const Text('İlk kaydınla kendi ritmini keşfetmeye başla.'),
        for (final key
            in (life.health.keys.toList()..sort((a, b) => b.compareTo(a))).take(
              14,
            ))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.favorite_outline, color: sage),
            title: Text(key),
            subtitle: Text(
              'Su: ${life.health[key]!.water} bardak · Uyku: ${life.health[key]!.sleep ?? '—'} saat · Hareket: ${life.health[key]!.movement ?? '—'} dk',
            ),
            onTap: () => setState(() => day = LocalDate.parse(key)),
          ),
      ],
    );
  }
}

class FocusPage extends StatelessWidget {
  const FocusPage({super.key, required this.controller, required this.clock});
  final TaskController controller;
  final FocusClock clock;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: clock,
    builder: (context, _) => LifePage(
      children: [
        const PageHeading(
          'Biraz yavaşla',
          'Tek bir şeye alan aç.',
          'Odak seansın sekmeler arasında devam eder. Kaydı tamamladığında sen onaylarsın.',
        ),
        LifeCard(
          child: Column(
            children: [
              const Icon(Icons.spa_outlined, size: 36, color: sage),
              const SizedBox(height: 18),
              Text(
                '${(clock.remaining ~/ 60).toString().padLeft(2, '0')}:${(clock.remaining % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w300,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                clock.completed
                    ? 'Bir nefes al. Seans sona erdi.'
                    : clock.running
                    ? 'Şu an, sadece bu adım.'
                    : 'Hazır olduğunda başla.',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final minutes in [5, 15, 25, 45, 60])
                    ChoiceChip(
                      label: Text('$minutes dk'),
                      selected: clock.minutes == minutes,
                      onSelected: clock.running
                          ? null
                          : (_) => clock.configure(minutes),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 440,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(clock.taskId),
                  initialValue: controller.data.taskById(clock.taskId) == null
                      ? ''
                      : clock.taskId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Neye odaklanıyorsun?',
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Serbest odak'),
                    ),
                    for (final t in controller.data.tasks)
                      DropdownMenuItem(
                        value: t.id,
                        child: Text(t.title, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: clock.running
                      ? null
                      : (v) {
                          clock.taskId = v!;
                        },
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: clock.completed
                        ? null
                        : clock.running
                        ? clock.pause
                        : clock.start,
                    icon: Icon(clock.running ? Icons.pause : Icons.play_arrow),
                    label: Text(clock.running ? 'Mola ver' : 'Odaklan'),
                  ),
                  OutlinedButton.icon(
                    onPressed: clock.reset,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Sıfırla'),
                  ),
                ],
              ),
              if (clock.completed)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: FilledButton.tonalIcon(
                    onPressed: clock.recorded
                        ? null
                        : () {
                            if (!clock.completed || clock.recorded) return;
                            final life = controller.data.life;
                            controller.updateLife(
                              life.copyWith(
                                sessions: [
                                  ...life.sessions,
                                  FocusSession(
                                    id: controller.newLifeId(),
                                    at: controller.now(),
                                    minutes: clock.minutes,
                                    taskId: clock.taskId,
                                  ),
                                ],
                              ),
                            );
                            clock.markRecorded();
                          },
                    icon: const Icon(Icons.check),
                    label: Text(
                      clock.recorded
                          ? 'Seans kaydedildi'
                          : 'Bu seansı tamamladım, kaydet',
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              const Text(
                'Seans kaydı görevi otomatik işaretlemez. Uygulama kapanırsa sayaç sıfırlanır.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Odak günlüğün', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (controller.data.life.sessions.isEmpty)
          const Text('Henüz onaylanmış bir seans yok.'),
        for (final s in controller.data.life.sessions.reversed.take(20))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.timelapse, color: sage),
            title: Text(
              '${s.minutes} dakika · ${controller.data.taskById(s.taskId)?.title ?? 'Serbest odak'}',
            ),
            subtitle: Text(LocalDate.of(s.at).toIso()),
          ),
      ],
    ),
  );
}

class AtlasPage extends StatelessWidget {
  const AtlasPage({super.key, required this.controller});
  final TaskController controller;
  @override
  Widget build(BuildContext context) {
    final life = controller.data.life;
    return LifePage(
      children: [
        PageHeading(
          'Puanlardan daha fazlası',
          'Yaşam atlasın',
          'Öğrendiğin diller, gördüğün yerler, hayatındaki ilkler. Kendi beyanınla tuttuğun anılar.',
          action: FilledButton.icon(
            onPressed: () => _add(context),
            icon: const Icon(Icons.add),
            label: const Text('Bir anı ekle'),
          ),
        ),
        if (life.milestones.isEmpty)
          LifeCard(
            child: Column(
              children: [
                CompanionScene(color: life.companion, height: 190),
                const Text(
                  'Hikâyen burada birikecek.',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                const SizedBox(height: 10),
                const Text(
                  'İlk seyahatin, bitirdiğin bir kitap, öğrendiğin bir dil…',
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        for (final m in life.milestones.reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LifeCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    m.kind == 'Ülke'
                        ? Icons.public
                        : m.kind == 'Dil'
                        ? Icons.translate
                        : Icons.auto_awesome_outlined,
                    color: sage,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${m.kind} · ${m.date.toIso()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (m.note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(m.note),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Anıyı kaldır',
                    onPressed: () {
                      final before = controller.data;
                      controller.updateLife(
                        life.copyWith(
                          milestones: life.milestones
                              .where((e) => e.id != m.id)
                              .toList(),
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Anı kaldırıldı'),
                          action: SnackBarAction(
                            label: 'Geri al',
                            onPressed: () => controller.restore(before),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _add(BuildContext context) async {
    final title = TextEditingController(), note = TextEditingController();
    var kind = 'İlkler';
    var date = controller.today;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, set) => AlertDialog(
          title: const Text('Hikâyene bir iz bırak'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Başlık',
                      hintText: 'Örn. İlk kez İtalya’yı gezdim',
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: kind,
                    items:
                        [
                              'İlkler',
                              'Ülke',
                              'Dil',
                              'Kitap',
                              'Sertifika',
                              'Deneyim',
                            ]
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (v) => set(() => kind = v!),
                  ),
                  TextField(
                    controller: note,
                    maxLength: 2000,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Anın veya kanıt bağlantın',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final d = await pickDate(context, initial: date);
                      if (d != null && !d.isAfter(controller.today)) {
                        set(() => date = d);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 17),
                    label: Text(date.toIso()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                if (title.text.trim().isNotEmpty) Navigator.pop(context, true);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      controller.updateLife(
        controller.data.life.copyWith(
          milestones: [
            ...controller.data.life.milestones,
            Milestone(
              id: controller.newLifeId(),
              title: title.text.trim(),
              kind: kind,
              date: date,
              note: note.text.trim(),
            ),
          ],
        ),
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    title.dispose();
    note.dispose();
  }
}
