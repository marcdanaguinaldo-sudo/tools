import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/tool_model.dart';

// ---------------------------------------------------------------------------
// A very small software 3D pipeline.
//
// Every tool is described once, as a set of solid meshes, and is then drawn by
// two callers: the static library card artwork and the animated lesson view.
// That keeps a single source of truth for the shape of each tool, gives the
// lesson view genuine depth, lighting and motion, and keeps the whole thing
// dependency free and offline.
// ---------------------------------------------------------------------------

class _V {
  const _V(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;

  _V add(_V o) => _V(x + o.x, y + o.y, z + o.z);
  _V scale(double s) => _V(x * s, y * s, z * s);
  _V rotateX(double a) {
    final c = math.cos(a);
    final s = math.sin(a);
    return _V(x, y * c - z * s, y * s + z * c);
  }

  _V rotateY(double a) {
    final c = math.cos(a);
    final s = math.sin(a);
    return _V(x * c + z * s, y, -x * s + z * c);
  }

  _V rotateZ(double a) {
    final c = math.cos(a);
    final s = math.sin(a);
    return _V(x * c - y * s, x * s + y * c, z);
  }
}

class _Face {
  _Face(this.points, this.color);
  final List<_V> points;
  final int color;
}

class _Mesh {
  _Mesh(this.faces);
  final List<_Face> faces;
}

_Mesh _merge(List<_Mesh> parts) =>
    _Mesh([for (final part in parts) ...part.faces]);

/// The technique animation attached to one part of a tool.
enum _Anim {
  none,
  bob, // vertical working stroke
  sway, // side to side shearing wave
  rock, // rocking / hinge motion
  press, // squeeze closed then open
  crank, // continuous rotation about the vertical axis
  roll, // continuous rotation about the tool's long axis
  lever, // pivot about one end
  lift, // raise and return
  fan, // hinge outwards to reveal what is nested
}

/// Forces the polygon to wind counter-clockwise in its own (r, y) plane so the
/// generated faces always end up with outward facing normals.
List<Offset> _ccw(List<Offset> profile) {
  var area = 0.0;
  for (var i = 0; i < profile.length; i++) {
    final a = profile[i];
    final b = profile[(i + 1) % profile.length];
    area += a.dx * b.dy - b.dx * a.dy;
  }
  return area < 0 ? profile.reversed.toList() : profile;
}

bool _same(_V a, _V b) =>
    (a.x - b.x).abs() < 1e-6 &&
    (a.y - b.y).abs() < 1e-6 &&
    (a.z - b.z).abs() < 1e-6;

_Face? _face(List<_V> raw, int color) {
  final points = <_V>[];
  for (final p in raw) {
    if (points.isEmpty || !_same(points.last, p)) points.add(p);
  }
  if (points.length > 2 && _same(points.first, points.last)) {
    points.removeLast();
  }
  return points.length < 3 ? null : _Face(points, color);
}

/// Extrudes a counter-clockwise 2D silhouette (x, y) between two z planes.
/// This is the workhorse for every flat tool: blades, boards, spatulas,
/// peelers, graters, mitts.
_Mesh _extrude(List<Offset> silhouette, double z0, double z1, int color) {
  final poly = _ccw(silhouette);
  final faces = <_Face>[];
  for (var i = 0; i < poly.length; i++) {
    final a = poly[i];
    final b = poly[(i + 1) % poly.length];
    final side = _face([
      _V(a.dx, a.dy, z0),
      _V(b.dx, b.dy, z0),
      _V(b.dx, b.dy, z1),
      _V(a.dx, a.dy, z1),
    ], color);
    if (side != null) faces.add(side);
  }
  final back = _face([for (final p in poly) _V(p.dx, p.dy, z0)], color);
  final front =
      _face([for (final p in poly.reversed) _V(p.dx, p.dy, z1)], color);
  if (back != null) faces.add(back);
  if (front != null) faces.add(front);
  return _Mesh(faces);
}

/// Revolves a closed cross-section (radius, y) around the vertical axis.
/// Everything round in the catalogue is built from this: bowls, jugs, ladles,
/// funnels, pestles, spoon handles.
_Mesh _revolve(List<Offset> profile, int segments, int color) {
  final loop = _ccw(profile);
  final faces = <_Face>[];
  for (var i = 0; i < loop.length; i++) {
    final a = loop[i];
    final b = loop[(i + 1) % loop.length];
    for (var j = 0; j < segments; j++) {
      final t0 = 2 * math.pi * j / segments;
      final t1 = 2 * math.pi * (j + 1) / segments;
      final c0 = math.cos(t0);
      final s0 = math.sin(t0);
      final c1 = math.cos(t1);
      final s1 = math.sin(t1);
      final quad = _face([
        _V(a.dx * c0, a.dy, a.dx * s0),
        _V(b.dx * c0, b.dy, b.dx * s0),
        _V(b.dx * c1, b.dy, b.dx * s1),
        _V(a.dx * c1, a.dy, a.dx * s1),
      ], color);
      if (quad != null) faces.add(quad);
    }
  }
  return _Mesh(faces);
}

/// Rotates a finished mesh about the vertical axis and unions the copies.
/// Used to fan whisk wires and turner slots around a central shaft.
_Mesh _radiallyRepeat(_Mesh base, int count, {double twist = 0}) {
  final faces = <_Face>[];
  for (var i = 0; i < count; i++) {
    final a = twist + 2 * math.pi * i / count;
    final c = math.cos(a);
    final s = math.sin(a);
    for (final face in base.faces) {
      final rotated = _face([
        for (final p in face.points)
          _V(p.x * c + p.z * s, p.y, -p.x * s + p.z * c)
      ], face.color);
      if (rotated != null) faces.add(rotated);
    }
  }
  return _Mesh(faces);
}

/// Repeats a flat arc around the vertical axis to make a wire cage.
_Mesh _wireCage(List<Offset> arc, int count, double wire) {
  final loop = _extrude(arc, -wire, wire, _steel);
  return _radiallyRepeat(loop, count);
}

// --- profile helpers -------------------------------------------------------

_Mesh _cyl(double r, double y0, double y1, {int sides = 20}) => _revolve(
    [Offset(0, y0), Offset(r, y0), Offset(r, y1), Offset(0, y1)],
    sides,
    _steel);

_Mesh _sphere(double r, {int rings = 8, int sides = 20}) {
  final profile = <Offset>[];
  for (var i = 0; i <= rings; i++) {
    final a = math.pi * i / rings;
    profile.add(Offset(r * math.sin(a), -r * math.cos(a)));
  }
  for (var i = rings; i >= 0; i--) {
    final a = math.pi * i / rings;
    final s = math.sin(a);
    if (s.abs() > 1e-4) {
      profile.add(Offset(math.max(0, r * s - r * .12) * (s / s.abs()),
          -r * math.cos(a) * .86));
    }
  }
  return _revolve(profile, sides, _steel);
}

_Mesh _bowl(double r, double h, double wall,
    {int sides = 24, int color = _steel}) {
  const steps = 7;
  final outer = <Offset>[];
  for (var i = 0; i <= steps; i++) {
    final a = (math.pi / 2) * (i / steps);
    outer.add(Offset(r * math.sin(a), h - h * math.cos(a) * .82));
  }
  final inner = <Offset>[];
  for (var i = outer.length - 1; i >= 0; i--) {
    final p = outer[i];
    inner.add(Offset(math.max(0, p.dx - wall), p.dy + wall * .55));
  }
  return _revolve([...outer, ...inner], sides, color);
}

_Mesh _cup(double rTop, double rBottom, double h, double wall,
    {int sides = 22, int color = _glass}) {
  return _revolve([
    const Offset(0, 0),
    Offset(rBottom, 0),
    Offset(rTop, h),
    Offset(math.max(0, rTop - wall), h),
    Offset(math.max(0, rBottom - wall), wall * .6),
    Offset(0, wall * .6),
  ], sides, color);
}

_Mesh _cone(double rTop, double rBottom, double h, double wall,
    {int sides = 20, int color = _steel}) {
  return _revolve([
    const Offset(0, 0),
    Offset(rBottom, 0),
    Offset(rTop, h),
    Offset(math.max(0, rTop - wall), h),
    Offset(math.max(0, rBottom - wall), wall * .8),
    Offset(0, wall * .8),
  ], sides, color);
}

_Mesh _tube(double rOuter, double rInner, double y0, double y1,
    {int sides = 20, int color = _steel}) {
  return _revolve([
    Offset(rInner, y0),
    Offset(rOuter, y0),
    Offset(rOuter, y1),
    Offset(rInner, y1),
  ], sides, color);
}

// --- palette ---------------------------------------------------------------

const _steel = 0xFFC6D2D9;
const _steelDark = 0xFF8FA0AA;
const _black = 0xFF2B333B;
const _rubber = 0xFF3D4A56;
const _wood = 0xFFB2794A;
const _woodDark = 0xFF7A4E2C;
const _glass = 0xFFA9D6E2;
const _ceramic = 0xFFF1ECE1;
const _silicone = 0xFFD1495B;
const _amber = 0xFFF2A65A;
const _stone = 0xFF8C9199;
const _sugar = 0xFFEFE7D8;

// --- part + tool definitions ----------------------------------------------

class _Part {
  const _Part(
    this.mesh, {
    this.anim = _Anim.none,
    this.pivot = const Offset(0, 0),
    this.amount = 1,
  });

