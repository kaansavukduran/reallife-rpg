import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/life.dart';

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

/// Original vector illustration, drawn locally at every display density.
/// The entrance is finite so reduced motion and keyboard use remain calm.
class CompanionScene extends StatefulWidget {
  const CompanionScene({super.key, this.color = 'mint', this.height = 240});
  final String color;
  final double height;
  @override
  State<CompanionScene> createState() => _CompanionSceneState();
}

class _CompanionSceneState extends State<CompanionScene> {
  int _wave = 0;
  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Kitap okuyan sevimli aksolotl yol arkadaşın. Dokununca selam verir.',
    button: true,
    child: InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () => setState(() => _wave++),
      child: TweenAnimationBuilder<double>(
        key: ValueKey('${widget.color}-$_wave'),
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 1200),
        curve: Curves.easeOutBack,
        builder: (_, value, _) => SizedBox(
          height: widget.height,
          width: double.infinity,
          child: CustomPaint(painter: _GardenPainter(value, widget.color)),
        ),
      ),
    ),
  );
}

class _GardenPainter extends CustomPainter {
  const _GardenPainter(this.progress, this.color);
  final double progress;
  final String color;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 420, size.height / 280);
    canvas.save();
    canvas.translate(
      (size.width - 420 * scale) / 2,
      (size.height - 280 * scale) / 2,
    );
    canvas.scale(scale);
    void oval(double x, double y, double w, double h, Color c) =>
        canvas.drawOval(Rect.fromLTWH(x, y, w, h), Paint()..color = c);
    void line(Offset a, Offset b, Color c, double w) => canvas.drawLine(
      a,
      b,
      Paint()
        ..color = c
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
    void round(double x, double y, double w, double h, double r, Color c) =>
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h),
            Radius.circular(r),
          ),
          Paint()..color = c,
        );
    const leaf = Color(0xFF89AB83),
        forest = Color(0xFF527B62),
        light = Color(0xFFD7E3C9);
    oval(60, 32, 292, 222, const Color(0xFFE4ECD9));
    oval(294, 39, 39, 39, const Color(0xFFF2D58D));
    final hill = Path()
      ..moveTo(42, 207)
      ..quadraticBezierTo(82, 110, 147, 184)
      ..quadraticBezierTo(210, 115, 270, 175)
      ..quadraticBezierTo(355, 150, 392, 219)
      ..close();
    canvas.drawPath(hill, Paint()..color = light);
    oval(53, 213, 316, 47, const Color(0xFFBCD0A6));
    oval(86, 216, 250, 27, const Color(0xFF70946B));
    for (final (x, y, h) in [
      (94.0, 171.0, 66.0),
      (327.0, 177.0, 82.0),
      (64.0, 203.0, 35.0),
    ]) {
      line(Offset(x, y + 36), Offset(x, y - h / 2), const Color(0xFF9D9E73), 5);
      final path = Path()
        ..moveTo(x, y - h)
        ..quadraticBezierTo(x - 47, y - 4, x - 33, y + 8)
        ..quadraticBezierTo(x, y + 24, x + 34, y + 7)
        ..quadraticBezierTo(x + 43, y - 5, x, y - h);
      canvas.drawPath(path, Paint()..color = (x == 327 ? forest : leaf));
      line(
        Offset(x, y + 9),
        Offset(x, y - h + 16),
        light.withValues(alpha: .55),
        2,
      );
    }
    canvas.save();
    canvas.translate(0, (1 - progress) * 23);
    final body = color == 'peach'
        ? const Color(0xFFF2B7A6)
        : color == 'lavender'
        ? const Color(0xFFC1B3DF)
        : const Color(0xFFAFD8BC);
    final gill = color == 'peach'
        ? const Color(0xFFD98E8C)
        : color == 'lavender'
        ? const Color(0xFF9784BA)
        : const Color(0xFF79AF91);
    oval(152, 208, 121, 21, const Color(0xFF4C7056).withValues(alpha: .2));
    oval(165, 144, 97, 78, body);
    for (final sign in [-1.0, 1.0]) {
      final x = 211 + 63 * sign;
      for (final dy in [-20.0, 0.0, 20.0]) {
        line(
          Offset(211 + 52 * sign, 116 + dy * .4),
          Offset(x + 17 * sign, 111 + dy),
          gill,
          14,
        );
        oval(x + 12 * sign - 7, 104 + dy, 14, 14, gill);
      }
    }
    round(151, 75, 122, 102, 46, body);
    oval(170, 118, 10, 12, ink);
    oval(242, 118, 10, 12, ink);
    oval(172, 119, 3, 3, Colors.white);
    oval(244, 119, 3, 3, Colors.white);
    oval(162, 135, 21, 10, const Color(0xFFE9A4A0).withValues(alpha: .65));
    oval(241, 135, 21, 10, const Color(0xFFE9A4A0).withValues(alpha: .65));
    final smile = Path()
      ..moveTo(201, 136)
      ..quadraticBezierTo(211, 146, 221, 136);
    canvas.drawPath(
      smile,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    round(177, 57, 73, 27, 12, forest);
    line(const Offset(171, 81), const Offset(260, 81), forest, 9);
    final sprout = Path()
      ..moveTo(210, 59)
      ..quadraticBezierTo(181, 24, 195, 25)
      ..quadraticBezierTo(218, 28, 210, 59)
      ..quadraticBezierTo(234, 25, 243, 37)
      ..quadraticBezierTo(245, 52, 210, 59);
    canvas.drawPath(sprout, Paint()..color = leaf);
    oval(150, 194, 28, 27, body);
    oval(248, 194, 28, 27, body);
    final book = Path()
      ..moveTo(172, 172)
      ..lineTo(210, 184)
      ..lineTo(251, 172)
      ..lineTo(248, 209)
      ..lineTo(210, 220)
      ..lineTo(176, 209)
      ..close();
    canvas.drawPath(book, Paint()..color = const Color(0xFFC8995C));
    final pages = Path()
      ..moveTo(176, 169)
      ..quadraticBezierTo(193, 168, 210, 181)
      ..quadraticBezierTo(231, 167, 247, 169)
      ..lineTo(245, 203)
      ..quadraticBezierTo(227, 203, 210, 215)
      ..quadraticBezierTo(191, 202, 179, 203)
      ..close();
    canvas.drawPath(pages, Paint()..color = const Color(0xFFFFF5DC));
    line(
      const Offset(210, 183),
      const Offset(210, 212),
      const Color(0xFFD5BD93),
      1.5,
    );
    oval(159, 177, 21, 15, body);
    oval(244, 177, 21, 15, body);
    canvas.restore();
    for (final (x, y) in [(124.0, 63.0), (302.0, 112.0), (284.0, 28.0)]) {
      line(Offset(x - 4, y), Offset(x + 4, y), const Color(0xFFC5A457), 2);
      line(Offset(x, y - 4), Offset(x, y + 4), const Color(0xFFC5A457), 2);
    }
    for (final (x, y) in [(113.0, 220.0), (291.0, 222.0), (341.0, 234.0)]) {
      line(Offset(x, y), Offset(x, y - 13), forest, 2);
      oval(x - 5, y - 18, 10, 10, const Color(0xFFF4E0AA));
      oval(x - 2, y - 15, 4, 4, const Color(0xFFD4AC66));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GardenPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
