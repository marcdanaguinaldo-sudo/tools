import '../models/tool_model.dart';
import 'detector.dart';

class DetectionGate {
  final int requiredConsecutiveMatches;

  /// Lowest confidence that counts as a hit. Defaults to the confirmation
  /// threshold. A lower floor lets a second gate track moderated-confidence
  /// proposals that a human still has to confirm.
  final double minConfidence;
  String? _candidateId;
  int _consecutiveCount = 0;
  ToolModel? _confirmedTool;

  DetectionGate({this.requiredConsecutiveMatches = 3, double? minConfidence})
      : minConfidence = minConfidence ?? ToolDetector.confidenceThreshold {
    if (requiredConsecutiveMatches < 1) {
      throw ArgumentError.value(requiredConsecutiveMatches,
          'requiredConsecutiveMatches', 'Must be positive');
    }
    // `!(x > 0)` also rejects NaN, which would otherwise poison every compare.
    if (!(this.minConfidence > 0) || this.minConfidence > 1) {
      throw ArgumentError.value(
          minConfidence, 'minConfidence', 'Must be in (0, 1]');
    }
  }

  int get currentCount => _consecutiveCount;
  bool get isConfirmed => _confirmedTool != null;
  ToolModel? get confirmedTool => _confirmedTool;
  double get progress =>
      (_consecutiveCount / requiredConsecutiveMatches).clamp(0.0, 1.0);

  /// Evaluates an incoming detection frame.
  /// Returns confirmed ToolModel only if [requiredConsecutiveMatches] matches are verified in a row.
  ToolModel? feed(DetectionResult result) {
    final tool = result.tool;
    final confidence = result.confidence;
    final hit = tool != null &&
        confidence.isFinite &&
        confidence >= minConfidence &&
        confidence <= 1;
    if (!hit) {
      reset();
      return null;
    }

    if (_candidateId == tool.id) {
      _consecutiveCount++;
    } else {
      _candidateId = tool.id;
      _consecutiveCount = 1;
      _confirmedTool = null;
    }

    if (_consecutiveCount >= requiredConsecutiveMatches) {
      _consecutiveCount = requiredConsecutiveMatches;
      _confirmedTool = tool;
      return _confirmedTool;
    }

    return null;
  }

  void reset() {
    _candidateId = null;
    _consecutiveCount = 0;
    _confirmedTool = null;
  }
}
