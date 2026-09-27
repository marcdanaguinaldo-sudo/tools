import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_tool_scanner/models/tool_model.dart';
import 'package:kitchen_tool_scanner/screens/scanner_screen.dart';
import 'package:kitchen_tool_scanner/services/detection_gate.dart';
import 'package:kitchen_tool_scanner/services/detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final knife = kBuiltInTools.firstWhere((tool) => tool.id == 'knife');
  final bowl = kBuiltInTools.firstWhere((tool) => tool.id == 'bowl');
  DetectionResult detected(ToolModel tool, [double confidence = .9]) =>
      DetectionResult(tool: tool, confidence: confidence, statusMessage: '');
  const miss = DetectionResult(tool: null, confidence: 0, statusMessage: '');

  test('a missed frame requires three fresh consecutive matches', () {
    final gate = DetectionGate();
    gate.feed(detected(knife));
    gate.feed(detected(knife));
    gate.feed(miss);
    expect(gate.currentCount, 0);
    expect(gate.feed(detected(knife)), isNull);
    expect(gate.feed(detected(knife)), isNull);
    expect(gate.feed(detected(knife)), knife);
    gate.feed(miss);
    expect(gate.isConfirmed, isFalse);
  });

  test('changing tools clears confirmation and restarts the streak', () {
    final gate = DetectionGate();
    for (var i = 0; i < 8; i++) {
      gate.feed(detected(knife));
    }
    expect(gate.currentCount, 3);
    expect(gate.feed(detected(bowl)), isNull);
    expect(gate.confirmedTool, isNull);
    expect(gate.currentCount, 1);
    gate.feed(detected(bowl, .64));
    expect(gate.progress, 0);
    expect(() => DetectionGate(requiredConsecutiveMatches: 0),
        throwsArgumentError);
  });

  test('tool metadata stays compatible without leaking model internals', () {
    expect(kBuiltInTools.first.classId, isNotNull);
    expect(ToolDetector.supportedToolsMessage, isNot(contains('Experimental')));
    expect(ToolDetector.supportedToolsMessage, isNot(contains('knife')));
    expect(
        ToolDetector.selectDetection(
            [0, 1, 2], [.99, .8, .95], 2, ['person', 'knife', 'bowl']).tool,
        knife);
    expect(
        ToolDetector.selectDetection([1], [.9], 0, ['person', 'knife'])
            .isRecognized,
        isFalse);
  });

  test('malformed classes and confidence never confirm a tool', () {
    for (final value in [double.nan, double.infinity, -1.0, .5, 99.0]) {
      expect(
          ToolDetector.selectDetection([value], [.9], 1, ['knife'])
              .isRecognized,
          isFalse);
    }
    for (final score in [double.nan, double.infinity, -.1, .64, 1.1]) {
      expect(
          ToolDetector.selectDetection([0], [score], 1, ['knife']).isRecognized,
          isFalse);
      expect(detected(knife, score).isRecognized, isFalse);
    }
  });

  test('placeholder model stays unavailable without native inference',
      () async {
    final detector = ToolDetector(assets: _PlaceholderAssets());
    await detector.loadModel();
    expect(detector.isLoaded, isFalse);
    expect(detector.loadError, contains('Choose a tool'));
    detector.dispose();
    detector.dispose();
    await detector.loadModel();
    expect(detector.isLoaded, isFalse);
  });

  testWidgets('unavailable recognition offers manual selection without camera',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: ScannerScreen(
            detector: ToolDetector(assets: _PlaceholderAssets()))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Automatic recognition is unavailable'),
        findsOneWidget);
    expect(find.text('Retry Camera'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Choose tool manually'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your kitchen tool'), findsOneWidget);
    for (final tool in kBuiltInTools) {
      await tester.scrollUntilVisible(find.text(tool.name), 100,
          scrollable: find.byType(Scrollable).last);
      expect(find.text(tool.name), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the manual picker searches the whole library and opens a lesson',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: ScannerScreen(
            detector: ToolDetector(assets: _PlaceholderAssets()))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose tool manually'));
    await tester.pumpAndSettle();

    // The banner is honest about how little the bundled model can name.
    expect(find.text(ToolDetector.recognitionScopeNotice), findsOneWidget);
    expect(
        ToolDetector.supportedToolIds.length, lessThan(kBuiltInTools.length));

    final whisk = kBuiltInTools.firstWhere((tool) => tool.id == 'whisk');
    await tester.enterText(find.byType(TextField), 'whisk');
    await tester.pumpAndSettle();
    expect(find.text(whisk.name), findsOneWidget);
    await tester.tap(find.text(whisk.name));
    // The lesson view runs a repeating animation, so settle only the route
    // transition rather than waiting for frames to stop.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Step 1 of ${whisk.steps.length}'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the picker groups results under category headings',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: ScannerScreen(
            detector: ToolDetector(assets: _PlaceholderAssets()))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose tool manually'));
    await tester.pumpAndSettle();

    for (final category in ToolCategories.ordered) {
      await tester.scrollUntilVisible(find.text(category), 200,
          scrollable: find.byType(Scrollable).last);
      expect(find.text(category), findsOneWidget, reason: category);
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

class _PlaceholderAssets extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList('placeholder'.codeUnits));
}
