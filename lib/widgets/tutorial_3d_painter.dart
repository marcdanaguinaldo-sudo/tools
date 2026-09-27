import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/tool_model.dart';
import 'tool_geometry.dart';

class Tutorial3DView extends StatefulWidget {
  final ToolModel tool;
  final int stepIndex;
  final bool isPlaying;

  const Tutorial3DView({
    super.key,
    required this.tool,
    required this.stepIndex,
    required this.isPlaying,
  });

  @override
  State<Tutorial3DView> createState() => _Tutorial3DViewState();
}

/// Camera framing per lesson step. Later steps push in on the working end of
/// the tool instead of showing the whole object again, so each step of a
/// lesson actually looks at something different.
/// Note: `zoom` magnifies the whole tool (it does not re-centre on a specific
/// part). Larger zoom = bigger on screen. The values below increase so later
/// steps feel tighter.
class Framing {
  const Framing(this.pitch, this.yaw, this.zoom);
  final double pitch;
  final double yaw;
  final double zoom;
}

const List<Framing> _framings = [
  Framing(-0.26, 0.58, 0.80), // establish the whole tool
  Framing(-0.10, 0.92, 1.05), // swing round to the working end
  Framing(-0.52, 0.44, 1.15), // look down onto the contact surface
  Framing(-0.20, 1.18, 1.25), // tight on the grip
];

/// Framing the previous step was heading towards, so a camera glide starts
/// from where the viewer actually was rather than teleporting from step one.
Framing _previousFraming(Framing current) {
  final index = _framings.indexOf(current);
  if (index <= 0) return current;
  return _framings[index - 1];
}

double _lerpAngle(double a, double b, double t) => a + (b - a) * t;

