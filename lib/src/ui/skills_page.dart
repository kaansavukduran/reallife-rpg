import 'dart:convert';

import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/assessment.dart';
import '../domain/life.dart';
import '../domain/local_date.dart';
import '../services/ai_assessment.dart';
import 'life_widgets.dart';

class SkillsPage extends StatelessWidget {
  const SkillsPage({super.key, required this.controller});
  final TaskController controller;
  @override
  Widget build(BuildContext context) => LifePage(
    children: [
      const PageHeading(
        'Emek başka, yeterlilik başka',
        'Ne kadarını gerçekten biliyorsun?',
        'Görevler emek geçmişini gösterir. Bilgi testi ve uygulamalı değerlendirme, ayrı kanıtlar sunar.',
      ),
      LifeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gelişim alanını seç',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            for (final task in controller.data.tasks)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Expanded(child: Text(task.title)),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 150,
                      child: DropdownButtonFormField<LifeArea>(
                        key: ValueKey(
                          '${task.id}-${controller.data.life.links[task.id]?.area}',
                        ),
                        initialValue:
                            controller.data.life.links[task.id]?.area ??
                            LifeArea.mind,
                        isExpanded: true,
                        items: LifeArea.values
                            .map(
                              (a) => DropdownMenuItem(
                                value: a,
                                child: Text(a.label),
                              ),
                            )
                            .toList(),
                        onChanged: (a) {
                          final life = controller.data.life,
                              old = life.links[task.id];
                          controller.updateLife(
                            life.copyWith(
                              links: {
                                ...life.links,
                                task.id: TaskLink(
                                  area: a!,
                                  projectId: old?.projectId ?? '',
                                  skillId: old?.skillId ?? '',
                                ),
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            if (controller.data.tasks.isEmpty)
              const Text(
                'Görev eklediğinde hangi yaşam alanını geliştirdiğini burada seçebilirsin.',
              ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      for (final skill in skillCatalog)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: LifeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school_outlined, color: sage),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        skill.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(skill.description),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _openQuiz(context, skill),
                      icon: const Icon(Icons.quiz_outlined, size: 18),
                      label: const Text('5 soruluk bilgi testi'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openPractice(context, skill),
                      icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                      label: const Text('Uygulamalı AI değerlendirmesi'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _latest(skill.id),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      const Text(
        'Bu kısa testler sınırlı örneklemdir. CEFR, diploma veya uzmanlık sertifikası yerine geçmez. Aynı testin tekrarı öğrenme amaçlıdır; sonuçlar XP kazandırmaz.',
        style: TextStyle(fontSize: 12, height: 1.6),
      ),
      const SizedBox(height: 24),
      Text('Kanıt günlüğün', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      for (final record in controller.data.life.assessments.reversed)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          leading: const Icon(Icons.fact_check_outlined, color: sage),
          title: Text(
            '${skillCatalog.where((s) => s.id == record.skill).firstOrNull?.name ?? record.skill} · ${record.score}/${record.total}',
          ),
          subtitle: Text(
            '${record.method} · ${LocalDate.of(record.at).toIso()} · ${record.rubric}',
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(record.feedback),
                  const SizedBox(height: 12),
                  const Text(
                    'Kaydedilen yanıt / kanıt',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(record.evidence),
                ],
              ),
            ),
          ],
        ),
    ],
  );
  String _latest(String id) {
    final last = controller.data.life.assessments
        .where((r) => r.skill == id)
        .lastOrNull;
    return last == null
        ? 'Henüz ölçüm yok. Başlangıç noktanı keşfet.'
        : 'Son ölçüm: ${last.score}/${last.total} · ${last.method}';
  }

  Future<void> _openQuiz(BuildContext context, SkillSpec skill) =>
      showDialog<void>(
        context: context,
        builder: (_) => _Quiz(controller: controller, skill: skill),
      );
  Future<void> _openPractice(BuildContext context, SkillSpec skill) =>
      showDialog<void>(
        context: context,
        builder: (_) => _Practice(controller: controller, skill: skill),
      );
}

class _Quiz extends StatefulWidget {
  const _Quiz({required this.controller, required this.skill});
  final TaskController controller;
  final SkillSpec skill;
  @override
  State<_Quiz> createState() => _QuizState();
}

class _QuizState extends State<_Quiz> {
  late final List<int?> answers = List.filled(
    widget.skill.questions.length,
    null,
  );
  bool submitted = false;
  String? error;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${widget.skill.name} · Bilgi testi'),
    content: SizedBox(
      width: 600,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Örneklem: 5 temel soru · Ölçüt: doğru yanıt sayısı · Sürüm: bilgi-v1',
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < widget.skill.questions.length; i++) ...[
              Text(
                '${i + 1}. ${widget.skill.questions[i].prompt}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (var j = 0; j < widget.skill.questions[i].options.length; j++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: _option(i, j),
                ),
              if (submitted)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Text(
                    widget.skill.questions[i].explanation,
                    style: TextStyle(
                      color: answers[i] == widget.skill.questions[i].answer
                          ? sage
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 18),
            ],
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (submitted)
              Text(
                'Sonuç: ${widget.skill.grade(answers)} / ${answers.length}. Yanıtların kanıt günlüğüne kaydedildi.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Kapat'),
      ),
      if (!submitted)
        FilledButton(
          onPressed: _submit,
          child: const Text('Yanıtları değerlendir'),
        ),
    ],
  );
  Widget _option(int i, int j) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: submitted ? null : () => setState(() => answers[i] = j),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: answers[i] == j ? sage.withValues(alpha: .12) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Text(
          '${answers[i] == j ? '●' : '○'}  ${widget.skill.questions[i].options[j]}',
        ),
      ),
    ),
  );
  void _submit() {
    if (answers.any((a) => a == null)) {
      setState(() => error = 'Önce tüm soruları yanıtla.');
      return;
    }
    final skill = widget.skill, c = widget.controller;
    c.updateLife(
      c.data.life.copyWith(
        assessments: [
          ...c.data.life.assessments,
          AssessmentRecord(
            id: c.newLifeId(),
            skill: skill.id,
            at: c.now(),
            score: skill.grade(answers),
            total: answers.length,
            method: 'Bilgi testi',
            feedback: skill.questions.map((q) => q.explanation).join('\n'),
            evidence: jsonEncode({
              'answers': answers,
              'questions': skill.questions.map((q) => q.prompt).toList(),
            }),
            rubric: 'bilgi-v1',
          ),
        ],
      ),
    );
    setState(() {
      submitted = true;
      error = null;
    });
  }
}

