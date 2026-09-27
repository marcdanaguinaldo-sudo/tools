import 'package:flutter/material.dart';

import '../models/tool_model.dart';
import 'tool_geometry.dart';

class ToolArtwork extends StatelessWidget {
  final ToolModel tool;
  final double height;
  const ToolArtwork({super.key, required this.tool, this.height = 160});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Illustration of ${tool.name}',
        image: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: height,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF29414C), Color(0xFF142630)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CustomPaint(
              painter: _ToolPortrait(tool.id),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
}

/// Library card artwork. Shares the same solid renderer as the lesson view, so
/// the silhouette a learner scrolls past is the exact object they then study
/// in three dimensions. Fully offline, fully scalable, no image assets.
class _ToolPortrait extends CustomPainter {
  final String id;
  const _ToolPortrait(this.id);

  /// A fixed three-quarter view. Every tool is authored in its own natural
  /// orientation, so one pose reads well for the whole catalogue.
  static const double _pitch = -0.34;
  static const double _yaw = 0.62;
  static const double _zoom = 0.94;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    ToolGeometry.paint(
      canvas,
      size,
      toolId: id,
      rotX: _pitch,
      rotY: _yaw,
      anim: 0,
      zoom: _zoom,
      showStage: true,
    );
  }

  @override
  bool shouldRepaint(covariant _ToolPortrait oldDelegate) =>
      oldDelegate.id != id;
}
