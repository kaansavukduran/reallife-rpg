import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../domain/fitness.dart';

final _images = <String, Future<ui.Image>>{};
Future<ui.Image> _load(String file) => _images.putIfAbsent(file, () async {
  final data = await rootBundle.load('assets/companions/$file.png');
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
});

class CompanionSprites {
  const CompanionSprites(this.actions, this.pet);
  final ui.Image actions;
  final ui.Image? pet;
}

final _sheets = <String, Future<CompanionSprites>>{};
Future<CompanionSprites> loadCompanionSprites(String character) =>
    _sheets.putIfAbsent(character, () async {
      final images = await Future.wait([
        _load('${character}_actions'),
        if (character == 'aion') _load('aion_pet'),
      ]);
      return CompanionSprites(
        images.first,
        images.length > 1 ? images.last : null,
      );
    });

bool hasActivityFrames(Motion motion, [Equipment? equipment]) {
  if (motion == Motion.curl &&
      equipment != null &&
      equipment != Equipment.dumbbell) {
    return false;
  }
  if (motion == Motion.reverseFly &&
      equipment != null &&
      equipment != Equipment.machine) {
    return false;
  }
  return const {
    Motion.idle,
    Motion.read,
    Motion.eat,
    Motion.curl,
    Motion.reverseFly,
  }.contains(motion);
}

class CompanionFrame {
  const CompanionFrame(
    this.image,
    this.source,
    this.index,
    this.count,
    this.clip,
  );
  final ui.Image image;
  final ui.Rect source;
  final int index, count;
  final String clip;
}

/// Whole drawings only. Each source cell has the same fixed ground anchor;
/// pointer tracking selects a drawn direction and never translates the body.
CompanionFrame companionFrame({
  required CompanionSprites sprites,
  required Motion motion,
  required double phase,
  ui.Offset look = ui.Offset.zero,
  String reaction = '',
  double reactionPhase = 1,
  String mood = 'happy',
}) {
  final pet = sprites.pet;
  var image = sprites.actions;
  var columns = 4, rows = 8, row = 0, count = 4;
  var clip = hasActivityFrames(motion) ? motion.name : 'idle';
  var progress = phase;
  int? fixed;
  if (reaction.isNotEmpty && reactionPhase < 1) {
    row = 1;
    clip = 'reaction';
    progress = reactionPhase;
    if (pet != null) {
      image = pet;
      columns = 8;
      rows = 11;
      row = reaction == 'feet' ? 4 : 3;
      count = reaction == 'feet' ? 5 : 4;
    }
  } else if (look.distance > .15) {
    clip = 'look';
    if (pet != null) {
      image = pet;
      columns = 8;
      rows = 11;
      final direction =
          (((math.atan2(look.dy, look.dx) + math.pi / 2) / (2 * math.pi) * 16)
              .round()) %
          16;
      row = 9 + direction ~/ 8;
      fixed = direction % 8;
      count = 8;
    } else {
      final direction =
          ((math.atan2(look.dy, look.dx) / (math.pi / 4)).round() + 4) % 8;
      row = 6 + direction ~/ 4;
      fixed = direction % 4;
    }
  } else if (motion == Motion.idle && mood != 'happy') {
    clip = mood;
    if (mood == 'sad') {
      row = 7;
      fixed = 2;
    } else {
      fixed = 1;
    }
  } else if (pet != null && (motion == Motion.idle || motion == Motion.read)) {
    image = pet;
    columns = 8;
    rows = 11;
    row = motion == Motion.read ? 8 : 0;
    count = 6;
  } else {
    row = switch (motion) {
      Motion.read => 2,
      Motion.eat => 3,
      Motion.curl => 4,
      Motion.reverseFly => 5,
      _ => 0,
    };
  }
  final index =
      fixed ?? (progress.clamp(0, 1) * count).floor().clamp(0, count - 1);
  final width = image.width / columns, height = image.height / rows;
  return CompanionFrame(
    image,
    ui.Rect.fromLTWH(index * width, row * height, width, height).deflate(.5),
    index,
    count,
    clip,
  );
}