class _Practice extends StatefulWidget {
  const _Practice({required this.controller, required this.skill});
  final TaskController controller;
  final SkillSpec skill;
  @override
  State<_Practice> createState() => _PracticeState();
}

class _PracticeState extends State<_Practice> {
  final evidence = TextEditingController();
  bool sending = false, saved = false;
  String? error;
  @override
  void dispose() {
    evidence.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !sending,
    child: AlertDialog(
      title: Text('${widget.skill.name} · Uygulama'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.skill.challenge,
                style: const TextStyle(height: 1.65),
              ),
              const SizedBox(height: 18),
              const Text(
                'Ölçütler: doğruluk, akıl yürütme, uygulama, sınırlılıkları fark etme. Her biri 0–4 puan. Model yorumu ve kanıt alıntıları kaydedilir.',
                style: TextStyle(fontSize: 12, height: 1.6),
              ),
              const SizedBox(height: 16),
              if (!aiConfigured)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'AI servisi bu derlemede yapılandırılmamış. Çevrimdışı bilgi testlerini kullanabilirsin. Kurulum: README → AI servisi.',
                  ),
                ),
              TextField(
                controller: evidence,
                minLines: 7,
                maxLines: 14,
                maxLength: 16000,
                enabled: !sending && !saved,
                decoration: const InputDecoration(
                  labelText: 'Yanıtın / çalışma kanıtın',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Değerlendir düğmesi yalnızca bu metni ve seçili beceriyi yapılandırılmış AI servisine gönderir. Sağlık, görev ve profil bilgilerin gönderilmez.',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (saved)
                const Text('Değerlendirme kanıt günlüğüne kaydedildi.'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: sending ? null : () => Navigator.pop(context),
          child: const Text('Kapat'),
        ),
        FilledButton(
          onPressed: !aiConfigured || sending || saved ? null : _send,
          child: Text(sending ? 'Değerlendiriliyor…' : 'AI ile değerlendir'),
        ),
      ],
    ),
  );
  Future<void> _send() async {
    if (evidence.text.trim().length < 100) {
      setState(
        () => error =
            'Değerlendirilebilmesi için en az 100 karakterlik bir yanıt yaz.',
      );
      return;
    }
    setState(() {
      sending = true;
      error = null;
    });
    try {
      final result = await assessPractice(
        widget.skill.id,
        evidence.text.trim(),
      );
      final score = integer(result, 'score', 0, 16),
          total = integer(result, 'total', 16, 16);
      final feedback = string(result, 'feedback'),
          rubric = string(result, 'rubric');
      if (!mounted) return;
      final c = widget.controller;
      c.updateLife(
        c.data.life.copyWith(
          assessments: [
            ...c.data.life.assessments,
            AssessmentRecord(
              id: c.newLifeId(),
              skill: widget.skill.id,
              at: c.now(),
              score: score,
              total: total,
              method: 'AI · uygulamalı örneklem',
              feedback: feedback,
              evidence: evidence.text.trim(),
              rubric: rubric,
            ),
          ],
        ),
      );
      setState(() => saved = true);
    } catch (e) {
      if (mounted) setState(() => error = 'Değerlendirme kaydedilemedi: $e');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }
}
