import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tool_model.dart';

/// Small, versioned local profile. Writes are serialized to preserve tap order.
class LearningStore extends ChangeNotifier {
  static final instance = LearningStore();
  static const storageKey = 'kusina.learning.v1';
  final Future<String?> Function() _read;
  final Future<void> Function(String) _write;
  Future<void> _pending = Future.value();
  bool onboardingComplete = false;
  bool reduceMotion = false;
  String? storageError;
  final Set<String> _favorites = {};
  final Set<String> _completed = {};
  final List<String> _recent = [];
  final Map<String, int> _steps = {};

  LearningStore({
    Future<String?> Function()? read,
    Future<void> Function(String)? write,
  })  : _read = read ?? (() => SharedPreferencesAsync().getString(storageKey)),
        _write = write ??
            ((value) => SharedPreferencesAsync().setString(storageKey, value));

  bool isFavorite(String id) => _favorites.contains(id);
  bool isComplete(String id) => _completed.contains(id);
  bool hasStarted(String id) => _steps.containsKey(id);
  int stepFor(ToolModel tool) =>
      (_steps[tool.id] ?? 0).clamp(0, tool.steps.length - 1);
  int get completedCount => _completed.length;
  List<ToolModel> get recentTools => [
        for (final id in _recent)
          ...kBuiltInTools.where((tool) => tool.id == id),
      ];
  ToolModel? get continueTool {
    for (final tool in recentTools) {
      if (hasStarted(tool.id) && !isComplete(tool.id)) return tool;
    }
    return null;
  }

  Future<void> get flushed => _pending;

  Future<void> load() async {
    try {
      final raw = await _read();
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final ids = kBuiltInTools.map((tool) => tool.id).toSet();
      List<String> validIds(dynamic value) => value is List
          ? value.whereType<String>().where(ids.contains).toSet().toList()
          : [];
      onboardingComplete = data['onboarding'] == true;
      reduceMotion = data['reduceMotion'] == true;
      _favorites
        ..clear()
        ..addAll(validIds(data['favorites']));
      _completed
        ..clear()
        ..addAll(validIds(data['completed']));
      _recent
        ..clear()
        ..addAll(validIds(data['recent']).take(6));
      _steps.clear();
      if (data['steps'] is Map) {
        for (final tool in kBuiltInTools) {
          final value = data['steps'][tool.id];
          if (value is int) {
            _steps[tool.id] = value.clamp(0, tool.steps.length - 1);
          }
        }
      }
      storageError = null;
    } catch (_) {
      storageError =
          'Saved learning data could not be loaded. You can still use the app.';
    }
    notifyListeners();
  }

  void finishOnboarding() {
    onboardingComplete = true;
    _save();
  }

  void setReduceMotion(bool value) {
    reduceMotion = value;
    _save();
  }

  void toggleFavorite(String id) {
    if (!_favorites.remove(id)) _favorites.add(id);
    _save();
  }

  void visit(ToolModel tool) {
    _recent
      ..remove(tool.id)
      ..insert(0, tool.id);
    if (_recent.length > 6) _recent.removeLast();
    _save();
  }

  void saveStep(ToolModel tool, int step) {
    _steps[tool.id] = step.clamp(0, tool.steps.length - 1);
    _recent
      ..remove(tool.id)
      ..insert(0, tool.id);
    _save();
  }

  void complete(ToolModel tool) {
    _completed.add(tool.id);
    _save();
  }

  void restart(ToolModel tool) {
    _completed.remove(tool.id);
    saveStep(tool, 0);
  }

  void clearLearning() {
    _steps.clear();
    _completed.clear();
    _recent.clear();
    _save();
  }

  void _save() {
    final value = jsonEncode({
      'onboarding': onboardingComplete,
      'reduceMotion': reduceMotion,
      'favorites': _favorites.toList(),
      'completed': _completed.toList(),
      'recent': _recent,
      'steps': _steps,
    });
    notifyListeners();
    _pending = _pending.then((_) async {
      try {
        await _write(value);
        if (storageError != null) {
          storageError = null;
          notifyListeners();
        }
      } catch (_) {
        storageError = 'Changes could not be saved on this device.';
        notifyListeners();
      }
    });
  }
}

class LearningScope extends InheritedNotifier<LearningStore> {
  const LearningScope(
      {super.key, required LearningStore store, required super.child})
      : super(notifier: store);
  static LearningStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LearningScope>()?.notifier ??
      LearningStore.instance;
}
