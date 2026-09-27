import '../models/tool_model.dart';
import 'detector.dart';

class DetectionGate {
  final int requiredConsecutiveMatches;
  String? _candidateId;
  int _consecutiveCount = 0;
  ToolModel? _confirmedTool;

  DetectionGate({this.requiredConsecutiveMatches = 3}) {
    if (requiredConsecutiveMatches < 1) {
      throw ArgumentError.value(requiredConsecutiveMatches,
          'requiredConsecutiveMatches', 'Must be positive');
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
    if (!result.isRecognized || result.tool == null) {
      reset();
      return null;
    }

    final tool = result.tool!;

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
