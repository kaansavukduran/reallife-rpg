import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../l10n/strings.dart';
import 'companion_stage.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.id, this.size = 36});
  final String id;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.s(companionId(id)),
    image: true,
    child: SizedBox(
      width: size,
      height: size,
      child: id == 'aion'
          ? Image.asset('assets/branding/aion-icon.png')
          : FutureBuilder<ui.Image>(
              future: loadMoodAtlas(),
              builder: (context, snapshot) =>
                  CustomPaint(painter: _LogoPainter(id, snapshot.data)),
            ),
    ),
  );
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter(this.id, this.atlas);
  final String id;
  final ui.Image? atlas;
  @override
  void paint(Canvas c, Size size) {
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      Paint()..color = const Color(0xFFFFE5EF),
    );
    if (atlas != null) {
      final w = atlas!.width / 3,
          h = atlas!.height / 4,
          index = companionIds.indexOf(companionId(id));
      c.drawImageRect(
        atlas!,
        Rect.fromLTWH(0, index * h, w, h),
        Offset.zero & size,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.id != id || old.atlas != atlas;
}

class LogoSettings extends StatelessWidget {
  const LogoSettings({super.key, required this.controller});
  final TaskController controller;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 20),
      Text(context.s('appLogo'), style: Theme.of(context).textTheme.titleLarge),
      Text(context.s('logoHelp')),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final id in companionIds)
            ChoiceChip(
              key: Key('logo-$id'),
              avatar: AppLogo(id: id, size: 28),
              label: Text(context.s(id)),
              selected: controller.settings.logoId == id,
              onSelected: (_) => controller.updateSettings(
                controller.settings.copyWith(logoId: id),
              ),
            ),
        ],
      ),
    ],
  );
}