  final _Mesh mesh;
  final _Anim anim;
  final Offset pivot;
  final double amount;
}

/// Turns [p] by [turn] about [pivot] so a moving part articulates from its own
/// joint rather than spinning around the world origin.
_V _about(_V p, Offset pivot, _V Function(_V) turn) {
  final offset = _V(pivot.dx, pivot.dy, 0);
  return turn(p.add(offset.scale(-1))).add(offset);
}

List<_V> _pose(List<_V> vertices, _Part part, double t) {
  if (part.anim == _Anim.none) return vertices;
  final phase = 2 * math.pi * t;

  // Rocking gestures share one axis; the coefficient per gesture is what makes
  // a whisk sweep read differently from a garlic press bite.
  List<_V> tilt(double angle) => [
        for (final p in vertices)
          _about(p, part.pivot, (q) => q.rotateZ(angle * part.amount)),
      ];
  List<_V> yaw(double angle) => [
        for (final p in vertices)
          _about(p, part.pivot, (q) => q.rotateY(angle * part.amount)),
      ];
  List<_V> rise(double distance) => [
        for (final p in vertices) p.add(_V(0, distance * part.amount, 0)),
      ];

  final wave = math.sin(phase);
  switch (part.anim) {
    case _Anim.none:
      return vertices;
    case _Anim.bob:
      return rise(wave * .16);
    case _Anim.lift:
      // A full stroke from rest to peak, so a scoop visibly rises and returns.
      return rise((wave * .5 + .5) * .34);
    case _Anim.sway:
      return tilt(wave * .34);
    case _Anim.rock:
      return tilt(wave * .26);
    case _Anim.press:
      return tilt(wave * .30);
    case _Anim.fan:
      return tilt(wave * .42);
    case _Anim.lever:
      return tilt(wave * .50);
    case _Anim.crank:
      return yaw(phase);
    case _Anim.roll:
      return tilt(phase);
  }
}

_V _sub(_V a, _V b) => _V(a.x - b.x, a.y - b.y, a.z - b.z);

_V _cross(_V a, _V b) => _V(
      a.y * b.z - a.z * b.y,
      a.z * b.x - a.x * b.z,
      a.x * b.y - a.y * b.x,
    );

/// Applies an arbitrary per-vertex transform to a finished mesh.
_Mesh _mapVerts(_Mesh mesh, _V Function(_V) f) {
  final faces = <_Face>[];
  for (final face in mesh.faces) {
    final mapped = _face([for (final p in face.points) f(p)], face.color);
    if (mapped != null) faces.add(mapped);
  }
  return _Mesh(faces);
}

/// Lays a mesh down into the xy plane, so a ring built around the vertical
/// axis can be used as a handle loop.
_Mesh _layFlat(_Mesh mesh, {bool flip = false}) => _mapVerts(mesh, (p) {
      final a = flip ? -math.pi / 2 : math.pi / 2;
      final c = math.cos(a);
      final s = math.sin(a);
      return _V(p.x, p.y * c - p.z * s, p.y * s + p.z * c);
    });

/// Swings a vertical cylinder onto the horizontal x axis, so a barrel can lie
/// left to right. A proper rotation, so face winding and normals survive.
_Mesh _axisX(_Mesh mesh) => _mapVerts(mesh, (p) => _V(-p.y, p.x, p.z));

/// One balloon-whisk wire, as a thin crescent in the xy plane. Repeated
/// around the axis by [_wireCage] it becomes the full cage.
List<Offset> _whiskArc() {
  const steps = 12;
  final outer = <Offset>[];
  final inner = <Offset>[];
  for (var i = 0; i <= steps; i++) {
    final a = math.pi * (i / steps);
    final bow = math.sin(a);
    outer.add(Offset(0.42 * bow, -0.12 - 0.40 * math.cos(a * .5)));
    inner.add(Offset(0.36 * bow, -0.12 - 0.40 * math.cos(a * .5) + .012));
  }
  return [...outer, ...inner.reversed];
}

// ---------------------------------------------------------------------------
// Renderer
// ---------------------------------------------------------------------------

class ToolGeometry {
  const ToolGeometry._();

  static const double _focal = 2.8;
  static const _light = _V(-0.42, 0.74, 0.66);

  /// True when every tool in the catalogue has bespoke geometry. A test asserts
  /// this so a new tool can never ship with a fallback shape.
  static bool get isComplete => missingGeometry.isEmpty;

  static List<String> get missingGeometry => [
        for (final tool in kBuiltInTools)
          if (!_parts.containsKey(tool.id)) tool.id,
      ];

  static bool hasGeometry(String toolId) => _parts.containsKey(toolId);

