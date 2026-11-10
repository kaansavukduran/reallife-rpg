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
  const CompanionSprites(
    this.actions,
    this.pet, {
    this.chestPress,
    this.benchPress,
    this.inclinePress,
    this.characterRow = 0,
  });
  final ui.Image actions;
  final ui.Image? pet;
  final ui.Image? chestPress;
  final ui.Image? benchPress;
  final ui.Image? inclinePress;
  final int characterRow;
}

final _sheets = <String, Future<CompanionSprites>>{};
Future<CompanionSprites> loadCompanionSprites(
  String character, {
  bool includeChestPress = false,
  bool includeBenchPress = false,
  bool includeInclinePress = false,
}) => _sheets.putIfAbsent(
  '$character/$includeChestPress/$includeBenchPress/$includeInclinePress',
  () async {
    final images = await Future.wait<ui.Image?>([
      _load('${character}_actions'),
      character == 'aion' ? _load('aion_pet') : Future.value(),
      includeChestPress ? _load('chest_press') : Future.value(),
      includeBenchPress ? _load('bench_press') : Future.value(),
      includeInclinePress ? _load('incline_press') : Future.value(),
    ]);
    return CompanionSprites(
      images[0]!,
      images[1],
      chestPress: images[2],
      benchPress: images[3],
      inclinePress: images[4],
      characterRow: const ['aion', 'sheep', 'wolf', 'owl'].indexOf(character),
    );
  },
);

bool isChestPressClip(Motion motion, Equipment? equipment, String exerciseId) =>
    motion == Motion.press &&
    equipment == Equipment.machine &&
    exerciseId == 'chest_press';

bool isBenchPressClip(Motion motion, Equipment? equipment, String exerciseId) =>
    motion == Motion.press &&
    equipment == Equipment.barbell &&
    exerciseId == 'bench_press';

bool isInclinePressClip(
  Motion motion,
  Equipment? equipment,
  String exerciseId,
) =>
    motion == Motion.press &&
    equipment == Equipment.dumbbell &&
    exerciseId == 'incline_press';

int activityFrameCount(
  String character,
  Motion motion,
  Equipment equipment,
  String exerciseId,
) {
  if (isChestPressClip(motion, equipment, exerciseId) ||
      isBenchPressClip(motion, equipment, exerciseId) ||
      isInclinePressClip(motion, equipment, exerciseId)) {
    return 8;
  }
  final effective = hasActivityFrames(motion, equipment, exerciseId)
      ? motion
      : Motion.idle;
  return character == 'aion' &&
          (effective == Motion.idle || effective == Motion.read)
      ? 6
      : 4;
}

bool hasActivityFrames(
  Motion motion, [
  Equipment? equipment,
  String exerciseId = '',
]) {
  if (isChestPressClip(motion, equipment, exerciseId) ||
      isBenchPressClip(motion, equipment, exerciseId) ||
      isInclinePressClip(motion, equipment, exerciseId)) {
    return true;
  }
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
  Equipment? equipment,
  String exerciseId = '',
  ui.Offset look = ui.Offset.zero,
  String reaction = '',
  double reactionPhase = 1,
  String mood = 'happy',
}) {
  final pet = sprites.pet;
  var image = sprites.actions;
  var columns = 4, rows = 8, row = 0, count = 4;
  var clip = hasActivityFrames(motion, equipment, exerciseId)
      ? motion.name
      : 'idle';
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
  } else if (isChestPressClip(motion, equipment, exerciseId) &&
      sprites.chestPress != null) {
    image = sprites.chestPress!;
    columns = 8;
    rows = 4;
    row = sprites.characterRow;
    count = 8;
    clip = 'chest_press';
  } else if (isBenchPressClip(motion, equipment, exerciseId) &&
      sprites.benchPress != null) {
    image = sprites.benchPress!;
    columns = 4;
    rows = 8;
    count = 8;
    clip = 'bench_press';
  } else if (isInclinePressClip(motion, equipment, exerciseId) &&
      sprites.inclinePress != null) {
    image = sprites.inclinePress!;
    columns = 8;
    rows = 4;
    row = sprites.characterRow;
    count = 8;
    clip = 'incline_press';
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
  var column = index;
  if (clip == 'bench_press') {
    row = sprites.characterRow * 2 + index ~/ 4;
    column = index % 4;
  }
  return CompanionFrame(
    image,
    ui.Rect.fromLTWH(column * width, row * height, width, height).deflate(.5),
    index,
    count,
    clip,
  );
}
