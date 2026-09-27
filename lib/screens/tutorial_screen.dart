import 'package:flutter/material.dart';
import '../models/tool_model.dart';
import '../services/learning_store.dart';
import '../widgets/tutorial_3d_painter.dart';

class TutorialScreen extends StatefulWidget {
  final ToolModel tool;
  const TutorialScreen({super.key, required this.tool});
  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _step = 0;
  bool _playing = true;
  bool _initialized = false;
  bool _finished = false;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final store = LearningScope.of(context);
      _step = store.stepFor(widget.tool);
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) store.saveStep(widget.tool, _step);
      });
    }
  }

  void _goTo(int index) {
    setState(() {
      _step = index;
      _finished = false;
    });
    LearningScope.of(context).saveStep(widget.tool, index);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final store = LearningScope.of(context);
    final step = tool.steps[_step];
    final last = _step == tool.steps.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(_finished ? 'Lesson complete' : 'Guided lesson'),
        actions: [
          IconButton(
              tooltip: 'Restart lesson',
              icon: const Icon(Icons.restart_alt),
              onPressed: () {
                store.restart(tool);
                _goTo(0);
              }),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(tool.name,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                    _finished
                        ? 'You completed all ${tool.steps.length} steps.'
                        : 'Step ${_step + 1} of ${tool.steps.length}',
                    style: const TextStyle(color: Color(0xFFFFC66D))),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                    value: _finished ? 1 : (_step + 1) / tool.steps.length,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(8),
                    semanticsLabel: 'Lesson progress'),
                const SizedBox(height: 20),
                if (_finished) ...[
                  const Padding(
                      padding: EdgeInsets.all(24),
                      child: Icon(Icons.check_circle_rounded,
                          size: 80, color: Color(0xFF8AD4B0))),
                  Text('One more skill for your kitchen.',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  const Text(
                      'Your progress is saved on this device. Revisit the lesson whenever you need a reminder.'),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to tools')),
                  TextButton(
                      onPressed: () {
                        store.restart(tool);
                        _goTo(0);
                      },
                      child: const Text('Practice again')),
                ] else ...[
                  Semantics(
                    label: 'Animated illustration for ${step.title}',
                    child: Container(
                      height: 280,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                          color: const Color(0xFF162937),
                          borderRadius: BorderRadius.circular(24)),
                      child: FittedBox(
                        child: SizedBox(
                            width: 380,
                            height: 320,
                            child: Tutorial3DView(
                                tool: tool,
                                stepIndex: _step,
                                isPlaying: _playing &&
                                    !store.reduceMotion &&
                                    !MediaQuery.disableAnimationsOf(context))),
                      ),
                    ),
                  ),
                  Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                          onPressed: store.reduceMotion ||
                                  MediaQuery.disableAnimationsOf(context)
                              ? null
                              : () => setState(() => _playing = !_playing),
                          icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                          label: Text(store.reduceMotion ||
                                  MediaQuery.disableAnimationsOf(context)
                              ? 'Motion reduced'
                              : _playing
                                  ? 'Pause animation'
                                  : 'Play animation'))),
                  Text(step.title.replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text(step.instruction,
                      style: const TextStyle(fontSize: 16, height: 1.6)),
                  const SizedBox(height: 20),
                  _note(context, Icons.pan_tool_outlined, 'Grip & position',
                      step.gripTip),
                  const SizedBox(height: 12),
                  _note(context, Icons.straighten, 'Target angle',
                      step.targetAngle),
                  const SizedBox(height: 12),
                  _note(context, Icons.shield_outlined, 'Safety first',
                      tool.safetyTip),
                  const SizedBox(height: 24),
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    OutlinedButton.icon(
                        onPressed: _step > 0 ? () => _goTo(_step - 1) : null,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous')),
                    FilledButton.icon(
                        onPressed: () {
                          if (last) {
                            store.complete(tool);
                            setState(() => _finished = true);
                            _scroll.jumpTo(0);
                          } else {
                            _goTo(_step + 1);
                          }
                        },
                        icon: Icon(last ? Icons.check : Icons.arrow_forward),
                        label: Text(last ? 'Complete lesson' : 'Next step')),
                  ]),
                ],
                if (store.storageError != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(store.storageError!,
                          style: const TextStyle(color: Colors.amber))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _note(
          BuildContext context, IconData icon, String title, String body) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF172732),
            borderRadius: BorderRadius.circular(16)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: const Color(0xFFFFC66D), size: 22),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(body,
                    style:
                        const TextStyle(color: Color(0xFFB8C7D0), height: 1.5)),
              ])),
        ]),
      );
}