  /// Tools whose every part is static, which would make their lesson a still
  /// image. A test asserts this is empty.
  static List<String> get staticTools => [
        for (final entry in _parts.entries)
          if (!entry.value.any((part) => part.anim != _Anim.none)) entry.key,
      ];

  /// Draws [toolId] as a shaded solid with real perspective.
  ///
  /// [anim] drives the tool's technique motion, [stepIndex] re-frames the
  /// camera for each lesson step, and [rotX] / [rotY] are the caller's drag.
  static void paint(
    Canvas canvas,
    Size size, {
    required String toolId,
    required double rotX,
    required double rotY,
    required double anim,
    required double zoom,
    int stepIndex = 0,
    bool showCallouts = false,
    bool showStage = false,
  }) {
    final parts = _parts[toolId] ?? _parts['knife']!;
    if (parts.isEmpty) return;

    // Frame the tool from its own bounds so every mesh in the catalogue sits
    // well in frame regardless of how it was authored. The bounds come from the
    // resting pose on purpose: re-fitting every animated frame would recentre
    // the camera onto the moving part and quietly cancel out every stroke that
    // works by translating (bob, lift).
    var minX = double.infinity;
    var maxX = double.negativeInfinity;
    var minY = double.infinity;
    var maxY = double.negativeInfinity;
    for (final part in parts) {
      for (final face in part.mesh.faces) {
        for (final p in _pose(face.points, part, 0)) {
          final turned = p.rotateX(rotX).rotateY(rotY);
          if (turned.x < minX) minX = turned.x;
          if (turned.x > maxX) maxX = turned.x;
          if (turned.y < minY) minY = turned.y;
          if (turned.y > maxY) maxY = turned.y;
        }
      }
    }
    if (!minX.isFinite || !minY.isFinite) return;

    final midX = (minX + maxX) / 2;
    final midY = (minY + maxY) / 2;
    final extent = math.max(maxX - minX, maxY - minY) / 2;
    if (extent < 1e-3) return;

    final origin = Offset(size.width / 2, size.height / 2);
    final unit = (math.min(size.width, size.height) * .40 * zoom) / extent;
    // A shallow tilt so the model reads as a solid rather than a flat card.
    final floor = origin.dy + math.min(size.width, size.height) * .34;

    Offset project(_V p) {
      final z = p.z;
      final k = _focal / math.max(.35, _focal - z);
      return Offset(origin.dx + (p.x - midX) * unit * k,
          origin.dy - (p.y - midY) * unit * k);
    }

    if (showStage) _drawStage(canvas, size, origin, floor);

    final length = math
        .sqrt(_light.x * _light.x + _light.y * _light.y + _light.z * _light.z);
    final lx = _light.x / length;
    final ly = _light.y / length;
    final lz = _light.z / length;

    final drawable = <_Drawable>[];
    for (var i = 0; i < parts.length; i++) {
      for (final face in parts[i].mesh.faces) {
        // Re-pose the exact face vertices so the animated position is used.
        final posed = _pose(face.points, parts[i], anim);
        final turned = [for (final p in posed) p.rotateX(rotX).rotateY(rotY)];
        if (turned.length < 3) continue;
        final normal =
            _cross(_sub(turned[1], turned[0]), _sub(turned[2], turned[0]));
        if (normal.z <= 1e-6) continue; // back face
        var z = 0.0;
        for (final p in turned) {
          z += p.z;
        }
        z /= turned.length;
        final diffuse =
            math.max(0.0, normal.x * lx + normal.y * ly + normal.z * lz);
        drawable.add(_Drawable(
          [for (final p in turned) project(p)],
          _shade(face.color, diffuse),
          z,
        ));
      }
    }

    drawable.sort((a, b) => a.z.compareTo(b.z));
    for (final face in drawable) {
      final path = Path()..addPolygon(face.points, true);
      final fill = Paint()..color = Color(face.color);
      canvas.drawPath(path, fill);
      // Stroking with the fill colour closes the hairline seams that
      // anti-aliasing leaves between adjacent facets.
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Color(face.color));
    }

    if (showCallouts) {
      _drawCallouts(canvas, size, origin, anim, stepIndex);
    }
  }

  static void _drawStage(
      Canvas canvas, Size size, Offset origin, double floor) {
    final w = math.min(size.width, size.height) * .34;
    const lift = 16.0;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(origin.dx, floor - lift * .2),
          width: w * 2.1,
          height: w * .62),
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(origin.dx, floor - lift * .2),
          width: w * 1.8,
          height: w * .5),
      Paint()..color = const Color(0x1AFFFFFF),
    );
  }

  /// A pulsing technique arc plus a target-angle marker. Driven by the same
  /// phase as the tool motion so the annotation beats with the demonstration.
  static void _drawCallouts(
      Canvas canvas, Size size, Offset origin, double anim, int stepIndex) {
    final phase = 2 * math.pi * anim;
    final pulse = .5 + .5 * math.sin(phase);
    final radius = math.min(size.width, size.height) * (.30 + .012 * pulse);
    final arc = Rect.fromCircle(center: origin, radius: radius);

    // Later steps sweep a longer arc, so the annotation tracks the lesson.
    final sweep = .18 + .12 * stepIndex.clamp(0, 3);
    canvas.drawArc(
      arc,
      -math.pi * .82,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = const Color(_amber).withValues(alpha: .30 + .35 * pulse),
    );
    canvas.drawArc(
      arc,
      math.pi * .10,
      sweep * .7,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = const Color(_amber).withValues(alpha: .18 + .22 * pulse),
    );
    canvas.drawCircle(
      Offset(origin.dx + radius * math.cos(-math.pi * .82),
          origin.dy + radius * math.sin(-math.pi * .82)),
      3.4 + 1.4 * pulse,
      Paint()..color = const Color(_amber).withValues(alpha: .55 + .35 * pulse),
    );
  }

  static int _shade(int color, double diffuse) {
    final a = (color >> 24) & 0xFF;
    final r = (color >> 16) & 0xFF;
    final g = (color >> 8) & 0xFF;
    final b = color & 0xFF;
    final f = .40 + .74 * diffuse;
    int ch(int c) => (c * f).round().clamp(0, 255);
    return (a << 24) | (ch(r) << 16) | (ch(g) << 8) | ch(b);
  }
}

class _Drawable {
  _Drawable(this.points, this.color, this.z);
  final List<Offset> points;
  final int color;
  final double z;
}

// --- shape helpers ---------------------------------------------------------

_Mesh _shift(_Mesh mesh, double x, double y, double z) =>
    _mapVerts(mesh, (p) => _V(p.x + x, p.y + y, p.z + z));

/// A rounded rectangle silhouette, ready for [_extrude].
List<Offset> _rrect(double cx, double cy, double w, double h, double r,
    {int steps = 4}) {
  final hw = w / 2;
  final hh = h / 2;
  final radius = math.min(r, math.min(hw, hh));
  final pts = <Offset>[];
  const corners = [
    (1.0, 1.0, 0.0),
    (-1.0, 1.0, 1.5707963),
    (-1.0, -1.0, 3.1415927),
    (1.0, -1.0, 4.7123890),
  ];
  for (final (sx, sy, a0) in corners) {
    final ccx = cx + sx * (hw - radius);
    final ccy = cy + sy * (hh - radius);
    for (var i = 0; i <= steps; i++) {
      final a = a0 + (math.pi / 2) * (i / steps);
      pts.add(Offset(ccx + radius * math.cos(a), ccy + radius * math.sin(a)));
    }
  }
  return pts;
}

