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
    this.pushUp,
    this.pecDeck,
    this.cableFly,
    this.reverseDumbbellFly,
    this.facePull,
    this.shoulderPress,
    this.shoulderDumbbell,
    this.barbellOverhead,
    this.lateralMachine,
    this.lateralDumbbell,
    this.lateralCable,
    this.frontRaise,
    this.latPulldown,
    this.pullUp,
    this.assistedPullUp,
    this.cableRow,
    this.characterRow = 0,
  });
  final ui.Image actions;
  final ui.Image? pet;
  final ui.Image? chestPress;
  final ui.Image? benchPress;
  final ui.Image? inclinePress;
  final ui.Image? pushUp;
  final ui.Image? pecDeck;
  final ui.Image? cableFly;
  final ui.Image? reverseDumbbellFly;
  final ui.Image? facePull;
  final ui.Image? shoulderPress;
  final ui.Image? shoulderDumbbell;
  final ui.Image? barbellOverhead;
  final ui.Image? lateralMachine;
  final ui.Image? lateralDumbbell;
  final ui.Image? lateralCable;
  final ui.Image? frontRaise;
  final ui.Image? latPulldown;
  final ui.Image? pullUp;
  final ui.Image? assistedPullUp;
  final ui.Image? cableRow;
  final int characterRow;
}

