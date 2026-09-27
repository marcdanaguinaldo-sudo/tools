import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_tool_scanner/services/frame_preprocessor.dart';
import 'package:kitchen_tool_scanner/services/detector.dart';

void main() {
  test('BGRA conversion honors row padding and clockwise rotation', () {
    final bytes = Uint8List.fromList([
      0,
      0,
      255,
      255,
      0,
      255,
      0,
      255,
      9,
      9,
      9,
      9,
      255,
      0,
      0,
      255,
      255,
      255,
      255,
      255,
      9,
      9,
      9,
      9,
    ]);
    DetectionFrame frame(int rotation) => DetectionFrame(
        width: 2,
        height: 2,
        bgra: true,
        rotation: rotation,
        planes: [FramePlane(bytes, 12, 4)]);
    expect(prepareFrame(frame(0), size: 2).rgb,
        [255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 255]);
    expect(prepareFrame(frame(90), size: 2).rgb,
        [0, 0, 255, 255, 0, 0, 255, 255, 255, 0, 255, 0]);
    expect(prepareFrame(frame(180), size: 2).rgb,
        [255, 255, 255, 0, 0, 255, 0, 255, 0, 255, 0, 0]);
    expect(prepareFrame(frame(270), size: 2).rgb,
        [0, 255, 0, 255, 255, 255, 255, 0, 0, 0, 0, 255]);
  });

  test('rectangular frames use the central square', () {
    final bytes = Uint8List.fromList([
      for (var y = 0; y < 2; y++)
        for (var x = 0; x < 4; x++) ...[x * 40, 0, 0, 255],
    ]);
    final result = prepareFrame(
        DetectionFrame(
            width: 4,
            height: 2,
            bgra: true,
            rotation: 0,
            planes: [FramePlane(bytes, 16, 4)]),
        size: 2);
    expect(result.rgb, [0, 0, 40, 0, 0, 80, 0, 0, 40, 0, 0, 80]);
  });

  test('YUV conversion honors independent pixel and row strides', () {
    final frame =
        DetectionFrame(width: 2, height: 2, bgra: false, rotation: 0, planes: [
      FramePlane(Uint8List.fromList([16, 235, 0, 16, 235, 0]), 3, 1),
      FramePlane(Uint8List.fromList([128, 9]), 2, 2),
      FramePlane(Uint8List.fromList([128, 9, 9]), 3, 1),
    ]);
    expect(prepareFrame(frame, size: 2).rgb,
        [0, 0, 0, 255, 255, 255, 0, 0, 0, 255, 255, 255]);
  });

  test('Android rotation accounts for sensor and device direction', () {
    expect(androidFrameRotation(90, DeviceOrientation.portraitUp), 90);
    expect(androidFrameRotation(90, DeviceOrientation.portraitDown), 270);
    expect(androidFrameRotation(90, DeviceOrientation.landscapeLeft), 0);
    expect(
        androidFrameRotation(270, DeviceOrientation.landscapeLeft,
            frontFacing: true),
        0);
  });

  test('unsupported tutorial names and off-center predictions are rejected',
      () {
    for (final label in ['whisk', 'peeler', 'tongs', 'mandoline', 'spoon']) {
      expect(ToolDetector.selectDetection([0], [.99], 1, [label]).isRecognized,
          isFalse);
    }
    expect(
        ToolDetector.selectDetection([0], [.9], 1, ['knife'],
            boxes: [
              [0, 0, .1, .1]
            ]).isRecognized,
        isFalse);
    expect(
        ToolDetector.selectDetection([0], [.9], 1, ['knife'],
            boxes: [
              [.2, .2, .8, .8]
            ]).isRecognized,
        isTrue);
    expect(ToolDetector.selectDetection([0], [.9], 2, ['knife']).isRecognized,
        isFalse);
  });
}
