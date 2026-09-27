import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_tool_scanner/models/tool_model.dart';
import 'package:kitchen_tool_scanner/services/learning_store.dart';

void main() {
  test('profile survives restart and reset preserves favorites and preferences',
      () async {
    String? saved;
    LearningStore create() => LearningStore(
        read: () async => saved,
        write: (value) async {
          saved = value;
        });
    final first = create();
    final tool = kBuiltInTools.first;
    first.finishOnboarding();
    first.toggleFavorite(tool.id);
    first.setReduceMotion(true);
    first.saveStep(tool, 2);
    first.complete(tool);
    await first.flushed;
    final restored = create();
    await restored.load();
    expect(restored.onboardingComplete, isTrue);
    expect(restored.isFavorite(tool.id), isTrue);
    expect(restored.stepFor(tool), 2);
    expect(restored.isComplete(tool.id), isTrue);
    expect(restored.recentTools.single.id, tool.id);
    restored.clearLearning();
    await restored.flushed;
    final reset = create();
    await reset.load();
    expect(reset.recentTools, isEmpty);
    expect(reset.completedCount, 0);
    expect(reset.isFavorite(tool.id), isTrue);
    expect(reset.reduceMotion, isTrue);
  });

  test('rapid changes are persisted in order and failed writes recover',
      () async {
    String? saved;
    var fail = true;
    final store = LearningStore(
        read: () async => null,
        write: (value) async {
          if (fail) throw StateError('storage unavailable');
          saved = value;
        });
    store.toggleFavorite('knife');
    await store.flushed;
    expect(store.storageError, isNotNull);
    fail = false;
    store.toggleFavorite('bowl');
    store.toggleFavorite('knife');
    await store.flushed;
    expect(store.storageError, isNull);
    expect(jsonDecode(saved!)['favorites'], ['bowl']);
  });

  test('malformed saved data does not block startup', () async {
    final store =
        LearningStore(read: () async => '{broken', write: (_) async {});
    await store.load();
    expect(store.storageError, isNotNull);
    expect(store.completedCount, 0);
  });

  test('obsolete tools are ignored and resumed steps are clamped', () async {
    final store = LearningStore(
        read: () async => jsonEncode({
              'favorites': ['knife', 'obsolete'],
              'completed': ['obsolete'],
              'recent': ['obsolete', 'knife'],
              'steps': {'knife': 999},
            }),
        write: (_) async {});
    await store.load();
    expect(store.completedCount, 0);
    expect(store.isFavorite('obsolete'), isFalse);
    expect(store.stepFor(kBuiltInTools.first),
        kBuiltInTools.first.steps.length - 1);
    expect(store.continueTool?.id, 'knife');
  });
}
