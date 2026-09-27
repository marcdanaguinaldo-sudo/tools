import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

class FramePlane {
  final Uint8List bytes;
  final int rowStride;
  final int pixelStride;
  const FramePlane(this.bytes, this.rowStride, this.pixelStride);
}

/// Plain data sent to the inference worker. No camera or platform handles.
class DetectionFrame {
  final int width;
  final int height;
  final bool bgra;
  final int rotation;
  final List<FramePlane> planes;
  const DetectionFrame(
      {required this.width,
      required this.height,
      required this.bgra,
      required this.rotation,
      required this.planes});

  factory DetectionFrame.fromCamera(CameraImage image, int rotation) {
    if (image.format.group != ImageFormatGroup.yuv420 &&
        image.format.group != ImageFormatGroup.bgra8888) {
      throw const FormatException('Unsupported camera pixel format');
    }
    return DetectionFrame(
        width: image.width,
        height: image.height,
        bgra: image.format.group == ImageFormatGroup.bgra8888,
        rotation: rotation,
        planes: image.planes
            .map((plane) => FramePlane(
                plane.bytes, plane.bytesPerRow, plane.bytesPerPixel ?? 1))
            .toList());
  }
}

class PreparedFrame {
  final Uint8List rgb;
  final double luminance;
  const PreparedFrame(this.rgb, this.luminance);
}

int androidFrameRotation(int sensorOrientation, DeviceOrientation orientation,
    {bool frontFacing = false}) {
  final degrees = switch (orientation) {
    DeviceOrientation.portraitUp => 0,
    DeviceOrientation.landscapeLeft => 90,
    DeviceOrientation.portraitDown => 180,
    DeviceOrientation.landscapeRight => 270,
  };
  return (sensorOrientation + (frontFacing ? degrees : -degrees)) % 360;
}

/// Center-crops the upright frame and samples directly into the quantized model
/// input, avoiding a full-resolution RGB allocation on every camera callback.
PreparedFrame prepareFrame(DetectionFrame frame, {int size = 300}) {
  if (frame.width <= 0 ||
      frame.height <= 0 ||
      size <= 0 ||
      ![0, 90, 180, 270].contains(frame.rotation) ||
      frame.planes.length != (frame.bgra ? 1 : 3)) {
    throw const FormatException('Invalid camera frame');
  }
  final sideways = frame.rotation == 90 || frame.rotation == 270;
  final uprightWidth = sideways ? frame.height : frame.width;
  final uprightHeight = sideways ? frame.width : frame.height;
  final side = uprightWidth < uprightHeight ? uprightWidth : uprightHeight;
  final left = (uprightWidth - side) ~/ 2;
  final top = (uprightHeight - side) ~/ 2;
  final result = Uint8List(size * size * 3);
  var offset = 0;
  double luminance = 0;
  int sample(FramePlane plane, int x, int y) =>
      plane.bytes[y * plane.rowStride + x * plane.pixelStride];
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final ox = left + ((x + .5) * side / size).floor().clamp(0, side - 1);
      final oy = top + ((y + .5) * side / size).floor().clamp(0, side - 1);
      final (sx, sy) = switch (frame.rotation) {
        90 => (oy, frame.height - 1 - ox),
        180 => (frame.width - 1 - ox, frame.height - 1 - oy),
        270 => (frame.width - 1 - oy, ox),
        _ => (ox, oy),
      };
      int r, g, b;
      if (frame.bgra) {
        final plane = frame.planes[0];
        final i = sy * plane.rowStride + sx * 4;
        b = plane.bytes[i];
        g = plane.bytes[i + 1];
        r = plane.bytes[i + 2];
      } else {
        final luma = sample(frame.planes[0], sx, sy);
        final u = sample(frame.planes[1], sx ~/ 2, sy ~/ 2) - 128;
        final v = sample(frame.planes[2], sx ~/ 2, sy ~/ 2) - 128;
        final yy = 1.164 * (luma - 16);
        r = (yy + 1.596 * v).round().clamp(0, 255);
        g = (yy - .392 * u - .813 * v).round().clamp(0, 255);
        b = (yy + 2.017 * u).round().clamp(0, 255);
      }
      result[offset++] = r;
      result[offset++] = g;
      result[offset++] = b;
      luminance += .299 * r + .587 * g + .114 * b;
    }
  }
  return PreparedFrame(result, luminance / (size * size));
}