/// A ring lying in the xy plane, so it can be used as a handle loop.
_Mesh _ringXY(double rOut, double rIn, double thickness, int color,
        {int sides = 16}) =>
    _layFlat(_tube(rOut, rIn, -thickness / 2, thickness / 2,
        sides: sides, color: color));

/// A shallow scoop: an ellipsoid flattened onto the xy plane.
_Mesh _scoop(double rx, double ry, double depth, int color, {int rings = 6}) {
  final profile = <Offset>[];
  for (var i = 0; i <= rings; i++) {
    final a = math.pi * i / rings;
    profile.add(Offset(rx * math.sin(a), depth - depth * math.cos(a) * .6));
  }
  for (var i = rings; i >= 0; i--) {
    final a = math.pi * i / rings;
    final s = math.sin(a);
    if (s.abs() > 1e-4) {
      profile.add(Offset(math.max(0, rx * s - depth * .22) * (s / s.abs()),
          depth * .30 - depth * math.cos(a) * .48));
    }
  }
  return _revolve(profile, 18, color);
}

/// A flat blade with a row of drainage slots cut into it, faked as recessed
/// dark bars so the solid renderer stays watertight.
_Mesh _slottedBlade(
    double cx, double cy, double w, double h, double z, int slotCount) {
  return _merge([
    _extrude(_rrect(cx, cy, w, h, h * .22), z - .028, z + .028, _steel),
    for (var i = 0; i < slotCount; i++)
      _extrude(
        _rrect(cx - w * .34 + (i * w * .68) / (slotCount - 1), cy, w * .09,
            h * .58, h * .05),
        z + .026,
        z + .032,
        _steelDark,
      ),
  ]);
}

/// A scatter of small dark pips over a surface, standing in for perforations.
_Mesh _pips(
    double cx, double cy, double z, int count, double spread, double pipR) {
  final faces = <_Face>[];
  for (var i = 0; i < count; i++) {
    final a = 2 * math.pi * i / count;
    final r = count.isEven ? (i.isEven ? spread * .55 : spread) : spread;
    final px = cx + r * math.cos(a);
    final py = cy + r * math.sin(a);
    final pip = _cyl(pipR, z, z + .02, sides: 6);
    final moved = _shift(pip, px, py, 0);
    faces.addAll(moved.faces);
  }
  return _Mesh(faces);
}

// --- the catalogue ---------------------------------------------------------

