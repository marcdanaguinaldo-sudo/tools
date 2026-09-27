import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_tool_scanner/models/tool_model.dart';
import 'package:kitchen_tool_scanner/widgets/tutorial_3d_painter.dart';
import 'package:kitchen_tool_scanner/widgets/tool_geometry.dart';

/// Rasterises a single tool pose and hands back raw RGBA bytes so the renderer
/// can be judged on what it actually draws, not on what the code intends.
Future<Uint8List> _render(
  String toolId, {
  double rotX = -0.34,
  double rotY = 0.62,
  double anim = 0,
  double zoom = 0.94,
  int stepIndex = 0,
  bool showCallouts = false,
}) async {
  const edge = 200;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  ToolGeometry.paint(
    canvas,
    Size(edge.toDouble(), edge.toDouble()),
    toolId: toolId,
    rotX: rotX,
    rotY: rotY,
    anim: anim,
    zoom: zoom,
    stepIndex: stepIndex,
    showCallouts: showCallouts,
  );
  final image = await recorder.endRecording().toImage(edge, edge);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Number of pixels with any visible ink.
int _painted(Uint8List px) {
  var count = 0;
  for (var i = 3; i < px.length; i += 4) {
    if (px[i] > 8) count++;
  }
  return count;
}

/// Number of pixels that differ between two rasters beyond [tolerance], which
/// absorbs anti-aliasing jitter but still catches a static image.
int _changed(Uint8List a, Uint8List b, {int tolerance = 12}) {
  var count = 0;
  for (var i = 0; i < a.length; i += 4) {
    if ((a[i] - b[i]).abs() > tolerance ||
        (a[i + 1] - b[i + 1]).abs() > tolerance ||
        (a[i + 2] - b[i + 2]).abs() > tolerance) {
      count++;
    }
  }
  return count;
}

/// Distinct opaque colours, which is how lambert shading proves it ran.
int _tones(Uint8List px) {
  final seen = <int>{};
  for (var i = 0; i < px.length; i += 4) {
    if (px[i + 3] > 200) seen.add((px[i] << 16) | (px[i + 1] << 8) | px[i + 2]);
  }
  return seen.length;
}

void main() {
  test('every tool paints a framed silhouette, not a blank or blown-out frame',
      () async {
    for (final tool in kBuiltInTools) {
      final px = await _render(tool.id);
      final filled = _painted(px) / (200 * 200);
      expect(filled, greaterThan(0.015),
          reason: '${tool.id} drew almost nothing');
      expect(filled, lessThan(0.60), reason: '${tool.id} overflowed its frame');
    }
  });

  test('every tool is lit with multiple tones rather than flat fill', () async {
    for (final tool in kBuiltInTools) {
      expect(_tones(await _render(tool.id)), greaterThanOrEqualTo(4),
          reason: '${tool.id} has no visible shading');
    }
  });

  test('the technique animation changes the rendered image', () async {
    // The original painter ignored its animation phase and repainted an
    // identical frame, so every lesson was a still image.
    for (final tool in kBuiltInTools) {
      final a = await _render(tool.id, anim: 0);
      final b = await _render(tool.id, anim: 0.37);
      expect(_changed(a, b), greaterThan(40),
          reason: '${tool.id} does not animate');
    }
  });

  test('camera drag changes the rendered image', () async {
    // rotX used to be threaded in but never drawn, so orbiting did nothing.
    // A tool whose long axis is X hides its own pitch, so a small but non-zero
    // change proves the value is consumed; the rest must respond strongly.
    for (final tool in kBuiltInTools) {
      final a = await _render(tool.id, rotX: -0.34);
      final b = await _render(tool.id, rotX: 0.28);
      expect(_changed(a, b), greaterThan(25),
          reason: '${tool.id} ignores the camera pitch');
    }
    for (final toolId in const ['knife', 'whisk', 'bowl', 'cleaver', 'tongs']) {
      final a = await _render(toolId, rotX: -0.34);
      final b = await _render(toolId, rotX: 0.28);
      expect(_changed(a, b), greaterThan(200),
          reason: '$toolId barely responds to the camera pitch');
    }
  });

  test('horizontal orbit changes the rendered image for every tool', () async {
    for (final tool in kBuiltInTools) {
      final a = await _render(tool.id, rotY: 0.1);
      final b = await _render(tool.id, rotY: 0.9);
      expect(_changed(a, b), greaterThan(60),
          reason: '${tool.id} does not respond to orbiting');
    }
  });

  test('lesson step re-frames the tool through the painter', () async {
    const first = Framing(-0.30, 0.10, 1.00);
    const last = Framing(0.22, -0.55, 0.86);
    for (final toolId in const ['knife', 'whisk', 'cleaver', 'ladle']) {
      final a = await _render(toolId, stepIndex: 0, showCallouts: true);
      final b = await _render(toolId, stepIndex: 3, showCallouts: true);
      expect(_changed(a, b), greaterThan(20),
          reason: '$toolId callout is static');

      final aFrame = await _render(toolId,
          rotX: first.pitch, rotY: first.yaw, zoom: first.zoom);
      final bFrame = await _render(toolId,
          rotX: last.pitch, rotY: last.yaw, zoom: last.zoom);
      expect(_changed(aFrame, bFrame), greaterThan(200),
          reason: '$toolId framing is identical across steps');
    }
  });

  test('the lesson painter repaints when its animation or step changes', () {
    const framing = Framing(0, 0, 1);
    const base = EnhancedTool3DPainter(
      toolId: 'knife',
      stepIndex: 0,
      rotX: 0,
      rotY: 0,
      progress: 0,
      framing: framing,
    );
    expect(base.shouldRepaint(base), isFalse);
    expect(
      base.shouldRepaint(const EnhancedTool3DPainter(
        toolId: 'knife',
        stepIndex: 1,
        rotX: 0,
        rotY: 0,
        progress: 0,
        framing: framing,
      )),
      isTrue,
      reason: 'a new lesson step must repaint',
    );
    expect(
      base.shouldRepaint(const EnhancedTool3DPainter(
        toolId: 'knife',
        stepIndex: 0,
        rotX: 0,
        rotY: 0,
        progress: 0.4,
        framing: framing,
      )),
      isTrue,
      reason: 'a new animation frame must repaint',
    );
    expect(
      base.shouldRepaint(const EnhancedTool3DPainter(
        toolId: 'whisk',
        stepIndex: 0,
        rotX: 0,
        rotY: 0,
        progress: 0,
        framing: framing,
      )),
      isTrue,
      reason: 'a different tool must repaint',
    );
  });
}
