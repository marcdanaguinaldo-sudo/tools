import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_tool_scanner/main.dart';
import 'package:kitchen_tool_scanner/models/tool_model.dart';
import 'package:kitchen_tool_scanner/screens/tutorial_screen.dart';
import 'package:kitchen_tool_scanner/services/learning_store.dart';

void main() {
  LearningStore memoryStore() =>
      LearningStore(read: () async => null, write: (_) async {});

  testWidgets(
      'onboarding is dismissed once and library favorites can be filtered',
      (tester) async {
    final store = memoryStore();
    await tester.pumpWidget(KitchenToolScannerApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Skip introduction'), findsOneWidget);
    await tester.tap(find.text('Skip introduction'));
    await tester.pumpAndSettle();
    expect(store.onboardingComplete, isTrue);
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Save ${kBuiltInTools.first.name}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('1 tool'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'no matching tool');
    await tester.pumpAndSettle();
    expect(find.text('No tools found'), findsOneWidget);
    await tester
        .ensureVisible(find.widgetWithText(TextButton, 'Reset filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset filters'));
    await tester.pumpAndSettle();
    expect(find.text('${kBuiltInTools.length} tools'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(KitchenToolScannerApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Skip introduction'), findsNothing);
  });

  testWidgets('lesson resumes and completes without camera at large text size',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = memoryStore()..setReduceMotion(true);
    final tool = kBuiltInTools.first;
    store.saveStep(tool, 1);
    await tester.pumpWidget(LearningScope(
        store: store,
        child: MaterialApp(
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.6)),
                child: child!),
            home: TutorialScreen(tool: tool))));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of ${tool.steps.length}'), findsOneWidget);
    for (var i = 1; i < tool.steps.length; i++) {
      final label =
          i == tool.steps.length - 1 ? 'Complete lesson' : 'Next step';
      await tester.scrollUntilVisible(find.text(label), 400,
          scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(find.widgetWithText(FilledButton, label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(store.isComplete(tool.id), isTrue);
    expect(store.continueTool, isNull);
    expect(find.text('Lesson complete'), findsOneWidget);
  });

  testWidgets('home and library fit a narrow screen with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = memoryStore()..finishOnboarding();
    await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: KitchenToolScannerApp(store: store)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
