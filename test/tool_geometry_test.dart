import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_tool_scanner/models/tool_model.dart';
import 'package:kitchen_tool_scanner/widgets/tool_geometry.dart';

void main() {
  test('every catalogue tool has bespoke geometry', () {
    expect(ToolGeometry.missingGeometry, isEmpty);
    expect(ToolGeometry.isComplete, isTrue);
  });

  test('no tool is left with a static lesson', () {
    expect(ToolGeometry.staticTools, isEmpty,
        reason:
            'these tools would animate nothing: ${ToolGeometry.staticTools}');
  });

  test('tool ids are unique', () {
    final ids = kBuiltInTools.map((tool) => tool.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every tool belongs to a declared category', () {
    for (final tool in kBuiltInTools) {
      expect(ToolCategories.ordered, contains(tool.category),
          reason: '${tool.id} has an undeclared category');
    }
  });

  test('every lesson has at least three steps with complete copy', () {
    for (final tool in kBuiltInTools) {
      expect(tool.steps.length, greaterThanOrEqualTo(3), reason: tool.id);
      expect(tool.safetyTip, isNotEmpty, reason: tool.id);
      expect(tool.warnings, isNotEmpty, reason: tool.id);
      for (var i = 0; i < tool.steps.length; i++) {
        final step = tool.steps[i];
        expect(step.stepNumber, i + 1, reason: '${tool.id} step $i');
        expect(step.title, isNotEmpty, reason: '${tool.id} step $i');
        expect(step.instruction, isNotEmpty, reason: '${tool.id} step $i');
        expect(step.gripTip, isNotEmpty, reason: '${tool.id} step $i');
        expect(step.targetAngle, isNotEmpty, reason: '${tool.id} step $i');
      }
    }
  });
}