final Map<String, List<_Part>> _parts = {
  // --------------------------------------------------------- cutting & prep
  'knife': [
    _Part(_merge([
      _extrude(_rrect(-0.46, 0.0, 0.80, 0.19, 0.09), -0.05, 0.05, _wood),
      _extrude(_rrect(-0.04, 0.0, 0.10, 0.23, 0.03), -0.055, 0.055, _steelDark),
    ])),
    _Part(
      _extrude(const [
        Offset(-0.02, 0.14),
        Offset(0.58, 0.12),
        Offset(0.97, -0.01),
        Offset(0.34, -0.15),
        Offset(-0.02, -0.11),
      ], -0.032, 0.032, _steel),
      anim: _Anim.rock,
      pivot: const Offset(-0.02, 0.02),
      amount: .5,
    ),
  ],
  'paring_knife': [
    _Part(_merge([
      _extrude(_rrect(-0.52, 0.0, 0.62, 0.15, 0.07), -0.04, 0.04, _wood),
      _extrude(_rrect(-0.16, 0.0, 0.08, 0.19, 0.02), -0.045, 0.045, _steelDark),
    ])),
    _Part(
      _extrude(const [
        Offset(-0.12, 0.10),
        Offset(0.34, 0.09),
        Offset(0.76, -0.02),
        Offset(0.26, -0.12),
        Offset(-0.12, -0.09),
      ], -0.026, 0.026, _steel),
      anim: _Anim.rock,
      pivot: const Offset(-0.12, 0.0),
      amount: .6,
    ),
  ],
  'cleaver': [
    _Part(_merge([
      _extrude(_rrect(-0.40, 0.0, 0.56, 0.21, 0.08), -0.06, 0.06, _wood),
      _extrude(_rrect(-0.10, 0.0, 0.08, 0.26, 0.02), -0.065, 0.065, _steelDark),
    ])),
    _Part(
      _extrude(const [
        Offset(-0.06, 0.48),
        Offset(0.84, 0.46),
        Offset(0.92, -0.38),
        Offset(-0.06, -0.44),
      ], -0.028, 0.028, _steel),
      anim: _Anim.rock,
      pivot: const Offset(-0.06, -0.34),
      amount: .38,
    ),
  ],
  'kitchen_shears': [
    _Part(_merge([
      _shift(_layFlat(_cyl(0.055, -0.06, 0.06, sides: 10)), 0.02, 0.0, 0.0),
      _shift(_ringXY(0.22, 0.14, 0.05, _rubber), -0.44, 0.30, 0.0),
      _shift(_ringXY(0.24, 0.16, 0.05, _rubber), -0.44, -0.30, 0.0),
    ])),
    _Part(
      _extrude(const [
        Offset(0.0, -0.05),
        Offset(0.94, 0.12),
        Offset(0.96, 0.22),
        Offset(0.0, 0.07),
      ], -0.025, 0.025, _steel),
      anim: _Anim.press,
      pivot: const Offset(0.0, 0.0),
      amount: .5,
    ),
    _Part(
      _extrude(const [
        Offset(0.0, 0.05),
        Offset(0.88, -0.06),
        Offset(0.90, -0.16),
        Offset(0.0, -0.07),
      ], -0.025, 0.025, _steel),
      anim: _Anim.press,
      pivot: const Offset(0.0, 0.0),
      amount: -.5,
    ),
  ],
  'cutting_board': [
    // Tilting the board is how you present its face and read the grain, so the
    // whole slab rocks about its middle.
    _Part(
      _merge([
        _extrude(_rrect(0.0, 0.0, 1.72, 1.14, 0.14), -0.05, 0.05, _wood),
        _extrude(_rrect(0.0, 0.0, 1.40, 0.86, 0.10), 0.048, 0.056, _woodDark),
        _extrude(
          const [
            Offset(0.70, -0.07),
            Offset(0.82, -0.07),
            Offset(0.82, 0.07),
            Offset(0.70, 0.07)
          ],
          0.03,
          0.07,
          _black,
        ),
      ]),
      anim: _Anim.rock,
      pivot: const Offset(0.86, 0.57),
      amount: .22,
    ),
  ],
  'peeler': [
    _Part(_extrude(_rrect(-0.30, -0.62, 0.26, 0.72, 0.12), -0.06, 0.06, _wood)),
    _Part(
      _merge([
        _extrude(const [
          Offset(-0.18, -0.28),
          Offset(-0.62, 0.20),
          Offset(-0.62, 0.34),
          Offset(-0.10, -0.14),
        ], -0.03, 0.03, _steel),
        _extrude(const [
          Offset(0.18, -0.28),
          Offset(0.62, 0.20),
          Offset(0.62, 0.34),
          Offset(0.10, -0.14),
        ], -0.03, 0.03, _steel),
        _extrude(
            _rrect(0.0, 0.34, 1.24, 0.14, 0.04), -0.035, 0.035, _steelDark),
        _extrude(_rrect(0.0, 0.34, 1.10, 0.05, 0.02), -0.04, 0.04, _steel),
      ]),
      anim: _Anim.bob,
      pivot: const Offset(0.0, 0.0),
      amount: .8,
    ),
  ],
  'grater': [
    _Part(_merge([
      _extrude(const [
        Offset(-0.46, -0.74),
        Offset(0.46, -0.74),
        Offset(0.34, 0.42),
        Offset(0.0, 0.60),
        Offset(-0.34, 0.42),
      ], -0.16, 0.16, _steel),
      _extrude(const [
        Offset(-0.34, -0.62),
        Offset(0.34, -0.62),
        Offset(0.24, 0.34),
        Offset(0.0, 0.48),
        Offset(-0.24, 0.34),
      ], 0.155, 0.17, _steelDark),
      _extrude(_rrect(0.56, 0.30, 0.44, 0.18, 0.08), -0.05, 0.05, _black),
      _extrude(_rrect(0.56, 0.30, 0.14, 0.14, 0.04), -0.09, 0.09, _steel),
    ])),
    _Part(
      _merge([
        _extrude(_rrect(-0.16, -0.14, 0.26, 0.44, 0.04), 0.16, 0.19, _black),
        _extrude(_rrect(0.14, -0.14, 0.26, 0.44, 0.04), 0.16, 0.19, _black),
      ]),
      anim: _Anim.rock,
      pivot: const Offset(0.0, -0.74),
      amount: .3,
    ),
  ],
  'zester': [
    _Part(_merge([
      _extrude(_rrect(-0.44, -0.36, 0.62, 0.30, 0.13), -0.07, 0.07, _wood),
      _extrude(_rrect(-0.16, -0.30, 0.10, 0.40, 0.03), -0.08, 0.08, _steelDark),
    ])),
    _Part(
      _merge([
        _extrude(
          const [
            Offset(-0.12, 0.30),
            Offset(0.52, 0.62),
            Offset(0.66, 0.40),
            Offset(-0.06, 0.10)
          ],
          -0.035,
          0.035,
          _steel,
        ),
        _shift(_pips(0.30, 0.40, 0.03, 7, 0.20, 0.028), 0, 0, 0),
        _shift(_pips(0.30, 0.40, -0.05, 7, 0.20, 0.028), 0, 0, 0),
      ]),
      anim: _Anim.bob,
      amount: .9,
    ),
  ],
  'mandoline': [
    _Part(_merge([
      _extrude(const [
        Offset(-0.52, -0.60),
        Offset(0.52, -0.60),
        Offset(0.62, 0.52),
        Offset(-0.62, 0.52),
      ], -0.22, 0.22, _steelDark),
      _extrude(_rrect(-0.44, -0.52, 0.16, 0.30, 0.04), -0.30, 0.30, _rubber),
      _extrude(_rrect(0.44, -0.52, 0.16, 0.30, 0.04), -0.30, 0.30, _rubber),
      _extrude(const [
        Offset(-0.60, 0.30),
        Offset(0.60, 0.06),
        Offset(0.60, 0.20),
        Offset(-0.60, 0.44),
      ], -0.24, 0.24, _steel),
    ])),
    _Part(
      _merge([
        _extrude(_rrect(0.0, 0.16, 0.46, 0.40, 0.10), -0.20, 0.20, _silicone),
        _extrude(_rrect(0.0, -0.02, 0.20, 0.20, 0.06), -0.10, 0.10, _steelDark),
      ]),
      anim: _Anim.bob,
      pivot: const Offset(0.0, 0.52),
      amount: .9,
    ),
  ],

  // ------------------------------------------------------------- measuring
  'dry_measuring_cups': [
    _Part(_cup(0.56, 0.42, 0.52, 0.05, sides: 22, color: _steel)),
    _Part(
      _shift(_cup(0.44, 0.33, 0.44, 0.05, sides: 22), 0, 0.40, 0),
      anim: _Anim.fan,
      pivot: const Offset(0, 0),
      amount: .5,
    ),
    _Part(
      _shift(_cup(0.33, 0.25, 0.36, 0.045, sides: 22), 0, 0.80, 0),
      anim: _Anim.fan,
      pivot: const Offset(0, 0),
      amount: 1.0,
    ),
  ],
  'liquid_measuring_cup': [
    _Part(_merge([
      _cup(0.50, 0.40, 0.86, 0.05, sides: 24),
      _shift(_ringXY(0.26, 0.18, 0.06, _glass), 0.66, 0.44, 0),
      _extrude(const [
        Offset(0.34, 0.86),
        Offset(0.66, 0.80),
        Offset(0.50, 1.02),
      ], -0.06, 0.06, _glass),
      for (var i = 0; i < 4; i++)
        _extrude(_rrect(0.0, 0.18 + i * 0.17, 0.30, 0.022, 0.008), 0.49, 0.52,
            _steelDark),
    ])),
    _Part(
      _merge([
        _extrude(_rrect(0.0, 0.55, 0.44, 0.40, 0.10), 0.50, 0.53, _sugar),
      ]),
      anim: _Anim.rock,
      pivot: const Offset(0.0, 0.0),
      amount: .12,
    ),
  ],
  'measuring_spoons': [
    _Part(_merge([
      _extrude(_rrect(-0.46, 0.30, 0.78, 0.13, 0.06), -0.03, 0.03, _steel),
      _shift(_scoop(0.19, 0.15, 0.10, _steel), 0.06, 0.30, 0),
    ])),
    _Part(
      _merge([
        _extrude(_rrect(-0.40, 0.02, 0.72, 0.12, 0.055), -0.028, 0.028, _steel),
        _shift(_scoop(0.16, 0.13, 0.09, _steel), 0.02, 0.02, 0),
      ]),
      anim: _Anim.fan,
      pivot: const Offset(-0.78, 0.0),
      amount: .5,
    ),
    _Part(
      _merge([
        _extrude(_rrect(-0.34, -0.26, 0.66, 0.11, 0.05), -0.026, 0.026, _steel),
        _shift(_scoop(0.13, 0.11, 0.08, _steel), -0.02, -0.26, 0),
      ]),
      anim: _Anim.fan,
      pivot: const Offset(-0.78, 0.0),
      amount: 1.0,
    ),
  ],
  'kitchen_scale': [
    _Part(_merge([
      _extrude(_rrect(0.0, -0.22, 1.30, 0.56, 0.12), -0.28, 0.28, _rubber),
      _extrude(_rrect(0.0, 0.30, 1.14, 0.62, 0.10), -0.30, 0.30, _steel),
      _extrude(_rrect(0.0, -0.20, 0.54, 0.22, 0.05), 0.28, 0.31, _black),
      _extrude(_rrect(0.0, -0.20, 0.44, 0.13, 0.03), 0.30, 0.33, _amber),
    ])),
    // The zero dial turns as you level and tare the scale, so it is its own
    // part rather than fused into the body.
    _Part(
      _shift(_cyl(0.22, 0.0, 0.07, sides: 16), 0, 0.60, 0),
      anim: _Anim.roll,
      pivot: const Offset(0, 0.60),
      amount: .45,
    ),
  ],

  // ------------------------------------------------------- mixing & prep
  'bowl': [
    // The bowl and its inner wall are one shell, so they lift together the way
    // a mixing bowl is actually picked up and settled back down.
    _Part(
      _merge([
        _bowl(0.80, 0.66, 0.05, sides: 28),
        _shift(_bowl(0.52, 0.44, 0.045, sides: 24), 0, 0.30, 0),
      ]),
      anim: _Anim.bob,
      amount: .5,
    ),
    // The spoon is the only part that clears the rim, so it carries the stirring
    // gesture on its own.
    _Part(
      _merge([
        _shift(_cone(0.05, 0.07, 0.80, 0.03, color: _wood), 0, -0.72, 0),
        _shift(_scoop(0.20, 0.15, 0.09, _wood), 0, 0.26, 0),
      ]),
      anim: _Anim.sway,
      pivot: const Offset(0, 0),
      amount: .85,
    ),
  ],
  'whisk': [
    _Part(_merge([
      _shift(_cone(0.06, 0.11, 0.62, 0.03, color: _wood), 0, 0.30, 0),
      _shift(_tube(0.13, 0.07, 0.26, 0.36, sides: 16), 0, 0, 0),
    ])),
    _Part(
      _merge([
        _cyl(0.05, -0.30, -0.16, sides: 10),
        _wireCage(_whiskArc(), 6, 0.022),
      ]),
      anim: _Anim.sway,
      pivot: const Offset(0, 0),
      amount: .5,
    ),
  ],
  'wooden_spoon': [
    _Part(_shift(_cone(0.05, 0.09, 0.86, 0.03, color: _wood), 0, -0.78, 0)),
    _Part(
      _shift(_scoop(0.25, 0.18, 0.10, _wood), 0, 0.24, 0),
      anim: _Anim.sway,
      amount: .7,
    ),
  ],
  'spatula': [
    _Part(_merge([
      _extrude(_rrect(0.0, 0.36, 0.84, 0.52, 0.09), -0.025, 0.025, _silicone),
      _extrude(_rrect(0.0, 0.36, 0.80, 0.48, 0.09), -0.035, 0.035, _steelDark),
      _extrude(_rrect(0.0, 0.60, 0.26, 0.26, 0.06), 0.0, 0.05, _steel),
    ])),
    _Part(
      _extrude(_rrect(0.0, -0.34, 0.19, 0.72, 0.09), -0.05, 0.05, _wood),
      anim: _Anim.bob,
      amount: .6,
    ),
  ],
  'rubber_scraper': [
    _Part(_merge([
      _extrude(_rrect(0.0, 0.44, 1.06, 0.48, 0.05), -0.022, 0.022, _silicone),
      _extrude(_rrect(0.0, 0.68, 0.22, 0.26, 0.05), -0.045, 0.045, _black),
    ])),
    _Part(
      _extrude(_rrect(0.0, -0.30, 0.17, 0.68, 0.08), -0.05, 0.05, _black),
      anim: _Anim.bob,
      amount: .7,
    ),
  ],
  'rolling_pin': [
    // Rolling a pin is an axial twist, which a smooth cylinder hides, so the
    // motion is the visible press-and-roll that actually happens over dough.
    _Part(
      _merge([
        _axisX(_cyl(0.25, -0.58, 0.58, sides: 24)),
        _axisX(_cyl(0.06, 0.58, 0.94, sides: 12)),
        _axisX(_cyl(0.06, -0.94, -0.58, sides: 12)),
      ]),
      anim: _Anim.rock,
      amount: .45,
    ),
  ],
  'pastry_brush': [
    _Part(_merge([
      _shift(_cone(0.06, 0.09, 0.74, 0.03, color: _wood), 0, 0.16, 0),
      _shift(_tube(0.12, 0.07, 0.10, 0.22, sides: 14), 0, 0, 0),
      _shift(_ringXY(0.16, 0.12, 0.03, _wood), 0, 1.02, 0),
    ])),
    _Part(
      _merge([
        _extrude(const [
          Offset(-0.13, 0.10),
          Offset(0.13, 0.10),
          Offset(0.10, -0.42),
          Offset(-0.10, -0.42),
        ], -0.09, 0.09, _silicone),
      ]),
      anim: _Anim.bob,
      amount: .8,
    ),
  ],
  'mortar_pestle': [
    _Part(_merge([
      _bowl(0.62, 0.50, 0.08, sides: 24),
      _shift(_tube(0.64, 0.56, 0.44, 0.52, sides: 24), 0, 0, 0),
    ])),
    // A pestle is used standing proud of the mortar. Seating the whole pestle
    // down inside would hide the entire gesture behind opaque geometry.
    _Part(
      _merge([
        _shift(_sphere(0.17, rings: 6, sides: 14), 0, 0.10, 0),
        _shift(_cone(0.10, 0.17, 0.66, 0.04, color: _stone), 0, 0.20, 0),
      ]),
      anim: _Anim.sway,
      pivot: const Offset(0, 0.20),
      amount: .8,
    ),
  ],
  'potato_masher': [
    _Part(_shift(_cone(0.05, 0.08, 0.80, 0.03, color: _black), 0, 0.28, 0)),
    _Part(
      _merge([
        _extrude(_rrect(0.0, -0.32, 0.86, 0.40, 0.14), -0.05, 0.05, _steel),
        _extrude(_rrect(0.0, -0.32, 0.74, 0.10, 0.04), -0.07, 0.07, _steelDark),
        for (var i = 0; i < 5; i++)
          _extrude(_rrect(-0.32 + i * 0.16, -0.32, 0.05, 0.34, 0.02), -0.06,
              0.06, _steelDark),
      ]),
      anim: _Anim.press,
      pivot: const Offset(0, 0.28),
      amount: .5,
    ),
  ],
  'garlic_press': [
    _Part(_merge([
      _extrude(_rrect(0.0, 0.28, 0.52, 0.52, 0.12), -0.16, 0.16, _steel),
      _shift(_tube(0.28, 0.20, 0.10, 0.30, sides: 16), 0, 0, 0),
    ])),
    _Part(
      _merge([
        _shift(_cone(0.13, 0.13, 0.16, 0.04, color: _steelDark), 0, 0.06, 0),
        _extrude(_rrect(0.0, 0.02, 0.16, 0.30, 0.06), -0.09, 0.09, _steel),
      ]),
      anim: _Anim.press,
      pivot: const Offset(0, 0.54),
      amount: .7,
    ),
    _Part(
      _merge([
        _extrude(_rrect(0.24, -0.34, 0.52, 0.17, 0.08), -0.05, 0.05, _silicone),
        _extrude(
            _rrect(-0.24, -0.34, 0.52, 0.17, 0.08), -0.05, 0.05, _silicone),
      ]),
      anim: _Anim.press,
      pivot: const Offset(0, -0.02),
      amount: -.8,
    ),
  ],

  // ------------------------------------------------------ straining & clean
  'colander': [
    _Part(_merge([
      _shift(_bowl(0.72, 0.52, 0.04, sides: 26), 0, -0.10, 0),
      _shift(_pips(0.0, 0.06, -0.30, 12, 0.40, 0.030), 0, 0, 0),
      _shift(_pips(0.0, 0.06, 0.30, 12, 0.40, 0.030), 0, 0, 0),
      _shift(_tube(0.76, 0.70, 0.38, 0.48, sides: 26), 0, -0.10, 0),
    ])),
    _Part(
      _merge([
        _shift(_ringXY(0.20, 0.13, 0.07, _steel), 0.86, 0.34, 0),
        _shift(_ringXY(0.20, 0.13, 0.07, _steel), -0.86, 0.34, 0),
      ]),
      anim: _Anim.rock,
      pivot: const Offset(0, 0),
      amount: .18,
    ),
  ],
  'strainer': [
    _Part(_merge([
      _shift(
          _bowl(0.66, 0.34, 0.035, sides: 24, color: _steelDark), 0, -0.06, 0),
      _shift(_tube(0.68, 0.62, 0.24, 0.32, sides: 24), 0, -0.06, 0),
    ])),
    _Part(
      _extrude(_rrect(0.94, 0.16, 0.62, 0.12, 0.05), -0.045, 0.045, _steel),
      anim: _Anim.rock,
      pivot: const Offset(0.66, 0.24),
      amount: .22,
    ),
  ],
  'sieve': [
    _Part(_merge([
      _shift(
          _tube(0.52, 0.46, -0.42, 0.34, sides: 24, color: _ceramic), 0, 0, 0),
      _shift(_tube(0.56, 0.48, 0.32, 0.42, sides: 24), 0, 0, 0),
      _shift(_tube(0.56, 0.48, -0.44, -0.34, sides: 24), 0, 0, 0),
    ])),
    _Part(
      _merge([
        _extrude(_rrect(0.82, 0.10, 0.56, 0.12, 0.05), -0.045, 0.045, _wood),
        _shift(_tube(0.14, 0.09, -0.05, 0.05, sides: 12), 0.52, 0.10, 0),
      ]),
      anim: _Anim.rock,
      pivot: const Offset(0.50, 0.10),
      amount: .3,
    ),
  ],
  'funnel': [
    _Part(_merge([
      _shift(_cone(0.52, 0.11, 0.56, 0.035), 0, 0.22, 0),
      _shift(_tube(0.60, 0.53, 0.74, 0.84, sides: 24), 0, 0, 0),
    ])),
    // The stem carries the pouring tilt while the cone stays planted.
    _Part(
      _shift(_cyl(0.11, -0.62, 0.24, sides: 16), 0, 0, 0),
      anim: _Anim.sway,
      pivot: const Offset(0, 0.22),
      amount: .30,
    ),
  ],

  // ------------------------------------------------- cooking & serving
  'ladle': [
    _Part(_shift(_cone(0.05, 0.08, 0.96, 0.03, color: _steel), 0, -0.30, 0)),
    _Part(
      _shift(_bowl(0.34, 0.30, 0.04, sides: 20), 0, -0.60, 0),
      anim: _Anim.lift,
      amount: .8,
    ),
  ],
  'tongs': [
    _Part(_merge([
      _shift(_layFlat(_cyl(0.07, -0.05, 0.05, sides: 10)), 0, 0.90, 0),
      _shift(
          _extrude(
              _rrect(0.74, 0.44, 0.30, 0.13, 0.06), -0.06, 0.06, _silicone),
          0,
          0,
          0),
      _shift(
          _extrude(
              _rrect(0.74, -0.44, 0.30, 0.13, 0.06), -0.06, 0.06, _silicone),
          0,
          0,
          0),
    ])),
    _Part(
      _extrude(_tongArm(1), -0.035, 0.035, _steel),
      anim: _Anim.press,
      pivot: const Offset(0, 0.90),
      amount: .38,
    ),
    _Part(
      _extrude(_tongArm(-1), -0.035, 0.035, _steel),
      anim: _Anim.press,
      pivot: const Offset(0, 0.90),
      amount: -.38,
    ),
  ],
  'turner': [
    _Part(_slottedBlade(0.0, 0.30, 0.82, 0.56, 0.0, 4)),
    _Part(
      _merge([
        _extrude(_rrect(0.0, 0.56, 0.30, 0.22, 0.06), -0.05, 0.05, _steelDark),
        _extrude(_rrect(0.0, -0.34, 0.20, 0.78, 0.10), -0.06, 0.06, _wood),
      ]),
      anim: _Anim.lever,
      pivot: const Offset(0, -0.70),
      amount: .5,
    ),
  ],
  'pasta_server': [
    _Part(_extrude(_rrect(-0.44, 0.02, 0.66, 0.13, 0.06), -0.05, 0.05, _wood)),
    _Part(
      _merge([
        _shift(_scoop(0.34, 0.28, 0.13, _steel), 0.34, -0.24, 0),
        for (var i = 0; i < 5; i++)
          _extrude(_rrect(0.08 + i * 0.14, -0.46, 0.055, 0.28, 0.025), -0.03,
              0.03, _steel),
      ]),
      anim: _Anim.lift,
      amount: .7,
    ),
  ],
  'baster': [
    _Part(_merge([
      _shift(_sphere(0.36, rings: 8, sides: 18), 0, -0.10, 0),
      _shift(_cone(0.05, 0.12, 0.40, 0.025, color: _rubber), 0, 0.26, 0),
    ])),
    _Part(
      _merge([
        _shift(_cyl(0.09, 0.40, 0.72, sides: 12), 0, 0, 0),
        _shift(_cyl(0.17, 0.70, 0.82, sides: 14), 0, 0, 0),
      ]),
      anim: _Anim.press,
      pivot: const Offset(0, 0.70),
      amount: .4,
    ),
  ],
  'dredger': [
    _Part(_merge([
      _shift(_tube(0.38, 0.34, -0.30, 0.20, sides: 20, color: _steelDark), 0, 0,
          0),
      _shift(_sphere(0.38, rings: 5, sides: 18), 0, 0.20, 0),
    ])),
    _Part(
      _merge([
        _shift(_cyl(0.13, 0.40, 0.52, sides: 12), 0, 0, 0),
        _extrude(_rrect(0.0, 0.62, 0.26, 0.22, 0.10), -0.05, 0.05, _silicone),
      ]),
      anim: _Anim.rock,
      pivot: const Offset(0, 0.20),
      amount: .3,
    ),
  ],
  'skimmer': [
    _Part(_slottedBlade(0.0, 0.28, 0.74, 0.44, 0.0, 3)),
    _Part(
      _merge([
        _extrude(_rrect(0.0, 0.50, 0.26, 0.20, 0.06), -0.05, 0.05, _steelDark),
        _extrude(_rrect(0.0, -0.34, 0.17, 0.80, 0.08), -0.05, 0.05, _steel),
        _shift(_ringXY(0.15, 0.10, 0.05, _steel), 0, -0.82, 0),
      ]),
      anim: _Anim.bob,
      pivot: const Offset(0, -0.74),
      amount: .8,
    ),
  ],

  // ------------------------------------------------------ misc & accessories
  'can_opener': [
    _Part(_merge([
      _shift(_layFlat(_cyl(0.09, -0.06, 0.06, sides: 12)), 0.06, -0.10, 0),
      _extrude(_rrect(-0.10, 0.16, 0.34, 0.16, 0.07), -0.05, 0.05, _steelDark),
    ])),
    _Part(
      _merge([
        _extrude(_rrect(-0.44, 0.44, 0.72, 0.20, 0.09), -0.05, 0.05, _silicone),
        _extrude(_rrect(-0.44, 0.16, 0.66, 0.18, 0.08), -0.045, 0.045, _black),
      ]),
      anim: _Anim.press,
      pivot: const Offset(0.0, 0.24),
      amount: .45,
    ),
    _Part(
      _merge([
        _extrude(_rrect(0.56, 0.02, 0.34, 0.09, 0.04), -0.035, 0.035, _steel),
        _extrude(_rrect(0.78, 0.26, 0.09, 0.52, 0.04), -0.035, 0.035, _steel),
      ]),
      anim: _Anim.crank,
      pivot: const Offset(0.06, -0.10),
      amount: .5,
    ),
  ],
  'bottle_opener': [
    _Part(_merge([
      _extrude(const [
        Offset(-0.86, 0.16),
        Offset(0.10, 0.30),
        Offset(0.42, 0.16),
        Offset(0.20, 0.04),
        Offset(0.42, -0.08),
        Offset(0.10, -0.22),
        Offset(-0.86, -0.06),
      ], -0.05, 0.05, _steel),
      _extrude(_rrect(-0.62, 0.05, 0.48, 0.20, 0.09), -0.07, 0.07, _rubber),
    ])),
    _Part(
      _extrude(_rrect(0.30, 0.40, 0.34, 0.11, 0.05), -0.045, 0.045, _steel),
      anim: _Anim.lever,
      pivot: const Offset(-0.10, 0.04),
      amount: .55,
    ),
  ],
  'corkscrew': [
    _Part(_merge([
      _shift(_cone(0.16, 0.20, 0.44, 0.05, color: _wood), 0, 0.22, 0),
      _shift(_tube(0.19, 0.13, 0.14, 0.24, sides: 14), 0, 0, 0),
    ])),
    _Part(
      _merge([
        _shift(_ringXY(0.28, 0.19, 0.06, _wood), 0, 0.78, 0),
        _shift(_cyl(0.05, -0.30, 0.14, sides: 10), 0, 0, 0),
        _helix(0.24, 0.05, 5),
      ]),
      anim: _Anim.crank,
      pivot: const Offset(0, 0.14),
      amount: .6,
    ),
  ],
  'sharpening_steel': [
    _Part(_merge([
      _mapVerts(_shift(_cone(0.035, 0.075, 0.96, 0.02), 0, -0.48, 0), (p) {
        const a = -.62;
        final c = math.cos(a);
        final s = math.sin(a);
        return _V(p.x, p.y * c - p.z * s, p.y * s + p.z * c);
      }),
      _extrude(const [
        Offset(-0.10, -0.90),
        Offset(0.16, -0.94),
        Offset(0.22, -0.52),
        Offset(-0.06, -0.48),
      ], -0.07, 0.07, _wood),
    ])),
    _Part(
      _merge([
        _extrude(
            _rrect(0.44, -0.62, 0.20, 0.92, 0.06), -0.035, 0.035, _steelDark),
        _extrude(_rrect(0.44, -0.62, 0.13, 0.84, 0.04), -0.045, 0.045, _amber),
      ]),
      anim: _Anim.rock,
      pivot: const Offset(0.20, -0.40),
      amount: .45,
    ),
  ],
  'oven_mitts': [
    _Part(_merge([
      _extrude(_mitt(-0.46, sign: -1), -0.07, 0.07, _silicone),
      _extrude(_rrect(-0.44, -0.62, 0.44, 0.24, 0.07), -0.075, 0.075, _rubber),
    ])),
    _Part(
      _merge([
        _extrude(_mitt(0.46), -0.07, 0.07, _sugar),
        _extrude(_rrect(0.44, -0.62, 0.44, 0.24, 0.07), -0.075, 0.075, _rubber),
      ]),
      anim: _Anim.sway,
      pivot: const Offset(0.44, 0.7),
      amount: .3,
    ),
  ],
};

