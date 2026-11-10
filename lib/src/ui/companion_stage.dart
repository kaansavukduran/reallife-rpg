import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/fitness.dart';
import '../l10n/strings.dart';
import 'pointer_scope.dart';
import 'companion_sprites.dart';

const companionIds = ['aion', 'sheep', 'wolf', 'owl'];
String companionId(String id) => companionIds.contains(id) ? id : 'aion';
Future<ui.Image>? _moods;
Future<ui.Image> loadMoodAtlas() =>
    _moods ??= rootBundle.load('assets/companions/moods.png').then((b) async {
      final codec = await ui.instantiateImageCodec(b.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    });

/// Plays complete cartoon drawings from a local atlas. No cosmetic XP.
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
    this.interactive = false,
    this.mood = 'happy',
  });
  final String character;
  final String exerciseId;
  final Motion motion;
  final Equipment equipment;
  final double height;
  final bool controls, autoplay;
  final bool interactive;
  final String mood;
  @override
  State<CompanionStage> createState() => _CompanionStageState();
}

class _CompanionStageState extends State<CompanionStage>
    with TickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  late final AnimationController _reaction = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  final stageKey = GlobalKey();
  String reaction = '';
  String caption = '';
  void react(Offset local, Size size) {
    final x = local.dx / size.width, y = local.dy / size.height;
    final part = y < .55
        ? 'head'
        : y > .86
        ? 'feet'
        : x < .27 || x > .73
        ? 'tail'
        : 'belly';
    setState(() {
      reaction = part;
      caption = context.s('pet.$part');
    });
    if (!_reduced) _reaction.forward(from: 0);
  }

  Timer? _frames;
  int _frameStep = 0;
  bool _initialized = false;
  void _startFrames() {
    _frames?.cancel();
    final delay = widget.motion == Motion.read
        ? 320
        : widget.motion == Motion.idle
        ? 240
        : 200;
    _frames = Timer.periodic(Duration(milliseconds: delay), (_) {
      final count = activityFrameCount(
        widget.character,
        widget.motion,
        widget.equipment,
        widget.exerciseId,
      );
      _clock.value = (++_frameStep % count) / count;
    });
    _playing = true;
  }

  bool _playing = false;
  late final FocusNode _phaseFocus = FocusNode(
    onKeyEvent: (node, event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
        return KeyEventResult.ignored;
      }
      if (event.logicalKey == LogicalKeyboardKey.home ||
          event.logicalKey == LogicalKeyboardKey.end) {
        _setPhase(event.logicalKey == LogicalKeyboardKey.home ? 0 : 1);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
  );
  void _setPhase(double value) => setState(() {
    _playing = false;
    _frames?.cancel();
    final count = activityFrameCount(
      widget.character,
      widget.motion,
      widget.equipment,
      widget.exerciseId,
    );
    _frameStep = (value * count).floor().clamp(0, count - 1);
    _clock.value = value;
  });
  bool _reduced = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      _frames?.cancel();
      _reaction.stop();
      _reaction.value = 0;
      _playing = false;
    } else if (widget.autoplay && (!_initialized || _reduced)) {
      _startFrames();
    }
    _initialized = true;
    _reduced = reduced;
  }

  @override
  void dispose() {
    _phaseFocus.dispose();
    _frames?.cancel();
    _reaction.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final frameCount = activityFrameCount(
      widget.character,
      widget.motion,
      widget.equipment,
      widget.exerciseId,
    );
    String frameLabel(double value) =>
        '${s('frame')} ${math.min(frameCount, (value * frameCount).floor() + 1)}/$frameCount';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label:
              '${s('scene')}: ${s(companionId(widget.character))}. ${s('motion.${widget.motion.name}')}. ${s('animationBody')}${widget.interactive ? '. ${s('petHelp')}' : ''}',
          image: true,
          child: SizedBox(
            key: stageKey,
            height: widget.height,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, box) => GestureDetector(
                key: widget.interactive
                    ? const Key('interactive-companion')
                    : null,
                behavior: HitTestBehavior.opaque,
                onTapDown: widget.interactive
                    ? (e) => react(e.localPosition, box.biggest)
                    : null,
                child: RepaintBoundary(
                  child: FutureBuilder<CompanionSprites>(
                    future: loadCompanionSprites(
                      companionId(widget.character),
                      includeChestPress: isChestPressClip(
                        widget.motion,
                        widget.equipment,
                        widget.exerciseId,
                      ),
                      includeBenchPress: isBenchPressClip(
                        widget.motion,
                        widget.equipment,
                        widget.exerciseId,
                      ),
                      includeFacePull: isFacePullClip(
                        widget.motion,
                        widget.equipment,
                        widget.exerciseId,
                      ),
                      includeShoulderPress: isShoulderPressClip(
                        widget.motion,
                        widget.equipment,
                        widget.exerciseId,
                      ),
                      includeShoulderDumbbell: isShoulderDumbbellClip(
                        widget.motion,
                        widget.equipment,
                        widget.exerciseId,
                      ),
                      includeBarbellOverhead: isBarbellOverheadClip(
                        widget.motion,
                        widget.equipment,
                        widget.exerciseId,
                      ),
                      includeLateralMachine: isLateralMachineClip(
                        widget.motion,
                        widget.equipment,
                        widget.exerciseId,
                      ),
                      includeLateralDumbbell: isLateralDumbbellClip(
                        widget.motion,
                        widget.equipment,
                        widget.exerciseId,
                      ),
                      includeLatPulldown: isLatPulldownClip(
                        widget.motion,
                        widget.equipment,
                        widget.exerciseId,
                      ),
                      includeFrontRaise: isFrontRaiseClip(
                        widget.motion,
                        widget.equipment,
                        widget.exerciseId,
                      ),
                      includeLateralCable: isLateralCableClip(
                        widget.motion,
                        widget.equipment,
                        widget.exerciseId,
                      ),
                      includeReverseDumbbellFly: isReverseDumbbellFlyClip(
                        widget.motion,
                        widget.equipment,
                        widget.exerciseId,
                      ),
                      includeCableFly: isCableFlyClip(
                        widget.motion,
                        widget.equipment,
                        widget.exerciseId,
                      ),
                      includePecDeck: isPecDeckClip(
                        widget.motion,
                        widget.equipment,
                        widget.exerciseId,
                      ),
                      includePushUp: isPushUpClip(
                        widget.motion,
                        widget.equipment,
                        widget.exerciseId,
                      ),
                      includeInclinePress: isInclinePressClip(
                        widget.motion,
                        widget.equipment,
                        widget.exerciseId,
                      ),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text(s('spriteLoadError')));
                      }

                      return AnimatedBuilder(
                        animation: Listenable.merge([
                          _clock,
                          _reaction,
                          if (widget.interactive &&
                              !_reduced &&
                              AppPointer.of(context) != null)
                            AppPointer.of(context)!,
                        ]),
                        builder: (context, _) {
                          final global = !_reduced && widget.interactive
                              ? AppPointer.of(context)?.value
                              : null;
                          final render = stageKey.currentContext
                              ?.findRenderObject();
                          Offset look = Offset.zero;
                          if (global != null &&
                              render is RenderBox &&
                              render.hasSize) {
                            final local = render.globalToLocal(global);
                            look = Offset(
                              ((local.dx / render.size.width - .5) * 2).clamp(
                                -1,
                                1,
                              ),
                              ((local.dy / render.size.height - .4) * 2).clamp(
                                -1,
                                1,
                              ),
                            );
                          }
                          return CustomPaint(
                            painter: CompanionPainter(
                              character: companionId(widget.character),
                              motion: widget.motion,
                              equipment: widget.equipment,
                              phase: _clock.value,
                              sprites: snapshot.data,
                              exerciseId: widget.exerciseId,
                              look: look,
                              reaction: _reduced ? '' : reaction,
                              reactionPhase: _reaction.value,
                              mood: widget.mood,
                            ),
                            child: snapshot.hasData
                                ? null
                                : Center(child: Text(s('loadingCompanion'))),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.interactive)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              caption.isEmpty ? s('petHelp') : caption,
              key: const Key('pet-caption'),
              textAlign: TextAlign.center,
            ),
          ),
        if (widget.controls &&
            !hasActivityFrames(
              widget.motion,
              widget.equipment,
              widget.exerciseId,
            ))
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(s('activityFramesPending')),
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
                          _startFrames();
                        } else {
                          _frames?.cancel();
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
                    focusNode: _phaseFocus,
                    onChangeStart: (_) => _phaseFocus.requestFocus(),
                    divisions: frameCount - 1,
                    label: frameLabel(_clock.value),
                    value: _clock.value,
                    onChanged: _setPhase,
                    semanticFormatterCallback: frameLabel,
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
    this.sprites,
    this.exerciseId = '',
    this.look = Offset.zero,
    this.reaction = '',
    this.reactionPhase = 1,
    this.mood = 'happy',
  });
  final String character, exerciseId, reaction, mood;
  final Motion motion;
  final Equipment equipment;
  final double phase, reactionPhase;
  final Offset look;
  final CompanionSprites? sprites;
  CompanionFrame? get frame => sprites == null
      ? null
      : companionFrame(
          sprites: sprites!,
          motion: hasActivityFrames(motion, equipment, exerciseId)
              ? motion
              : Motion.idle,
          equipment: equipment,
          exerciseId: exerciseId,
          phase: phase,
          look: look,
          reaction: reaction,
          reactionPhase: reactionPhase,
          mood: mood,
        );
  @override
  void paint(Canvas canvas, Size size) {
    final selected = frame;
    if (selected == null) return;
    final source = selected.source;
    final scale =
        math.min(size.width / source.width, size.height / source.height) * .94;
    final width = source.width * scale, height = source.height * scale;
    final dest = Rect.fromLTWH(
      (size.width - width) / 2,
      size.height - height,
      width,
      height,
    );
    canvas.drawImageRect(
      selected.image,
      source,
      dest,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(CompanionPainter old) =>
      old.frame?.image != frame?.image || old.frame?.source != frame?.source;
}
