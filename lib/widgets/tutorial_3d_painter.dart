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
class Framing {
  const Framing(this.pitch, this.yaw, this.zoom);
  final double pitch;
  final double yaw;
  final double zoom;
}

const List<Framing> _framings = [
  Framing(-0.26, 0.58, 0.98), // establish the whole tool
  Framing(-0.10, 0.92, 0.76), // swing round to the working end
  Framing(-0.52, 0.44, 0.90), // look down onto the contact surface
  Framing(-0.20, 1.18, 0.70), // tight on the grip
];

class _Tutorial3DViewState extends State<Tutorial3DView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  double _rotX = 0;
  double _rotY = 0;
  bool _dragged = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    if (widget.isPlaying) {
      _animController.repeat();
    }
  }

  @override
  void didUpdateWidget(Tutorial3DView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _animController.repeat();
      } else {
        // Park on a readable frame instead of freezing mid-stroke.
        _animController.animateTo(0.12,
            duration: const Duration(milliseconds: 220));
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.tool.steps.length;
    final framing =
        _framings[widget.stepIndex.clamp(0, _framings.length - 1)];
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
                  _rotY += details.delta.dx * 0.010;
                  _rotX = (_rotX - details.delta.dy * 0.008).clamp(-0.9, 0.9);
                });
              },
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) => CustomPaint(
                  painter: EnhancedTool3DPainter(
                    toolId: widget.tool.id,
                    stepIndex: widget.stepIndex,
                    rotX: _rotX,
                    rotY: _rotY,
                    progress: _animController.value,
                    framing: framing,
                  ),
                  child: const SizedBox.expand(),
                ),
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
    // The idle camera keeps turning so a paused screen still reads as a solid
    // object rather than a flat illustration.
    const tau = 2 * math.pi;
    final orbit = math.sin(progress * tau) * 0.24;
    final settle = math.cos(progress * tau) * 0.05;

    ToolGeometry.paint(
      canvas,
      size,
      toolId: toolId,
      rotX: rotX + framing.pitch + settle,
      rotY: rotY + framing.yaw + orbit,
      anim: progress,
      zoom: framing.zoom,
      stepIndex: stepIndex,
      showCallouts: true,
      showStage: true,
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
