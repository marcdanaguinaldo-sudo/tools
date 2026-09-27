import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kitchen_tool_scanner/services/detector.dart';
import 'package:kitchen_tool_scanner/services/frame_preprocessor.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('bundled model loads and runs native inference on the device',
      (tester) async {
    final detector = ToolDetector();
    await detector.loadModel();
    expect(detector.isLoaded, isTrue, reason: detector.loadError);
    final plane = Uint8List(300 * 300 * 4);
    for (var i = 0; i < plane.length; i += 4) {
      plane[i] = plane[i + 1] = plane[i + 2] = 128;
      plane[i + 3] = 255;
    }
    final frame = DetectionFrame(
        width: 300,
        height: 300,
        bgra: true,
        rotation: 0,
        planes: [FramePlane(plane, 1200, 4)]);
    final timings = <int>[];
    for (var i = 0; i < 5; i++) {
      final result = await detector.processFrame(frame);
      expect(result.statusMessage, ToolDetector.noMatchMessage);
      expect(result.isRecognized, isFalse);
      timings.add(result.processingMilliseconds);
    }
    debugPrint('Native preprocessing + inference times (ms): $timings');
    final pending = detector.processFrame(frame);
    detector.dispose();
    await pending;
    expect(detector.isLoaded, isFalse);
    detector.dispose();
  });
}
