import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/task_controller.dart';
import '../app/focus_clock.dart';
import 'adventure_page.dart';
import 'life_pages.dart';
import 'life_widgets.dart';
import 'skills_page.dart';
import 'fitness_page.dart';
import 'nutrition_page.dart';
import 'companions_page.dart';
import '../l10n/strings.dart';
import '../domain/local_date.dart';
import 'character_page.dart';
import 'day_page.dart';
import 'history_page.dart';
import 'settings_page.dart';
import 'task_actions.dart';
import 'tasks_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.controller,
    this.version = '',
    this.initialPage = 'gun',
  });

  final TaskController controller;
  final String version;
  final String initialPage;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _tab = _tabs().indexWhere((t) => t.id == widget.initialPage);
  final FocusClock _focus = FocusClock();
  late LocalDate _day = widget.controller.today;
  Timer? _clock;
  late bool _lastGameMode = controller.settings.gameMode;

  TaskController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    // Past midnight the new day becomes "today"; a person looking at the
    // old today follows it.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      final before = controller.today;
      if (controller.refreshToday() && _day == before) {
        setState(() => _day = controller.today);
      }
      _remind();
    });
  }

  /// Reminders already shown today (task id + time), so each shows once.
  final Set<String> _reminded = {};

  /// Shows an in-app reminder for every task whose time has come today and
  /// that is not ticked yet. (System notifications are not used: the app
  /// works only while it is open.)
  void _remind() {
    if (!mounted || controller.state != LoadState.ready) return;
    final now = controller.now();
    final today = controller.today;
    final minutes = now.hour * 60 + now.minute;
    final due = [
      for (final t in controller.data.tasksOn(today))
        if (t.time != null &&
            t.time!.minutes <= minutes &&
            !controller.data.isDone(t.id, today) &&
            _reminded.add('${today.toIso()} ${t.id} ${t.time!.format()}'))
          t,
    ];
    if (due.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        key: const Key('reminder'),
        width: MediaQuery.sizeOf(context).width > 560 ? 520 : null,
        duration: const Duration(seconds: 12),
        content: Text(
          'Hatırlatma: ${due.map((t) => '${t.time!.format()} ${t.title}').join(', ')}',
        ),
        action: SnackBarAction(
          label: 'Güne git',
          onPressed: () => _setDay(controller.today),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _clock?.cancel();
    _focus.dispose();
    super.dispose();
  }

  void _setDay(LocalDate d) => setState(() {
    _day = d;
    _tab = 0;
  });

  Future<void> _newTask() => addTaskWithEditor(
    context,
    controller,
    start: _tab == 0 ? _day : controller.today,
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => switch (controller.state) {
        LoadState.loading => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        LoadState.unreadable => _UnreadablePage(controller: controller),
        LoadState.ready => _ready(context),
      },
    );
  }

  /// Tabs in order; Karakter only in game mode.
  List<_Tab> _tabs() => [
    const _Tab('gun', Icons.today_outlined, Icons.today, 'Gün'),
    const _Tab('gorevler', Icons.list_alt_outlined, Icons.list_alt, 'Görevler'),
    const _Tab('kontrol', Icons.grid_view_outlined, Icons.grid_view, 'Kontrol'),
    if (controller.settings.gameMode)
      const _Tab('karakter', Icons.person_outline, Icons.person, 'Karakter'),
    const _Tab('ayarlar', Icons.settings_outlined, Icons.settings, 'Ayarlar'),
    const _Tab(
      'maceram',
      Icons.grid_view_rounded,
      Icons.grid_view_rounded,
      'Maceram',
    ),
    const _Tab('projeler', Icons.flag_outlined, Icons.flag, 'Projeler'),
    const _Tab(
      'yetenekler',
      Icons.account_tree_outlined,
      Icons.account_tree,
      'Yetenekler',
    ),
    const _Tab(
      'saglik',
      Icons.favorite_border_rounded,
      Icons.favorite,
      'Sağlık',
    ),
    const _Tab('odak', Icons.timelapse_outlined, Icons.timelapse, 'Odak'),
    const _Tab('atlas', Icons.public_outlined, Icons.public, 'Yaşam atlası'),
    const _Tab(
      'fitness',
      Icons.fitness_center_outlined,
      Icons.fitness_center,
      'Spor',
    ),
    const _Tab(
      'nutrition',
      Icons.restaurant_outlined,
      Icons.restaurant,
      'Beslenme',
    ),
    const _Tab(
      'companions',
      Icons.pets_outlined,
      Icons.pets,
      'Yol arkadaşları',
    ),
  ];

  void _go(String id) {
    final i = _tabs().indexWhere((t) => t.id == id);
    if (i >= 0) setState(() => _tab = i);
  }

  Widget _ready(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    if (_lastGameMode != controller.settings.gameMode) {
      if (_tab >= 3) _tab += controller.settings.gameMode ? 1 : -1;
      _lastGameMode = controller.settings.gameMode;
    }
    final tabs = _tabs();
    if (_tab >= tabs.length) _tab = tabs.length - 1;
    final current = tabs[_tab].id;
    final Widget page = switch (current) {
      'fitness' => FitnessPage(controller: controller),
      'nutrition' => NutritionPage(controller: controller),
      'companions' => CompanionsPage(controller: controller),
      'maceram' => AdventurePage(controller: controller, go: _go),
      'projeler' => ProjectsPage(controller: controller),
      'yetenekler' => SkillsPage(controller: controller),
      'saglik' => HealthPage(controller: controller),
      'odak' => FocusPage(controller: controller, clock: _focus),
      'atlas' => AtlasPage(controller: controller),
      'gun' => DayPage(
        controller: controller,
        day: _day,
        onDayChanged: _setDay,
        onOpenCharacter: () => _go('karakter'),
      ),
      'gorevler' => TasksPage(controller: controller),
      'kontrol' => HistoryPage(controller: controller),
      'karakter' => CharacterPage(controller: controller),
      _ => SettingsPage(controller: controller, version: widget.version),
    };

    final body = Column(
      children: [
        if (!controller.store.persistent)
          const _Banner(
            icon: Icons.info_outline_rounded,
            text: 'Bellek önizlemesi: bu oturumdaki değişiklikler kalıcı kaydedilmez.',
          ),
        if (controller.saveError != null)
          _Banner(
            icon: Icons.error_outline_rounded,
            text:
                '${controller.saveError}\nDeğişiklik ekranda duruyor; bir sonraki değişiklikte yeniden denenecek.',
            error: true,
          ),
        Expanded(child: page),
      ],
    );

    final scaffold = Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco_rounded, color: sage, size: 25),
              const SizedBox(width: 9),
              const Text(
                'RealLife',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'RPG',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width > 600)
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Cihazında, sana ait',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
      drawer: wide
          ? null
          : Drawer(child: SafeArea(child: _sidebar(tabs, current))),
      floatingActionButton: current != 'gorevler'
          ? null
          : FloatingActionButton.extended(
              key: const Key('new-task-fab'),
              tooltip: 'Yeni görev (Ctrl + N)',
              onPressed: _newTask,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni görev'),
            ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _tab < _mainTabs(tabs).length ? _tab : 0,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: [
                for (final t in _mainTabs(tabs))
                  NavigationDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.selected),
                    label: context.s(t.id),
                  ),
              ],
            ),
      body: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 208, child: _sidebar(tabs, current)),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
    );

    void tab(int i) {
      if (i < tabs.length) setState(() => _tab = i);
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _newTask,
        const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): () =>
            _setDay(_day.addDays(-1)),
        const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): () =>
            _setDay(_day.addDays(1)),
        const SingleActivator(LogicalKeyboardKey.keyB, alt: true): () =>
            _setDay(controller.today),
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () =>
            tab(0),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
            tab(1),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () =>
            tab(2),
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () =>
            tab(3),
        const SingleActivator(LogicalKeyboardKey.digit5, control: true): () =>
            tab(4),
      },
      child: Focus(autofocus: true, child: scaffold),
    );
  }

  List<_Tab> _mainTabs(List<_Tab> tabs) =>
      tabs.take(controller.settings.gameMode ? 5 : 4).toList();

  Widget _sidebar(List<_Tab> tabs, String current) {
    final order = [
      'maceram',
      'ayarlar',
      'gun',
      'gorevler',
      'projeler',
      'yetenekler',
      'karakter',
      'saglik',
      'fitness',
      'nutrition',
      'companions',
      'odak',
      'atlas',
      'kontrol',
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 22, 14, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 0, 18),
            child: Text(
              'KENDİNE BİR YOL ÇİZ',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.7,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final id in order)
            for (final t in tabs.where((t) => t.id == id))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  selected: current == t.id,
                  selectedTileColor: Theme.of(context).colorScheme.primary
                      .withValues(alpha: .1),
                  leading: Icon(t.icon, size: 20),
                  title: Text(
                    context.s(t.id),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: current == t.id
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    if (MediaQuery.sizeOf(context).width < 720 &&
                        Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                    _go(t.id);
                  },
                ),
              ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: .06),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.spa_outlined, color: sage, size: 21),
                SizedBox(height: 10),
                Text(
                  'Kendi hızında büyü.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  'Bugün attığın küçük bir adım bile yeterli.',
                  style: TextStyle(fontSize: 11, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab(this.id, this.icon, this.selected, this.label);
  final String id;
  final IconData icon;
  final IconData selected;
  final String label;
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, this.error = false});

  final IconData icon;
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: error ? scheme.errorContainer : scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              color: error
                  ? scheme.onErrorContainer
                  : scheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: error
                      ? scheme.onErrorContainer
                      : scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadablePage extends StatelessWidget {
  const _UnreadablePage({required this.controller});

  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = controller.store;
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco_rounded, color: sage, size: 25),
              const SizedBox(width: 9),
              const Text(
                'RealLife',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'RPG',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width > 600)
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Cihazında, sana ait',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.report_problem_outlined,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Kayıtlı görevler açılamadı',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  controller.loadError ?? '',
                  key: const Key('unreadable-message'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Dosya:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SelectableText(store.location),
                if (store.backupLocation != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Günlük yedekler:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SelectableText(store.backupLocation!),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Dosyaya dokunulmadı ve üzerine yazılmadı. Bir yedeği bu dosyanın '
                  'yerine kopyalayıp uygulamayı yeniden açabilir ya da dosyayı kenara '
                  'alıp boş bir listeyle başlayabilirsin.',
                ),
                const SizedBox(height: 20),
                FilledButton.tonal(
                  key: const Key('start-over'),
                  onPressed: () async {
                    final movedTo = await controller.startOverAfterUnreadable();
                    if (!context.mounted) return;
                    showUndoSnack(
                      context,
                      'Eski dosya şuraya taşındı: $movedTo',
                    );
                  },
                  child: const Text('Dosyayı kenara al ve boş liste başlat'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
