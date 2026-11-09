import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/fitness.dart';
import '../l10n/strings.dart';

const companionIds = ['aion', 'sheep', 'wolf', 'owl'];
String companionId(String id) => companionIds.contains(id) ? id : 'aion';
Future<ui.Image>? _atlas;
Future<ui.Image> _loadAtlas() =>
    _atlas ??= rootBundle.load('assets/companions/heads.png').then((b) async {
      final codec = await ui.instantiateImageCodec(b.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    });

/// A small local articulated 2D rig. Playback changes no user data or XP.
class CompanionStage extends StatefulWidget {
  const CompanionStage({
    super.key,
    required this.character,
    this.motion = Motion.idle,
    this.equipment = Equipment.bodyweight,
    this.height = 300,
    this.controls = false,
    this.autoplay = false,
    this.exerciseId = '',
  });
  final String character;
  final String exerciseId;
  final Motion motion;
  final Equipment equipment;
  final double height;
  final bool controls, autoplay;
  @override
  State<CompanionStage> createState() => _CompanionStageState();
}

class _CompanionStageState extends State<CompanionStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  bool _playing = false;
  bool _reduced = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      _clock.stop();
      _playing = false;
    } else if (!_reduced && widget.autoplay && !_playing) {
      _clock.repeat();
      _playing = true;
    }
    _reduced = reduced;
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label:
              '${s('scene')}: ${s(companionId(widget.character))}. ${s('motion.${widget.motion.name}')}。 ${s('animationBody')}',
          image: true,
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: RepaintBoundary(
              child: FutureBuilder<ui.Image>(
                future: _loadAtlas(),
                builder: (context, snapshot) => AnimatedBuilder(
                  animation: _clock,
                  builder: (context, _) => CustomPaint(
                    painter: CompanionPainter(
                      character: companionId(widget.character),
                      motion: widget.motion,
                      equipment: widget.equipment,
                      phase: _clock.value,
                      atlas: snapshot.data,
                      exerciseId: widget.exerciseId,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.controls) ...[
          if (_reduced)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(s('reduced')),
            ),
          Row(
            children: [
              IconButton(
                key: const Key('animation-play'),
                tooltip: s(_playing ? 'pause' : 'play'),
                onPressed: _reduced
                    ? null
                    : () => setState(() {
                        _playing = !_playing;
                        if (_playing) {
                          _clock.repeat();
                        } else {
                          _clock.stop();
                        }
                      }),
                icon: Icon(
                  _playing
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _clock,
                  builder: (context, _) => Slider(
                    key: const Key('animation-phase'),
                    label: '${(_clock.value * 100).round()}%',
                    value: _clock.value,
                    onChanged: (v) {
                      setState(() {
                        _playing = false;
                        _clock.stop();
                        _clock.value = v;
                      });
                    },
                    semanticFormatterCallback: (v) =>
                        '${s('frame')} ${(v * 100).round()}%',
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class CompanionPainter extends CustomPainter {
  const CompanionPainter({
    required this.character,
    required this.motion,
    required this.equipment,
    required this.phase,
    this.atlas,
    this.exerciseId = '',
  });
  final String character;
  final String exerciseId;
  final Motion motion;
  final Equipment equipment;
  final double phase;
  final ui.Image? atlas;
  @override
  void paint(Canvas c, Size size) {
    final z = math.min(size.width / 400, size.height / 360);
    c.save();
    c.translate((size.width - 400 * z) / 2, (size.height - 360 * z) / 2);
    c.scale(z);
    final t = (1 - math.cos(phase * math.pi * 2)) / 2;
    final skin = switch (character) {
      'sheep' => const Color(0xFFFFE3BF),
      'wolf' => const Color(0xFF99889F),
      'owl' => const Color(0xFFD38142),
      _ => const Color(0xFFFF9BBE),
    };
    const steel = Color(0xFF536974),
        pad = Color(0xFF253D47),
        cyan = Color(0xFF66D5ED);
    void oval(double x, double y, double w, double h, Color color) =>
        c.drawOval(Rect.fromLTWH(x, y, w, h), Paint()..color = color);
    void line(Offset a, Offset b, Color color, double w) => c.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
    void round(double x, double y, double w, double h, double r, Color color) =>
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h),
            Radius.circular(r),
          ),
          Paint()..color = color,
        );
    void limb(Offset a, Offset b, double width) {
      line(a, b, skin.withValues(alpha: .65), width + 3);
      line(a, b, skin, width);
      line(
        a + const Offset(-2, -2),
        b + const Offset(-2, -2),
        Colors.white.withValues(alpha: .18),
        width * .25,
      );
    }

    oval(33, 19, 334, 319, const Color(0xFFEDF2E9));
    oval(95, 315, 215, 20, const Color(0xFFCBD7C7));
    final machine =
        equipment == Equipment.machine || equipment == Equipment.cable;
    if (machine) {
      line(const Offset(93, 314), const Offset(307, 314), steel, 9);
      line(const Offset(120, 310), const Offset(120, 111), steel, 9);
      line(const Offset(280, 310), const Offset(280, 111), steel, 9);
      round(105, 103, 190, 15, 7, steel);
      round(256, 176, 30, 83, 7, pad);
      for (int i = 0; i < 5; i++) {
        round(261, 185 + i * 11, 20, 7, 2, Color.lerp(steel, cyan, t * .5)!);
      }
      round(171, 255, 61, 13, 5, pad);
      line(const Offset(201, 265), const Offset(201, 313), steel, 8);
    }
    if ([
      Motion.cycle,
      Motion.elliptical,
      Motion.rowing,
      Motion.stairs,
      Motion.walk,
    ].contains(motion)) {
      line(const Offset(91, 316), const Offset(310, 316), steel, 10);
      if (motion == Motion.cycle) {
        oval(240, 260, 55, 55, steel);
        oval(250, 270, 35, 35, cyan);
        line(const Offset(140, 268), const Offset(267, 288), steel, 9);
        line(const Offset(267, 288), const Offset(283, 200), steel, 8);
        line(const Offset(270, 197), const Offset(310, 197), pad, 9);
        round(161, 257, 57, 12, 5, pad);
      }
      if (motion == Motion.walk || motion == Motion.elliptical) {
        line(const Offset(310, 316), const Offset(310, 200), steel, 8);
        round(275, 186, 55, 24, 6, pad);
      }
      if (motion == Motion.rowing) {
        oval(272, 268, 55, 48, steel);
        line(const Offset(290, 285), const Offset(200, 220), steel, 3);
      }
      if (motion == Motion.stairs) {
        for (int i = 0; i < 3; i++) {
          round(159 + i * 35, 316 - i * 18, 36, 18, 2, steel);
        }
      }
    }
    final reclined =
        [
          'bench_press',
          'incline_press',
          'crunch',
          'glute_bridge',
        ].contains(exerciseId) ||
        motion == Motion.lyingLegCurl ||
        motion == Motion.plank ||
        motion == Motion.sidePlank;
    if (reclined) {
      line(const Offset(74, 294), const Offset(280, 314), steel, 8);
      round(65, 275, 170, 15, 6, pad);
    }
    if (motion == Motion.backExtension) {
      line(const Offset(166, 311), const Offset(215, 250), steel, 9);
      round(177, 247, 60, 14, 5, pad);
    }
    double bob = 0;
    if (motion == Motion.squat || motion == Motion.lunge) bob = 23 * t;
    if (motion == Motion.calf) bob = -12 * t;
    if (motion == Motion.walk || motion == Motion.stairs) {
      bob = -4 * math.sin(phase * 4 * math.pi).abs();
    }
    c.save();
    c.translate(0, bob);
    if (reclined) {
      c.translate(200, 260);
      c.rotate(motion == Motion.sidePlank ? -1.1 : -1.25);
      c.translate(-200, -260);
    }
    // Character-specific silhouettes and accessories remain identifiable in every action.
    if (character == 'aion') {
      final tail = Path()
        ..moveTo(215, 262)
        ..cubicTo(293, 288, 309, 223, 343, 239)
        ..cubicTo(369, 267, 295, 319, 217, 286)
        ..close();
      c.drawPath(tail, Paint()..color = cyan);
      c.drawPath(
        tail,
        Paint()
          ..color = skin
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      for (int i = 0; i < 8; i++) {
        final x = 241.0 + i * 10;
        line(
          Offset(x, 275 + 7 * math.sin(i.toDouble())),
          Offset(x + 4, 280 - 7 * math.sin(i.toDouble())),
          Colors.white.withValues(alpha: .8),
          2,
        );
      }
    }
    if (character == 'wolf') {
      final tail = Path()
        ..moveTo(220, 260)
        ..cubicTo(270, 220, 305, 233, 314, 264)
        ..cubicTo(325, 296, 269, 313, 219, 281)
        ..close();
      c.drawPath(tail, Paint()..color = skin);
      oval(273, 252, 36, 29, const Color(0xFFF8E7D5));
    }
    if (character == 'owl') {
      oval(167, 243, 66, 55, const Color(0xFFA45C32));
    }
    final hipL = Offset(185, 258), hipR = Offset(216, 258);
    Offset kneeL = const Offset(180, 283),
        kneeR = const Offset(222, 283),
        footL = const Offset(171, 315),
        footR = const Offset(230, 315);
    if (motion == Motion.squat) {
      kneeL = Offset(156, 283);
      kneeR = Offset(244, 283);
      footL = Offset(158, 315 - bob);
      footR = Offset(245, 315 - bob);
    }
    if (motion == Motion.legExtension ||
        motion == Motion.legPress ||
        motion == Motion.legRaise) {
      kneeL = const Offset(170, 280);
      kneeR = const Offset(227, 280);
      footL = Offset(142 - 14 * t, 310 - 48 * t);
      footR = Offset(253 + 14 * t, 310 - 48 * t);
    }
    if (motion == Motion.legCurl || motion == Motion.lyingLegCurl) {
      kneeL = const Offset(173, 280);
      kneeR = const Offset(228, 280);
      footL = Offset(155 + 25 * t, 310 - 23 * t);
      footR = Offset(245 - 25 * t, 310 - 23 * t);
    }
    if (motion == Motion.hipAbduction || motion == Motion.hipAdduction) {
      final v = motion == Motion.hipAdduction ? 1 - t : t;
      kneeL = Offset(178 - 30 * v, 283);
      kneeR = Offset(224 + 30 * v, 283);
      footL = Offset(170 - 35 * v, 315);
      footR = Offset(232 + 35 * v, 315);
    }
    if ([
      Motion.walk,
      Motion.elliptical,
      Motion.cycle,
      Motion.stairs,
      Motion.lunge,
      Motion.rowing,
    ].contains(motion)) {
      final a = phase * 2 * math.pi;
      final stride = motion == Motion.elliptical ? 35.0 : 22.0;
      kneeL = Offset(180 + math.sin(a) * 12, 282 - math.cos(a) * 9);
      kneeR = Offset(222 - math.sin(a) * 12, 282 + math.cos(a) * 9);
      footL = Offset(
        171 + math.sin(a) * stride,
        310 - math.max(0, math.cos(a)) * 23,
      );
      footR = Offset(
        230 - math.sin(a) * stride,
        310 - math.max(0, -math.cos(a)) * 23,
      );
    }
    limb(hipL, kneeL, 24);
    limb(kneeL, footL, 18);
    limb(hipR, kneeR, 24);
    limb(kneeR, footR, 18);
    final footColor = character == 'sheep'
        ? const Color(0xFF60413C)
        : character == 'owl'
        ? const Color(0xFFF0B03B)
        : skin;
    oval(footL.dx - 15, footL.dy - 6, 28, 14, footColor);
    oval(footR.dx - 13, footR.dy - 6, 28, 14, footColor);
    // Body posture: hip hinge and core actions rotate the torso and head, not the apparatus.
    final tilt = switch (motion) {
      Motion.hinge || Motion.backExtension => -.55 * t,
      Motion.hipThrust => -.45 * (1 - t),
      Motion.crunch => .24 * t,
      Motion.plank || Motion.sidePlank => 0.0,
      _ => 0.0,
    };
    c.save();
    c.translate(200, 260);
    c.rotate(tilt);
    c.translate(-200, -260);
    round(188, 148, 25, 43, 10, skin);
    final bodyRect = Rect.fromLTWH(163, 178, 75, 91);
    c.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(31)),
      Paint()
        ..shader = LinearGradient(
          colors: [Color.lerp(skin, Colors.white, .32)!, skin],
        ).createShader(bodyRect),
    );
    if (character == 'aion') {
      final coat = Path()
        ..moveTo(167, 182)
        ..lineTo(191, 188)
        ..lineTo(185, 263)
        ..lineTo(157, 262)
        ..close();
      c.drawPath(coat, Paint()..color = const Color(0xFFFBF7FF));
      final coatR = Path()
        ..moveTo(232, 182)
        ..lineTo(208, 188)
        ..lineTo(214, 263)
        ..lineTo(244, 262)
        ..close();
      c.drawPath(coatR, Paint()..color = const Color(0xFFFBF7FF));
      for (int i = 0; i < 5; i++) {
        round(
          219,
          204 + i * 3,
          13,
          3,
          0,
          [
            cyan,
            const Color(0xFFFFABD0),
            Colors.white,
            const Color(0xFFFFABD0),
            cyan,
          ][i],
        );
      }
      line(const Offset(171, 235), const Offset(182, 235), cyan, 2);
    }
    if (character == 'sheep') {
      for (int i = 0; i < 20; i++) {
        final a = i * 2.4;
        oval(
          192 + math.cos(a) * 27,
          213 + math.sin(a) * 34,
          20,
          19,
          const Color(0xFFFFF2D9),
        );
      }
    }
    if (character == 'owl') {
      oval(177, 186, 47, 71, const Color(0xFFFFE6BF));
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 3; j++) {
          oval(183 + j * 11.0, 200 + i * 12.0, 5, 8, skin);
        }
      }
    }
    if (character == 'wolf') oval(181, 183, 38, 73, const Color(0xFFF7E5D3));
    if (machine && motion == Motion.reverseFly) {
      round(177, 195, 47, 50, 10, pad);
    }
    const shoulderL = Offset(168, 194), shoulderR = Offset(233, 194);
    Offset elbowL = const Offset(152, 226),
        elbowR = const Offset(249, 226),
        handL = const Offset(158, 254),
        handR = const Offset(243, 254);
    switch (motion) {
      case Motion.reverseFly:
      case Motion.fly:
        final v = motion == Motion.fly ? 1 - t : t;
        elbowL = Offset(169 - 49 * v, 192 + 8 * (1 - v));
        elbowR = Offset(231 + 49 * v, 192 + 8 * (1 - v));
        handL = Offset(190 - 89 * v, 196);
        handR = Offset(210 + 89 * v, 196);
      case Motion.lateralRaise:
        elbowL = Offset(154 - 33 * t, 229 - 40 * t);
        elbowR = Offset(247 + 33 * t, 229 - 40 * t);
        handL = Offset(151 - 56 * t, 257 - 70 * t);
        handR = Offset(250 + 56 * t, 257 - 70 * t);
      case Motion.frontRaise:
        elbowL = Offset(171, 229 - 46 * t);
        elbowR = Offset(230, 229 - 46 * t);
        handL = Offset(184, 257 - 101 * t);
        handR = Offset(217, 257 - 101 * t);
      case Motion.overheadTriceps:
        elbowL = const Offset(166, 143);
        elbowR = const Offset(235, 143);
        handL = Offset(185, 126 - 80 * t);
        handR = Offset(216, 126 - 80 * t);
      case Motion.curl:
      case Motion.wrist:
        handL = Offset(151, 255 - 61 * t);
        handR = Offset(250, 255 - 61 * t);
      case Motion.pushdown:
        handL = Offset(174 - 22 * t, 207 + 45 * t);
        handR = Offset(227 + 22 * t, 207 + 45 * t);
      case Motion.press:
        elbowL = Offset(146 + 17 * t, 220 - 15 * t);
        elbowR = Offset(255 - 17 * t, 220 - 15 * t);
        handL = Offset(163 + 24 * t, 195 - 17 * t);
        handR = Offset(238 - 24 * t, 195 - 17 * t);
      case Motion.overhead:
      case Motion.pulldown:
        final v = motion == Motion.pulldown ? 1 - t : t;
        elbowL = Offset(141 + 14 * v, 199 - 47 * v);
        elbowR = Offset(260 - 14 * v, 199 - 47 * v);
        handL = Offset(153 + 14 * v, 173 - 60 * v);
        handR = Offset(248 - 14 * v, 173 - 60 * v);
      case Motion.row:
      case Motion.rowing:
        elbowL = Offset(173 - 35 * t, 220);
        elbowR = Offset(228 + 35 * t, 220);
        handL = Offset(190 - 26 * t, 214 + 21 * t);
        handR = Offset(211 + 26 * t, 214 + 21 * t);
      case Motion.shrug:
        elbowL = Offset(151, 225 - 13 * t);
        elbowR = Offset(250, 225 - 13 * t);
        handL = Offset(151, 253 - 13 * t);
        handR = Offset(250, 253 - 13 * t);
      case Motion.eat:
        elbowL = const Offset(150, 228);
        handL = const Offset(172, 226);
        elbowR = Offset(250 - 10 * t, 225 - 15 * t);
        handR = Offset(234 - 22 * t, 235 - 95 * t);
      case Motion.read:
        handL = const Offset(175, 225);
        handR = const Offset(226, 225);
      case Motion.walk:
      case Motion.elliptical:
      case Motion.stairs:
        final a = math.sin(phase * 2 * math.pi);
        handL = Offset(149 + 16 * a, 253 - 8 * a);
        handR = Offset(252 - 16 * a, 253 + 8 * a);
      case Motion.cycle:
        handL = const Offset(282, 197);
        handR = const Offset(305, 197);
        elbowL = const Offset(215, 210);
        elbowR = const Offset(264, 210);
      default:
        break;
    }
    if (machine &&
        [
          Motion.reverseFly,
          Motion.fly,
          Motion.press,
          Motion.row,
          Motion.pulldown,
          Motion.overhead,
        ].contains(motion)) {
      line(const Offset(120, 120), handL, steel, 5);
      line(const Offset(280, 120), handR, steel, 5);
      line(handL - const Offset(0, 8), handL + const Offset(0, 8), pad, 7);
      line(handR - const Offset(0, 8), handR + const Offset(0, 8), pad, 7);
    }
    limb(shoulderL, elbowL, 22);
    limb(elbowL, handL, 17);
    limb(shoulderR, elbowR, 22);
    limb(elbowR, handR, 17);
    if (character == 'owl') {
      for (final elbow in [elbowL, elbowR]) {
        for (int i = 0; i < 3; i++) {
          oval(
            elbow.dx - 10 + i * 6,
            elbow.dy - 8,
            10,
            23,
            Color.lerp(skin, const Color(0xFFFFD49A), i / 3)!,
          );
        }
      }
    }
    if (character == 'wolf') {
      line(
        shoulderL,
        elbowL,
        const Color(0xFF9F59EF).withValues(alpha: .4),
        14,
      );
      final mark = Path()
        ..moveTo(160, 204)
        ..lineTo(149, 214)
        ..lineTo(160, 215)
        ..lineTo(149, 228);
      c.drawPath(
        mark,
        Paint()
          ..color = const Color(0xFFE0C5FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    if (equipment == Equipment.dumbbell &&
        ![Motion.read, Motion.eat].contains(motion)) {
      for (final hand in [handL, handR]) {
        line(hand - const Offset(11, 0), hand + const Offset(11, 0), steel, 6);
        round(hand.dx - 18, hand.dy - 10, 10, 20, 3, pad);
        round(hand.dx + 8, hand.dy - 10, 10, 20, 3, pad);
      }
    }
    if (equipment == Equipment.barbell) {
      line(handL - const Offset(30, 0), handR + const Offset(30, 0), steel, 6);
      round(handL.dx - 32, handL.dy - 18, 11, 36, 3, pad);
      round(handR.dx + 21, handR.dy - 18, 11, 36, 3, pad);
    }
    // Source atlas contains exactly four transparent head cells, displayed unedited.
    if (atlas != null) {
      final index = companionIds.indexOf(character);
      final w = atlas!.width / 2, h = atlas!.height / 2;
      c.drawImageRect(
        atlas!,
        Rect.fromLTWH((index % 2) * w, (index ~/ 2) * h, w, h),
        const Rect.fromLTWH(87, 20, 226, 151),
        Paint()..filterQuality = FilterQuality.medium,
      );
    } else {
      oval(132, 52, 136, 105, skin);
      oval(161, 95, 15, 20, pad);
      oval(225, 95, 15, 20, pad);
    }
    if (character == 'sheep') {
      c.drawOval(
        const Rect.fromLTWH(167, 22, 67, 13),
        Paint()
          ..color = const Color(0xFFF7C33F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    if (motion == Motion.read) {
      round(174, 211, 52, 37, 3, const Color(0xFFBB8748));
      line(
        const Offset(200, 214),
        const Offset(200, 246),
        const Color(0xFFFFE7AD),
        2,
      );
    }
    if (motion == Motion.eat) {
      oval(143, 224, 49, 26, const Color(0xFFC7B4E6));
      for (final o in [
        const Offset(155, 225),
        const Offset(167, 221),
        const Offset(179, 226),
        handR,
      ]) {
        oval(o.dx - 5, o.dy - 5, 11, 11, const Color(0xFF5066A4));
        oval(o.dx - 1, o.dy - 3, 3, 3, const Color(0xFFBCC9ED));
      }
    }
    c.restore();
    c.restore();
    c.restore();
  }

  @override
  bool shouldRepaint(CompanionPainter old) =>
      old.character != character ||
      old.motion != motion ||
      old.equipment != equipment ||
      old.phase != phase ||
      old.atlas != atlas ||
      old.exerciseId != exerciseId;
}