class _Tutorial3DViewState extends State<Tutorial3DView>
    with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final AnimationController _cameraController;
  late final AnimationController _inertiaController;
  double _rotX = 0;
  double _rotY = 0;
  double _pitchVelocity = 0;
  double _yawVelocity = 0;
  bool _dragged = false;

  Duration get _motionDuration =>
      Duration(milliseconds: 2600 + (widget.tool.id.length % 4) * 180);

  void _playFromBeginning() {
    _animController
      ..duration = _motionDuration
      ..reset()
      ..repeat();
  }

  void _replayTechnique() {
    _inertiaController.stop();
    setState(() {
      _dragged = false;
      _rotX = 0;
      _rotY = 0;
      _pitchVelocity = 0;
      _yawVelocity = 0;
    });
    _cameraController.forward(from: 0);
    _playFromBeginning();
  }

  String _motionLabel() {
    final phase = _animController.value;
    if (phase < .14) return 'Ready position';
    if (phase < .46) return 'Demonstrating stroke';
    if (phase < .65) return 'Returning safely';
    if (phase < .86) return 'Repeating technique';
    return 'Resetting position';
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: _motionDuration,
    );
    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      value: 1,
    );
    _inertiaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _inertiaController.addListener(() {
      // Orbit inertia: a short glide after release feels physical.
      setState(() {
        _rotY += _yawVelocity * _inertiaController.value;
        _rotX = (_rotX + _pitchVelocity * _inertiaController.value)
            .clamp(-0.9, 0.9);
      });
    });
    if (widget.isPlaying) {
      _playFromBeginning();
    }
  }

  @override
  void didUpdateWidget(Tutorial3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _playFromBeginning();
      } else {
        // Park on a readable frame instead of freezing mid-stroke.
        _animController.animateTo(0.12,
            duration: const Duration(milliseconds: 220));
      }
    }
    // A new technique needs to begin at its clear "ready" pose, and the camera
    // should glide to the new framing instead of snapping. Without the glide a
    // step change is a cut; with it the lesson reads as one continuous look.
    if (widget.stepIndex != oldWidget.stepIndex ||
        widget.tool.id != oldWidget.tool.id) {
      _animController.duration = _motionDuration;
      if (widget.isPlaying) {
        _playFromBeginning();
      } else {
        _animController.value = 0.12;
      }
      _cameraController
        ..duration = widget.tool.id != oldWidget.tool.id
            ? const Duration(milliseconds: 1200)
            : const Duration(milliseconds: 900)
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _cameraController.dispose();
    _inertiaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.tool.steps.length;
    final target = _framings[widget.stepIndex.clamp(0, _framings.length - 1)];
    return Semantics(
      label: 'Animated illustration of ${widget.tool.name}',
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                setState(() {
                  _dragged = true;
                  _yawVelocity = details.delta.dx * 0.010;
                  _pitchVelocity = -details.delta.dy * 0.008;
                  _rotY += _yawVelocity;
                  _rotX = (_rotX + _pitchVelocity).clamp(-0.9, 0.9);
                });
              },
              onPanEnd: (_) => _inertiaController.forward(from: 0),
              onDoubleTap: _replayTechnique,
              child: AnimatedBuilder(
                animation:
                    Listenable.merge([_animController, _cameraController]),
                builder: (context, child) {
                  // Ease out on the glide so the camera arrives rather than
                  // stops. The tool keeps animating while it moves.
                  final t = Curves.easeOutCubic
                      .transform(_cameraController.value.clamp(0.0, 1.0));
                  var from = _previousFraming(target);
                  final framing = Framing(
                    _lerpAngle(from.pitch, target.pitch, t),
                    _lerpAngle(from.yaw, target.yaw, t),
                    from.zoom + (target.zoom - from.zoom) * t,
                  );
                  return CustomPaint(
                    painter: EnhancedTool3DPainter(
                      toolId: widget.tool.id,
                      stepIndex: widget.stepIndex,
                      rotX: _rotX,
                      rotY: _rotY,
                      progress: _animController.value,
                      framing: framing,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 8,
            child: IgnorePointer(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _dragged ? Icons.threed_rotation : Icons.swipe_left_alt,
                    size: 13,
                    color: Colors.white.withValues(alpha: .45),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _dragged ? 'Orbiting' : 'Drag to orbit',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: .45),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 8,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final running =
                      widget.isPlaying && _animController.isAnimating;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: (running
                              ? const Color(0xFF155E4A)
                              : const Color(0xFF334155))
                          .withValues(alpha: .88),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(running ? Icons.motion_photos_on : Icons.pause,
                            size: 13, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(running ? _motionLabel() : 'Paused',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Step ${widget.stepIndex.clamp(0, steps - 1) + 1}/$steps',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFC66D),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 4,
            child: Tooltip(
              message: 'Replay 3D technique',
              child: IconButton.filledTonal(
                onPressed: _replayTechnique,
                icon: const Icon(Icons.replay_rounded, size: 19),
                color: const Color(0xFFFFD58D),
                style: IconButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF102938).withValues(alpha: .88),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws the tool as a lit solid from a draggable camera, with the tool's own
/// technique motion running on [progress].
class EnhancedTool3DPainter extends CustomPainter {
  final String toolId;
  final int stepIndex;
  final double rotX;
  final double rotY;
  final double progress;
  final Framing framing;

  const EnhancedTool3DPainter({
    required this.toolId,
    required this.stepIndex,
    required this.rotX,
    required this.rotY,
    required this.progress,
    required this.framing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    const tau = 2 * math.pi;
    _paintCinematicStage(canvas, size);

    // The camera gently tracks the working part. The swing is deliberately
    // restrained: it exists to reveal the gesture, not to compete with it.
    final orbit = math.sin(progress * tau) * 0.24;
    final settle = math.sin(progress * tau * 2) * 0.05;
    final techniqueProgress = _stagedTechniqueProgress(progress);

    ToolGeometry.paint(
      canvas,
      size,
      toolId: toolId,
      rotX: rotX + framing.pitch + settle,
      rotY: rotY + framing.yaw + orbit,
      anim: techniqueProgress,
      zoom: framing.zoom,
      stepIndex: stepIndex,
      showCallouts: true,
      showStage: true,
    );
  }

  /// Each loop reads as a compact demonstration: settle at the ready pose,
  /// make the forward stroke, return, repeat on the opposite side, then reset.
  /// A linear sine loop made the original gestures feel like idle wobbling.
  double _stagedTechniqueProgress(double value) {
    final t = value.clamp(0.0, 1.0);
    double between(double start, double end, double from, double to) {
      final local = ((t - start) / (end - start)).clamp(0.0, 1.0);
      return from + (to - from) * Curves.easeInOutCubic.transform(local);
    }

    if (t < .14) return 0;
    if (t < .46) return between(.14, .46, 0, .25);
    if (t < .65) return between(.46, .65, .25, .5);
    if (t < .86) return between(.65, .86, .5, .75);
    return between(.86, 1, .75, 1);
  }

  /// A quiet studio pool behind the tool, so the object reads as lit from the
  /// front-left and sits in a space rather than on a flat rectangle. Kept
  /// deliberately plain: no grid, no horizon, no floating decoration — every
  /// pixel that is not the tool is there to hold the eye on the tool.
  ///
  /// Drawn here rather than in ToolGeometry so the reusable renderer still
  /// draws cleanly on library cards without the lesson chrome.
  void _paintCinematicStage(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.12, -.34),
          radius: 1.02,
          colors: [Color(0xFF26414F), Color(0xFF132530), Color(0xFF0A161E)],
          stops: [0, .55, 1],
        ).createShader(bounds),
    );
    // Vignette: the corners fall away so the tool always reads as the subject,
    // even at small sizes on a bright phone screen.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const RadialGradient(
          radius: .88,
          colors: [Color(0x00000000), Color(0x99000000)],
          stops: [.52, 1],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(covariant EnhancedTool3DPainter oldDelegate) {
    return oldDelegate.toolId != toolId ||
        oldDelegate.stepIndex != stepIndex ||
        oldDelegate.rotX != rotX ||
        oldDelegate.rotY != rotY ||
        oldDelegate.progress != progress ||
        oldDelegate.framing != framing;
  }
}