final _sheets = <String, Future<CompanionSprites>>{};
Future<CompanionSprites> loadCompanionSprites(
  String character, {
  bool includeChestPress = false,
  bool includeBenchPress = false,
  bool includeInclinePress = false,
  bool includePushUp = false,
  bool includePecDeck = false,
  bool includeCableFly = false,
  bool includeReverseDumbbellFly = false,
  bool includeFacePull = false,
  bool includeShoulderPress = false,
  bool includeShoulderDumbbell = false,
  bool includeBarbellOverhead = false,
  bool includeLateralMachine = false,
  bool includeLateralDumbbell = false,
  bool includeLateralCable = false,
  bool includeFrontRaise = false,
  bool includeLatPulldown = false,
  bool includePullUp = false,
  bool includeAssistedPullUp = false,
  bool includeCableRow = false,
}) => _sheets.putIfAbsent(
  '$character/$includeChestPress/$includeBenchPress/$includeInclinePress/$includePushUp/$includePecDeck/$includeCableFly/$includeReverseDumbbellFly/$includeFacePull/$includeShoulderPress/$includeShoulderDumbbell/$includeBarbellOverhead/$includeLateralMachine/$includeLateralDumbbell/$includeLateralCable/$includeFrontRaise/$includeLatPulldown/$includePullUp/$includeAssistedPullUp/$includeCableRow',
  () async {
    final images = await Future.wait<ui.Image?>([
      _load('${character}_actions'),
      character == 'aion' ? _load('aion_pet') : Future.value(),
      includeChestPress ? _load('chest_press') : Future.value(),
      includeBenchPress ? _load('bench_press') : Future.value(),
      includeInclinePress ? _load('incline_press') : Future.value(),
      includePushUp ? _load('${character}_push_up') : Future.value(),
      includePecDeck ? _load('${character}_pec_deck') : Future.value(),
      includeCableFly ? _load('${character}_cable_fly') : Future.value(),
      includeReverseDumbbellFly
          ? _load('${character}_reverse_dumbbell_fly')
          : Future.value(),
      includeFacePull ? _load('${character}_face_pull') : Future.value(),
      includeShoulderPress
          ? _load('${character}_shoulder_press')
          : Future.value(),
      includeShoulderDumbbell
          ? _load('${character}_shoulder_dumbbell')
          : Future.value(),
      includeBarbellOverhead
          ? _load('${character}_overhead_barbell')
          : Future.value(),
      includeLateralMachine
          ? _load('${character}_lateral_machine')
          : Future.value(),
      includeLateralDumbbell
          ? _load('${character}_lateral_dumbbell')
          : Future.value(),
      includeLateralCable
          ? _load('${character}_lateral_cable')
          : Future.value(),
      includeFrontRaise ? _load('${character}_front_raise') : Future.value(),
      includeLatPulldown ? _load('${character}_lat_pulldown') : Future.value(),
      includePullUp ? _load('${character}_pull_up') : Future.value(),
      includeAssistedPullUp
          ? _load('${character}_assisted_pull_up')
          : Future.value(),
      includeCableRow ? _load('${character}_cable_row') : Future.value(),
    ]);
    return CompanionSprites(
      images[0]!,
      images[1],
      chestPress: images[2],
      benchPress: images[3],
      inclinePress: images[4],
      pushUp: images[5],
      pecDeck: images[6],
      cableFly: images[7],
      reverseDumbbellFly: images[8],
      facePull: images[9],
      shoulderPress: images[10],
      shoulderDumbbell: images[11],
      barbellOverhead: images[12],
      lateralMachine: images[13],
      lateralDumbbell: images[14],
      lateralCable: images[15],
      frontRaise: images[16],
      latPulldown: images[17],
      pullUp: images[18],
      assistedPullUp: images[19],
      cableRow: images[20],
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

bool isPushUpClip(Motion motion, Equipment? equipment, String exerciseId) =>
    motion == Motion.press &&
    equipment == Equipment.bodyweight &&
    exerciseId == 'push_up';

bool isPecDeckClip(Motion motion, Equipment? equipment, String exerciseId) =>
    motion == Motion.fly &&
    equipment == Equipment.machine &&
    exerciseId == 'pec_deck';

bool isCableFlyClip(Motion motion, Equipment? equipment, String exerciseId) =>
    motion == Motion.fly &&
    equipment == Equipment.cable &&
    exerciseId == 'cable_fly';

bool isReverseDumbbellFlyClip(
  Motion motion,
  Equipment? equipment,
  String exerciseId,
) =>
    motion == Motion.reverseFly &&
    equipment == Equipment.dumbbell &&
    exerciseId == 'reverse_dumbbell_fly';

bool isFacePullClip(Motion motion, Equipment? equipment, String exerciseId) =>
    motion == Motion.reverseFly &&
    equipment == Equipment.cable &&
    exerciseId == 'face_pull';

bool isShoulderPressClip(
  Motion motion,
  Equipment? equipment,
  String exerciseId,
) =>
    motion == Motion.overhead &&
    equipment == Equipment.machine &&
    exerciseId == 'shoulder_press';

bool isShoulderDumbbellClip(
  Motion motion,
  Equipment? equipment,
  String exerciseId,
) =>
    motion == Motion.overhead &&
    equipment == Equipment.dumbbell &&
    exerciseId == 'shoulder_dumbbell';

bool isBarbellOverheadClip(
  Motion motion,
  Equipment? equipment,
  String exerciseId,
) =>
    motion == Motion.overhead &&
    equipment == Equipment.barbell &&
    exerciseId == 'overhead_barbell';

bool isLateralMachineClip(
  Motion motion,
  Equipment? equipment,
  String exerciseId,
) =>
    motion == Motion.lateralRaise &&
    equipment == Equipment.machine &&
    exerciseId == 'lateral_machine';

bool isLateralDumbbellClip(
  Motion motion,
  Equipment? equipment,
  String exerciseId,
) =>
    motion == Motion.lateralRaise &&
    equipment == Equipment.dumbbell &&
    exerciseId == 'lateral_dumbbell';

bool isLateralCableClip(
  Motion motion,
  Equipment? equipment,
  String exerciseId,
) =>
    motion == Motion.lateralRaise &&
    equipment == Equipment.cable &&
    exerciseId == 'lateral_cable';

bool isFrontRaiseClip(Motion motion, Equipment? equipment, String exerciseId) =>
    motion == Motion.frontRaise &&
    equipment == Equipment.dumbbell &&
    exerciseId == 'front_raise';

bool isLatPulldownClip(
  Motion motion,
  Equipment? equipment,
  String exerciseId,
) =>
    motion == Motion.pulldown &&
    equipment == Equipment.machine &&
    exerciseId == 'lat_pulldown';

bool isPullUpClip(Motion motion, Equipment? equipment, String exerciseId) =>
    motion == Motion.pulldown &&
    equipment == Equipment.bodyweight &&
    exerciseId == 'pull_up';

bool isAssistedPullUpClip(
  Motion motion,
  Equipment? equipment,
  String exerciseId,
) =>
    motion == Motion.pulldown &&
    equipment == Equipment.machine &&
    exerciseId == 'assisted_pull_up';

bool isCableRowClip(Motion motion, Equipment? equipment, String exerciseId) =>
    motion == Motion.row &&
    equipment == Equipment.cable &&
    exerciseId == 'cable_row';

int activityFrameCount(
  String character,
  Motion motion,
  Equipment equipment,
  String exerciseId,
) {
  // Aion uses its second drawing once more on the way down. This closes the
  // loop without a larger jump than the first upward step; no body is shifted.
  if (character == 'aion' && isPullUpClip(motion, equipment, exerciseId)) {
    return 9;
  }
  if (isChestPressClip(motion, equipment, exerciseId) ||
      isBenchPressClip(motion, equipment, exerciseId) ||
      isInclinePressClip(motion, equipment, exerciseId) ||
      isPushUpClip(motion, equipment, exerciseId) ||
      isPecDeckClip(motion, equipment, exerciseId) ||
      isCableFlyClip(motion, equipment, exerciseId) ||
      isReverseDumbbellFlyClip(motion, equipment, exerciseId) ||
      isFacePullClip(motion, equipment, exerciseId) ||
      isShoulderPressClip(motion, equipment, exerciseId) ||
      isShoulderDumbbellClip(motion, equipment, exerciseId) ||
      isBarbellOverheadClip(motion, equipment, exerciseId) ||
      isLateralMachineClip(motion, equipment, exerciseId) ||
      isLateralDumbbellClip(motion, equipment, exerciseId) ||
      isLateralCableClip(motion, equipment, exerciseId) ||
      isFrontRaiseClip(motion, equipment, exerciseId) ||
      isLatPulldownClip(motion, equipment, exerciseId) ||
      isPullUpClip(motion, equipment, exerciseId) ||
      isAssistedPullUpClip(motion, equipment, exerciseId) ||
      isCableRowClip(motion, equipment, exerciseId)) {
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
      isInclinePressClip(motion, equipment, exerciseId) ||
      isPushUpClip(motion, equipment, exerciseId) ||
      isPecDeckClip(motion, equipment, exerciseId) ||
      isCableFlyClip(motion, equipment, exerciseId) ||
      isReverseDumbbellFlyClip(motion, equipment, exerciseId) ||
      isFacePullClip(motion, equipment, exerciseId) ||
      isShoulderPressClip(motion, equipment, exerciseId) ||
      isShoulderDumbbellClip(motion, equipment, exerciseId) ||
      isBarbellOverheadClip(motion, equipment, exerciseId) ||
      isLateralMachineClip(motion, equipment, exerciseId) ||
      isLateralDumbbellClip(motion, equipment, exerciseId) ||
      isLateralCableClip(motion, equipment, exerciseId) ||
      isFrontRaiseClip(motion, equipment, exerciseId) ||
      isLatPulldownClip(motion, equipment, exerciseId) ||
      isPullUpClip(motion, equipment, exerciseId) ||
      isAssistedPullUpClip(motion, equipment, exerciseId) ||
      isCableRowClip(motion, equipment, exerciseId)) {
    return true;
  }
  if (exerciseId == 'reverse_dumbbell_fly' ||
      exerciseId == 'face_pull' ||
      exerciseId == 'shoulder_press' ||
      exerciseId == 'shoulder_dumbbell' ||
      exerciseId == 'overhead_barbell' ||
      exerciseId == 'lateral_machine' ||
      exerciseId == 'lateral_dumbbell' ||
      exerciseId == 'lateral_cable' ||
      exerciseId == 'front_raise' ||
      exerciseId == 'lat_pulldown' ||
      exerciseId == 'pull_up' ||
      exerciseId == 'assisted_pull_up' ||
      exerciseId == 'cable_row') {
    return false;
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

// Authoring registration for the four 1774×887 barbell atlases. Only transparent
// padding is trimmed: every 443.5×400 window stays inside its original cell,
// with the drawn soles at y=390. The destination never moves between poses.
const _barbellTopInsets = <List<double>>[
  [14.5, 14.5, 14.5, 14.5, 22, 22, 22, 22],
  [18.5, 18.5, 18.5, 18.5, 20, 20, 19, 20],
  [39.5, 39.5, 39.5, 39.5, 18, 19, 18, 18],
  [18.5, 18.5, 18.5, 18.5, 18, 18, 18, 18],
];

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
  // Dedicated clips must never fall through to the generic machine row.
  if ((exerciseId == 'reverse_dumbbell_fly' &&
          sprites.reverseDumbbellFly == null) ||
      (exerciseId == 'face_pull' && sprites.facePull == null) ||
      (exerciseId == 'shoulder_press' && sprites.shoulderPress == null) ||
      (exerciseId == 'shoulder_dumbbell' && sprites.shoulderDumbbell == null) ||
      (exerciseId == 'overhead_barbell' && sprites.barbellOverhead == null) ||
      (exerciseId == 'lateral_machine' && sprites.lateralMachine == null) ||
      (exerciseId == 'lateral_dumbbell' && sprites.lateralDumbbell == null) ||
      (exerciseId == 'lateral_cable' && sprites.lateralCable == null) ||
      (exerciseId == 'front_raise' && sprites.frontRaise == null) ||
      (exerciseId == 'lat_pulldown' && sprites.latPulldown == null) ||
      (exerciseId == 'pull_up' && sprites.pullUp == null) ||
      (exerciseId == 'assisted_pull_up' && sprites.assistedPullUp == null) ||
      (exerciseId == 'cable_row' && sprites.cableRow == null)) {
    clip = 'idle';
  }
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
  } else if (isPushUpClip(motion, equipment, exerciseId) &&
      sprites.pushUp != null) {
    image = sprites.pushUp!;
    columns = 4;
    rows = 2;
    row = (phase.clamp(0, 1) * 8).floor().clamp(0, 7) ~/ 4;
    count = 8;
    clip = 'push_up';
  } else if (isPecDeckClip(motion, equipment, exerciseId) &&
      sprites.pecDeck != null) {
    image = sprites.pecDeck!;
    columns = 4;
    rows = 2;
    count = 8;
    clip = 'pec_deck';
  } else if (isCableFlyClip(motion, equipment, exerciseId) &&
      sprites.cableFly != null) {
    image = sprites.cableFly!;
    columns = 4;
    rows = 2;
    count = 8;
    clip = 'cable_fly';
  } else if (isReverseDumbbellFlyClip(motion, equipment, exerciseId) &&
      sprites.reverseDumbbellFly != null) {
    image = sprites.reverseDumbbellFly!;
    columns = 4;
    rows = 2;
    count = 8;
    clip = 'reverse_dumbbell_fly';
  } else if (isFacePullClip(motion, equipment, exerciseId) &&
      sprites.facePull != null) {
    image = sprites.facePull!;
    columns = 4;
    rows = 2;
    count = 8;
    clip = 'face_pull';
  } else if (isShoulderPressClip(motion, equipment, exerciseId) &&
      sprites.shoulderPress != null) {
    image = sprites.shoulderPress!;
    columns = 4;
    rows = 2;
    count = 8;
    clip = 'shoulder_press';
  } else if (isShoulderDumbbellClip(motion, equipment, exerciseId) &&
      sprites.shoulderDumbbell != null) {
    image = sprites.shoulderDumbbell!;
    columns = 4;
    rows = 2;
    count = 8;
    clip = 'shoulder_dumbbell';
  } else if (isBarbellOverheadClip(motion, equipment, exerciseId) &&
      sprites.barbellOverhead != null) {
    image = sprites.barbellOverhead!;
    columns = 4;
    rows = 2;
    count = 8;
    clip = 'overhead_barbell';
  } else if (isLateralMachineClip(motion, equipment, exerciseId) &&
      sprites.lateralMachine != null) {
    image = sprites.lateralMachine!;
    columns = 4;
    rows = 2;
    count = 8;
    clip = 'lateral_machine';
  } else if (isLateralDumbbellClip(motion, equipment, exerciseId) &&
      sprites.lateralDumbbell != null) {
    image = sprites.lateralDumbbell!;
    columns = 4;
    rows = 2;
    count = 8;
    clip = 'lateral_dumbbell';
  } else if (isLateralCableClip(motion, equipment, exerciseId) &&
      sprites.lateralCable != null) {
    image = sprites.lateralCable!;
    columns = 4;
    rows = 2;
    count = 8;
    clip = 'lateral_cable';
  } else if (isFrontRaiseClip(motion, equipment, exerciseId) &&
      sprites.frontRaise != null) {
    image = sprites.frontRaise!;
    columns = 4;
    rows = 2;
    count = 8;
    clip = 'front_raise';
  } else if (isLatPulldownClip(motion, equipment, exerciseId) &&
      sprites.latPulldown != null) {
    image = sprites.latPulldown!;
    columns = 4;
    rows = 2;
    count = 8;
    clip = 'lat_pulldown';
  } else if (isPullUpClip(motion, equipment, exerciseId) &&
      sprites.pullUp != null) {
    image = sprites.pullUp!;
    columns = 4;
    rows = 2;
    count = sprites.characterRow == 0 ? 9 : 8;
    clip = 'pull_up';
  } else if (isAssistedPullUpClip(motion, equipment, exerciseId) &&
      sprites.assistedPullUp != null) {
    image = sprites.assistedPullUp!;
    columns = 4;
    rows = 2;
    count = 8;
    clip = 'assisted_pull_up';
  } else if (isCableRowClip(motion, equipment, exerciseId) &&
      sprites.cableRow != null) {
    image = sprites.cableRow!;
    columns = 4;
    rows = 2;
    count = 8;
    clip = 'cable_row';
  } else if (motion == Motion.idle && mood != 'happy') {
    clip = mood;
    if (mood == 'sad') {
      row = 7;
      fixed = 2;
    } else {
      fixed = 1;
    }
  } else if (pet != null && (clip == 'idle' || motion == Motion.read)) {
    image = pet;
    columns = 8;
    rows = 11;
    // A rejected exercise/family pair may still carry Motion.read. Honor its
    // resolved idle clip rather than borrowing Aion's reading row.
    row = clip == 'idle' ? 0 : 8;
    count = 6;
  } else {
    row = switch (clip == 'idle' ? Motion.idle : motion) {
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
  if (clip == 'push_up' ||
      clip == 'pec_deck' ||
      clip == 'cable_fly' ||
      clip == 'reverse_dumbbell_fly' ||
      clip == 'face_pull' ||
      clip == 'shoulder_press' ||
      clip == 'shoulder_dumbbell' ||
      clip == 'overhead_barbell' ||
      clip == 'lateral_machine' ||
      clip == 'lateral_dumbbell' ||
      clip == 'lateral_cable' ||
      clip == 'front_raise' ||
      clip == 'lat_pulldown' ||
      clip == 'pull_up' ||
      clip == 'assisted_pull_up' ||
      clip == 'cable_row') {
    final drawing = clip == 'pull_up' && index == 8 ? 1 : index;
    row = drawing ~/ 4;
    column = drawing % 4;
  }
  if (clip == 'bench_press') {
    row = sprites.characterRow * 2 + index ~/ 4;
    column = index % 4;
  }
  var sourceLeft = column * width;
  var sourceWidth = width;
  var sourceTop = row * height;
  var sourceHeight = height;
  if (clip == 'overhead_barbell') {
    sourceTop += _barbellTopInsets[sprites.characterRow.clamp(0, 3)][index];
    sourceHeight = 400;
  }
  // Authoring registration trims transparent padding only. The final Aion
  // atlas has a taller grid; sheep's second row has seven fewer top pixels.
  // Keep the complete drawing and a fixed destination; never slide body parts.
  if (clip == 'front_raise' && sprites.characterRow == 0) {
    sourceLeft += 10;
    sourceTop += 90;
    sourceWidth = 400;
    sourceHeight = 330;
  } else if (clip == 'front_raise' && sprites.characterRow == 1) {
    const lefts = [20.0, 15.0, 16.0, 16.0, 21.0, 18.0, 19.0, 18.0];
    sourceLeft += lefts[index];
    sourceTop += index < 4 ? 20 : 13;
    sourceWidth = 410;
    sourceHeight = 410;
  }
  if (clip == 'pull_up' && sprites.characterRow == 3) {
    // Align the owl's fixed rack by trimming transparent source padding only.
    // Keep the whole drawing and the same destination; the body is not moved.
    const lefts = [27.0, 22.0, 20.0, 15.0, 27.0, 22.0, 20.0, 15.0];
    sourceLeft += lefts[index];
    sourceTop += index < 4 ? 12 : 8;
    sourceWidth = 400;
    sourceHeight = 420;
  }
  if (clip == 'assisted_pull_up' && sprites.characterRow == 1) {
    // Trim only transparent padding to align the sheep's stationary machine.
    // All drawn body/support movement remains inside the complete source pose.
    const lefts = [31.0, 26.0, 22.0, 20.0, 30.0, 26.0, 23.0, 21.0];
    const tops = [20.0, 20.0, 20.0, 20.0, 16.0, 16.0, 15.0, 15.0];
    sourceLeft += lefts[index];
    sourceTop += tops[index];
    sourceWidth = 340;
    sourceHeight = 490;
  }
  return CompanionFrame(
    image,
    ui.Rect.fromLTWH(
      sourceLeft,
      sourceTop,
      sourceWidth,
      sourceHeight,
    ).deflate(.5),
    index,
    count,
    clip,
  );
}