// --- late-bound shape helpers ---------------------------------------------
//
// These sit below the catalogue so the map above reads as one block of tool
// definitions rather than as a wall of coordinate maths.

/// One curved tong arm, mirrored by [sign]. Pivot end is at the top.
List<Offset> _tongArm(double sign) => [
      Offset(0.05 * sign, 0.94),
      Offset(0.19 * sign, 0.90),
      Offset(0.22 * sign, 0.16),
      Offset(0.34 * sign, -0.48),
      Offset(0.48 * sign, -0.80),
      Offset(0.64 * sign, -0.74),
      Offset(0.48 * sign, -0.36),
      Offset(0.36 * sign, 0.20),
      Offset(0.33 * sign, 0.88),
    ];

/// A corkscrew wire: small beads laid along a rising spiral. At lesson scale
/// this reads as a helix without needing a swept-tube solver.
_Mesh _helix(double radius, double wire, int steps) {
  final faces = <_Face>[];
  const turns = 2.4;
  final bead = _extrude(
      _rrect(0, 0, wire * 1.6, wire * 1.6, wire * .5), -wire, wire, _steel);
  for (var i = 0; i < steps; i++) {
    final t = i / (steps - 1);
    final a = t * turns * 2 * math.pi;
    final y = -0.30 + t * 0.44;
    faces.addAll(
        _shift(bead, radius * math.cos(a), y, radius * math.sin(a)).faces);
  }
  return _Mesh(faces);
}

/// A quilted oven mitt, with the thumb on the side given by [sign].
List<Offset> _mitt(double cx, {double sign = 1}) {
  Offset p(double x, double y) => Offset(cx + x * sign, y);
  return [
    p(-0.30, -0.50),
    p(-0.34, 0.10),
    p(-0.24, 0.44),
    p(0.10, 0.50),
    p(0.30, 0.32),
    p(0.26, 0.12),
    p(0.50, 0.06),
    p(0.54, -0.16),
    p(0.38, -0.34),
    p(0.20, -0.50),
  ];
}
