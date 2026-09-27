import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/tool_model.dart';
import 'frame_preprocessor.dart';

class DetectionResult {
  final ToolModel? tool;
  final double confidence;
  final String statusMessage;
  final int processingMilliseconds;
  const DetectionResult(
      {required this.tool,
      required this.confidence,
      required this.statusMessage,
      this.processingMilliseconds = 0});
  bool get isRecognized =>
      tool != null &&
      confidence.isFinite &&
      confidence >= ToolDetector.confidenceThreshold &&
      confidence <= 1;
}

class ToolDetector {
  static const confidenceThreshold = .65;

  /// The only tool names the bundled COCO model can actually produce. The
  /// library is far larger, so every other tool is reached through the manual
  /// picker instead of pretending the camera understands it.
  static const supportedToolIds = {'knife', 'bowl'};

  /// Ready-state copy for the camera banner. Kept free of tool names so the
  /// banner never implies a coverage the model does not have.
  static const supportedToolsMessage = 'Camera ready';

  /// Copy for a frame the model ran on without finding anything scannable.
  /// Exposed as a constant so the UI and the native smoke test cannot drift
  /// apart the way a duplicated string literal did.
  static const noMatchMessage =
      'No match yet — center the tool, or pick it from the library';

  /// Plain statement of how much of the library automatic recognition covers.
  static String get recognitionScopeNotice =>
      'Automatic recognition covers ${supportedToolIds.length} of '
      '${kBuiltInTools.length} tools. Open any other tool from the library.';

  final AssetBundle _assets;
  Interpreter? _interpreter;
  Future<DetectionResult>? _pending;
  Future<void>? _loading;
  bool _disposed = false;
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;
  String? loadError;
  List<String> _labels = [];
  ToolDetector({AssetBundle? assets}) : _assets = assets ?? rootBundle;

  Future<void> loadModel() => _loading ??= _loadModel();
  Future<void> _loadModel() async {
    if (_disposed || _isLoaded) return;
    Interpreter? candidate;
    try {
      final data = await _assets.load('assets/models/ssd_mobilenet.tflite');
      if (_disposed) return;
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      if (bytes.length < 8 ||
          String.fromCharCodes(bytes.sublist(4, 8)) != 'TFL3') {
        throw const FormatException(
            'A trained TensorFlow Lite model is required.');
      }
      final labels = (await _assets.loadString('assets/models/labels.txt'))
          .trim()
          .split(RegExp(r'\r?\n'))
          .map((line) => line.trim())
          .toList();
      if (_disposed) return;
      // This release ships one known model and its embedded COCO label order.
      if (labels.length != 90 ||
          labels[48] != 'knife' ||
          labels[50] != 'bowl') {
        throw const FormatException(
            'Labels do not match the bundled COCO model.');
      }
      final options = InterpreterOptions()..threads = 2;
      try {
        candidate = Interpreter.fromBuffer(bytes, options: options);
      } finally {
        options.delete();
      }
      final inputs = candidate.getInputTensors();
      final outputs = candidate.getOutputTensors();
      const shapes = [
        [1, 10, 4],
        [1, 10],
        [1, 10],
        [1]
      ];
      if (inputs.length != 1 ||
          inputs.first.type != TensorType.uint8 ||
          !listEquals(inputs.first.shape, [1, 300, 300, 3]) ||
          outputs.length != 4 ||
          List.generate(4, (i) => i).any((i) =>
              outputs[i].type != TensorType.float32 ||
              !listEquals(outputs[i].shape, shapes[i]))) {
        throw const FormatException('Unsupported model tensor format.');
      }
      _interpreter = candidate;
      _labels = labels;
      _isLoaded = true;
      loadError = null;
    } catch (error) {
      candidate?.close();
      _isLoaded = false;
      loadError =
          'Automatic recognition is unavailable. Choose a tool to continue.';
      debugPrint('Tool detector could not load: $error');
    }
  }

