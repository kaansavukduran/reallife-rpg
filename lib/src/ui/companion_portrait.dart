import 'dart:math' as math;
import 'dart:ui';

/// Measured sprite boundaries in the unmodified 1254×1254 expression atlas.
/// Its painted rows are not a uniform grid: a grid crop includes neighbouring
/// ears/wool and places the chin differently for each expression.
class CompanionPortrait {
  const CompanionPortrait(this.source, this.chin, this.eyes);
  final Rect source;
  final Offset chin;
  final List<Rect> eyes;

  static const socket = Offset(200, 184);

  Rect fittedToSocket({Offset at = socket, Size limit = const Size(226, 174)}) {
    final scale = math.min(
      limit.width / source.width,
      limit.height / source.height,
    );
    return Rect.fromLTWH(
      at.dx - (chin.dx - source.left) * scale,
      at.dy - (chin.dy - source.top) * scale,
      source.width * scale,
      source.height * scale,
    );
  }

  Rect mapSourceRect(Rect rect, Rect destination) {
    final scale = destination.width / source.width;
    return Rect.fromLTWH(
      destination.left + (rect.left - source.left) * scale,
      destination.top + (rect.top - source.top) * scale,
      rect.width * scale,
      rect.height * scale,
    );
  }
}

CompanionPortrait portraitFor(String character, String mood) =>
    _portraits[character]?[_expression(mood)] ??
    _portraits['aion']![_expression(mood)]!;
String _expression(String mood) =>
    mood == 'sad' || mood == 'neutral' ? mood : 'happy';

const _portraits = <String, Map<String, CompanionPortrait>>{
  'aion': {
    'happy': CompanionPortrait(
      Rect.fromLTRB(33, 17, 427, 271),
      Offset(235, 264),
      [Rect.fromLTRB(145, 151, 193, 199), Rect.fromLTRB(279, 151, 326, 198)],
    ),
    'neutral': CompanionPortrait(
      Rect.fromLTRB(430, 17, 823, 271),
      Offset(628, 264),
      [Rect.fromLTRB(539, 152, 586, 201), Rect.fromLTRB(672, 152, 718, 201)],
    ),
    'sad': CompanionPortrait(
      Rect.fromLTRB(826, 17, 1218, 271),
      Offset(1024, 264),
      [Rect.fromLTRB(934, 155, 980, 202), Rect.fromLTRB(1065, 156, 1112, 203)],
    ),
  },
  'sheep': {
    'happy': CompanionPortrait(
      Rect.fromLTRB(28, 291, 425, 567),
      Offset(235, 557),
      [Rect.fromLTRB(143, 426, 192, 468), Rect.fromLTRB(269, 426, 317, 468)],
    ),
    'neutral': CompanionPortrait(
      Rect.fromLTRB(432, 291, 821, 566),
      Offset(628, 558),
      [Rect.fromLTRB(541, 428, 589, 472), Rect.fromLTRB(665, 428, 713, 468)],
    ),
    'sad': CompanionPortrait(
      Rect.fromLTRB(829, 290, 1225, 566),
      Offset(1024, 559),
      [Rect.fromLTRB(939, 432, 989, 477), Rect.fromLTRB(1065, 431, 1116, 473)],
    ),
  },
  'wolf': {
    'happy': CompanionPortrait(
      Rect.fromLTRB(48, 575, 410, 866),
      Offset(235, 856),
      [Rect.fromLTRB(145, 741, 202, 790), Rect.fromLTRB(274, 742, 330, 790)],
    ),
    'neutral': CompanionPortrait(
      Rect.fromLTRB(448, 576, 807, 866),
      Offset(635, 857),
      [Rect.fromLTRB(541, 744, 599, 792), Rect.fromLTRB(672, 744, 730, 792)],
    ),
    'sad': CompanionPortrait(
      Rect.fromLTRB(844, 577, 1207, 867),
      Offset(1030, 858),
      [Rect.fromLTRB(938, 745, 996, 793), Rect.fromLTRB(1068, 745, 1125, 793)],
    ),
  },
  'owl': {
    'happy': CompanionPortrait(
      Rect.fromLTRB(51, 876, 412, 1186),
      Offset(235, 1177),
      [
        Rect.fromLTRB(126, 1036, 195, 1090),
        Rect.fromLTRB(276, 1036, 339, 1085),
      ],
    ),
    'neutral': CompanionPortrait(
      Rect.fromLTRB(449, 875, 805, 1186),
      Offset(629, 1177),
      [
        Rect.fromLTRB(522, 1037, 589, 1087),
        Rect.fromLTRB(671, 1037, 733, 1094),
      ],
    ),
    'sad': CompanionPortrait(
      Rect.fromLTRB(843, 876, 1203, 1187),
      Offset(1024, 1178),
      [
        Rect.fromLTRB(916, 1044, 984, 1098),
        Rect.fromLTRB(1065, 1044, 1130, 1094),
      ],
    ),
  },
};
