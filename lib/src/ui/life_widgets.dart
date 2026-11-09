import 'package:flutter/material.dart';

import '../domain/life.dart';
import '../domain/fitness.dart';
import 'companion_stage.dart';

const sage = Color(0xFF527B62);
const ink = Color(0xFF283D33);

IconData areaIcon(LifeArea area) => switch (area) {
  LifeArea.mind => Icons.auto_stories_outlined,
  LifeArea.body => Icons.favorite_border_rounded,
  LifeArea.craft => Icons.handyman_outlined,
  LifeArea.social => Icons.people_outline_rounded,
  LifeArea.spirit => Icons.spa_outlined,
};

Color areaColor(LifeArea area) => switch (area) {
  LifeArea.mind => const Color(0xFF8A79B1),
  LifeArea.body => const Color(0xFFCC856F),
  LifeArea.craft => const Color(0xFFB18C48),
  LifeArea.social => const Color(0xFF668FAB),
  LifeArea.spirit => sage,
};

class LifeCard extends StatelessWidget {
  const LifeCard({
    super.key,
    required this.child,
    this.color,
    this.padding = 22,
  });
  final Widget child;
  final Color? color;
  final double padding;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: color,
    elevation: 0,
    child: Padding(padding: EdgeInsets.all(padding), child: child),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(
    this.eyebrow,
    this.title,
    this.subtitle, {
    super.key,
    this.action,
  });
  final String eyebrow, title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 20,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            ?action,
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    ),
  );
}

class LifePage extends StatelessWidget {
  const LifePage({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1220),
      child: ListView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width > 700 ? 32 : 16,
        ),
        children: children,
      ),
    ),
  );
}

class MiniMetric extends StatelessWidget {
  const MiniMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    this.color = sage,
  });
  final IconData icon;
  final String label, value, detail;
  final Color color;
  @override
  Widget build(BuildContext context) => LifeCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

/// Shared selected character, used by adventure, identity and atlas.
class CompanionScene extends StatelessWidget {
  const CompanionScene({super.key, this.color = 'aion', this.height = 240});
  final String color;
  final double height;
  @override
  Widget build(BuildContext context) =>
      CompanionStage(character: color, motion: Motion.read, height: height);
}