  /// Uses the zero-based labels embedded in the distributed model.
  static DetectionResult selectDetection(List<double> classes,
      List<double> scores, double count, List<String> labels,
      {List<List<double>>? boxes, int processingMilliseconds = 0}) {
    if (!count.isFinite ||
        count < 0 ||
        count != count.truncateToDouble() ||
        count > classes.length ||
        count > scores.length ||
        (boxes != null && count > boxes.length)) {
      return const DetectionResult(
          tool: null, confidence: 0, statusMessage: 'Invalid detection output');
    }
    ToolModel? best;
    double confidence = 0;
    for (var i = 0; i < count.toInt(); i++) {
      final value = classes[i];
      final score = scores[i];
      if (!value.isFinite ||
          value < 0 ||
          value != value.truncateToDouble() ||
          value >= labels.length ||
          !score.isFinite ||
          score < confidenceThreshold ||
          score > 1 ||
          score <= confidence) {
        continue;
      }
      final label = labels[value.toInt()];
      if (!supportedToolIds.contains(label)) continue;
      if (boxes != null) {
        final box = boxes[i];
        if (box.length != 4 ||
            box.any((n) => !n.isFinite) ||
            box[2] <= box[0] ||
            box[3] <= box[1]) {
          continue;
        }
        final centerX = (box[1] + box[3]) / 2;
        final centerY = (box[0] + box[2]) / 2;
        if (centerX < .15 || centerX > .85 || centerY < .15 || centerY > .85) {
          continue;
        }
      }
      for (final tool in kBuiltInTools) {
        if (tool.id == label) {
          best = tool;
          confidence = score;
          break;
        }
      }
    }
    return DetectionResult(
        tool: best,
        confidence: confidence,
        processingMilliseconds: processingMilliseconds,
        statusMessage: best == null ? noMatchMessage : 'Possible match: ${best.name}');
  }

  Future<DetectionResult> processCameraImage(CameraImage image,
      {int rotation = 0}) {
    try {
      return processFrame(DetectionFrame.fromCamera(image, rotation));
    } catch (_) {
      return Future.value(const DetectionResult(
          tool: null,
          confidence: 0,
          statusMessage: 'Unsupported camera image. Choose a tool manually.'));
    }
  }

  /// Also used by the native smoke test. Only one worker may use the interpreter.
  Future<DetectionResult> processFrame(DetectionFrame frame) {
    if (!isLoaded || _disposed) {
      return Future.value(const DetectionResult(
          tool: null,
          confidence: 0,
          statusMessage:
              'Automatic recognition is unavailable. Choose a tool to continue.'));
    }
    if (_pending != null) return _pending!;
    final task = _run(frame);
    _pending = task;
    return task;
  }

  Future<DetectionResult> _run(DetectionFrame frame) async {
    try {
      return await compute(
          _inferFrame, _InferenceJob(_interpreter!.address, frame, _labels));
    } catch (error) {
      debugPrint('Tool inference failed: $error');
      return const DetectionResult(
          tool: null,
          confidence: 0,
          statusMessage:
              'Unable to process camera image. Try again or choose a tool.');
    } finally {
      _pending = null;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _isLoaded = false;
    final interpreter = _interpreter;
    _interpreter = null;
    // Never release native memory while a background inference owns its address.
    if (_pending case final pending?) {
      pending.whenComplete(() => interpreter?.close());
    } else {
      interpreter?.close();
    }
  }
}

class _InferenceJob {
  final int address;
  final DetectionFrame frame;
  final List<String> labels;
  const _InferenceJob(this.address, this.frame, this.labels);
}

DetectionResult _inferFrame(_InferenceJob job) {
  final timer = Stopwatch()..start();
  final prepared = prepareFrame(job.frame);
  if (prepared.luminance < 35) {
    return DetectionResult(
        tool: null,
        confidence: 0,
        processingMilliseconds: timer.elapsedMilliseconds,
        statusMessage: 'Too dark — improve lighting or turn on the torch');
  }
  final interpreter = Interpreter.fromAddress(job.address, allocated: true);
  final boxes =
      List.generate(1, (_) => List.generate(10, (_) => List.filled(4, 0.0)));
  final classes = [List.filled(10, 0.0)];
  final scores = [List.filled(10, 0.0)];
  final count = [0.0];
  interpreter.runForMultipleInputs(
      [prepared.rgb.buffer], {0: boxes, 1: classes, 2: scores, 3: count});
  // The UI isolate owns this interpreter. Do not close it from the worker.
  return ToolDetector.selectDetection(
      classes[0], scores[0], count[0], job.labels,
      boxes: boxes[0], processingMilliseconds: timer.elapsedMilliseconds);
}
