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

  /// True when the frame was rejected purely for being too dark, so the scanner
  /// can light the scene instead of asking the user to find a lamp.
  final bool autoTorchRecommended;
  const DetectionResult(
      {required this.tool,
      required this.confidence,
      required this.statusMessage,
      this.processingMilliseconds = 0,
      this.autoTorchRecommended = false});
  bool get isRecognized =>
      tool != null &&
      confidence.isFinite &&
      confidence >= ToolDetector.confidenceThreshold &&
      confidence <= 1;
}

class ToolDetector {
  static const confidenceThreshold = .65;

  /// COCO label -> catalog tool id. The model emits COCO class names (e.g. 'scissors');
  /// the catalogue uses stable tool ids (e.g. 'kitchen_shears'). They are different
  /// domains, so keep the mapping explicit. Adding or renaming a tool id must update
  /// this map, not the old supportedToolIds set.
  static const Map<String, String> labelToToolId = {
    'knife': 'knife',
    'bowl': 'bowl',
    'scissors': 'kitchen_shears',
  };

  /// Tool ids the camera can actually name, for UI copy. Derived from the mapping
  /// so the two surfaces (detection + picker) can never drift.
  static Set<String> get supportedToolIds => labelToToolId.values.toSet();

  /// Catalogue tool-by-id, precomputed once for O(1) detection lookups.
  static final Map<String, ToolModel> _toolsById = {
    for (final t in kBuiltInTools) t.id: t
  };

  /// Ready-state copy for the camera banner. Kept free of tool names so the
  /// banner never implies a coverage the model does not have.
  static const supportedToolsMessage = 'Camera ready';

  /// Copy for a frame the model ran on without finding anything scannable.
  /// Exposed as a constant so the UI and the native smoke test cannot drift
  /// apart the way a duplicated string literal did.
  static const noMatchMessage =
      'No match yet — center the tool, or pick it from the library';

  /// Lowest score that still earns a guidance hint in the HUD. Below the
  /// confirmation threshold nothing can confirm a lesson, but naming what the
  /// model likely sees turns a dead-end 'no match' into actionable advice.
  static const candidateFloor = .40;

  /// COCO classes the camera commonly sees in a kitchen that have no lesson
  /// mapping. Naming them keeps the HUD honest about what the model sees —
  /// a spoon is named, never aliased to a lesson.
  static const _kitchenNeighbors = {
    'fork',
    'spoon',
    'plate',
    'cup',
    'wine glass',
    'bottle',
    'blender',
  };

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
          labels[50] != 'bowl' ||
          labels[86] != 'scissors') {
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
    bool centered(List<double> box) {
      final centerX = (box[1] + box[3]) / 2;
      final centerY = (box[0] + box[2]) / 2;
      return centerX >= .15 && centerX <= .85 && centerY >= .15 && centerY <= .85;
    }

    ToolModel? best;
    double confidence = 0;
    ToolModel? likely;
    double likelyScore = 0;
    bool likelyCentered = false;
    String? neighbor;
    double neighborScore = 0;
    for (var i = 0; i < count.toInt(); i++) {
      final value = classes[i];
      final score = scores[i];
      if (!value.isFinite ||
          value < 0 ||
          value != value.truncateToDouble() ||
          value >= labels.length ||
          !score.isFinite ||
          score < candidateFloor ||
          score > 1) {
        continue;
      }
      final label = labels[value.toInt()];
      if (boxes != null) {
        final box = boxes[i];
        if (box.length != 4 || box.any((n) => !n.isFinite)) continue;
        if (box[2] <= box[0] || box[3] <= box[1]) continue;
      }
      final inGuide = boxes == null || centered(boxes[i]);
      final toolId = labelToToolId[label];
      if (toolId == null) {
        // The model names it, the catalogue has no lesson for it. Say so —
        // silence here is what makes the scanner feel broken.
        if (_kitchenNeighbors.contains(label) && score > neighborScore) {
          neighbor = label;
          neighborScore = score;
        }
        continue;
      }
      final tool = _toolsById[toolId];
      if (tool == null) continue;
      if (score >= confidenceThreshold) {
        if (inGuide) {
          if (score > confidence) {
            best = tool;
            confidence = score;
          }
        } else if (score > likelyScore) {
          likely = tool;
          likelyScore = score;
          likelyCentered = false;
        }
      } else if (score > likelyScore) {
        likely = tool;
        likelyScore = score;
        likelyCentered = inGuide;
      }
    }
    if (best != null) {
      return DetectionResult(
          tool: best,
          confidence: confidence,
          processingMilliseconds: processingMilliseconds,
          statusMessage: 'Possible match: ${best.name}');
    }
    if (likely != null) {
      return DetectionResult(
          tool: null,
          confidence: likelyScore,
          processingMilliseconds: processingMilliseconds,
          statusMessage: likelyCentered
              ? 'Looks like a ${likely.name} — hold it steady to confirm'
              : 'Looks like a ${likely.name} — move it toward the center guide');
    }
    if (neighbor != null) {
      final named = neighbor[0].toUpperCase() + neighbor.substring(1);
      return DetectionResult(
          tool: null,
          confidence: neighborScore,
          processingMilliseconds: processingMilliseconds,
          statusMessage:
              '$named detected — not scannable yet. Choose it from the library.');
    }
    return DetectionResult(
        tool: null,
        confidence: 0,
        processingMilliseconds: processingMilliseconds,
        statusMessage: noMatchMessage);
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
        statusMessage: 'Too dark — improve lighting or turn on the torch',
        autoTorchRecommended: true);
  }
  if (prepared.luminance > 246) {
    return DetectionResult(
        tool: null,
        confidence: 0,
        processingMilliseconds: timer.elapsedMilliseconds,
        statusMessage: 'Too bright — reduce glare or move out of direct light');
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
