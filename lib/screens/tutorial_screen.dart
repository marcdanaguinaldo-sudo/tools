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
  bool _artworkOnScreen = true;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateArtworkVisibility);
  }

  /// The 3D canvas sits at the top of the lesson; once the reader scrolls down
  /// to the coaching notes it is fully offscreen, so stop paying for its
  /// repaints. Scrolling back up re-arms playback.
  void _updateArtworkVisibility() {
    if (!_scroll.hasClients || !mounted) return;
    final onScreen = _scroll.offset < 370;
    if (onScreen != _artworkOnScreen) {
      setState(() => _artworkOnScreen = onScreen);
    }
  }

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

  Color get _accent => switch (widget.tool.category) {
        ToolCategories.cutting => const Color(0xFFFF7968),
        ToolCategories.measuring => const Color(0xFF73C9FF),
        ToolCategories.mixing => const Color(0xFFA78BFA),
        ToolCategories.straining => const Color(0xFF5EEAD4),
        ToolCategories.cooking => const Color(0xFFFFC66D),
        _ => const Color(0xFF9BD48C),
      };

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final store = LearningScope.of(context);
    final step = tool.steps[_step];
    final last = _step == tool.steps.length - 1;
    return Scaffold(
      backgroundColor: const Color(0xFF08131B),
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: _accent.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(_finished ? Icons.workspace_premium : Icons.view_in_ar,
                size: 19, color: _accent),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(_finished ? 'Lesson complete' : '3D skill studio',
                  overflow: TextOverflow.ellipsis)),
        ]),
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF102530), Color(0xFF08131B)]),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _lessonHeader(tool, _finished),
                  const SizedBox(height: 20),
                  if (_finished) ...[
                    Center(
                      child: Container(
                        width: 122,
                        height: 122,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF173D39),
                            border: Border.all(
                                color: const Color(0xFF8AD4B0), width: 2)),
                        child: const Icon(Icons.check_rounded,
                            size: 72, color: Color(0xFF8AD4B0)),
                      ),
                    ),
                    const SizedBox(height: 22),
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
                        height: 330,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                            color: const Color(0xFF162937),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                                color: _accent.withValues(alpha: .48)),
                            boxShadow: [
                              BoxShadow(
                                  color: _accent.withValues(alpha: .13),
                                  blurRadius: 30,
                                  spreadRadius: 2)
                            ]),
                        child: Stack(children: [
                          Positioned.fill(
                            child: FittedBox(
                              child: SizedBox(
                                  width: 390,
                                  height: 340,
                                  child: Tutorial3DView(
                                      tool: tool,
                                      stepIndex: _step,
                                      isPlaying: _playing &&
                                          _artworkOnScreen &&
                                          !store.reduceMotion &&
                                          !MediaQuery.disableAnimationsOf(
                                              context))),
                            ),
                          ),
                          Positioned(
                            top: 15,
                            left: 15,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF0B1922)
                                      .withValues(alpha: .82),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text('LIVE 3D DEMO',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                      color: _accent)),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                              color: const Color(0xFF112530),
                              borderRadius: BorderRadius.circular(16)),
                          child: Wrap(spacing: 4, children: [
                            TextButton.icon(
                                onPressed: store.reduceMotion ||
                                        MediaQuery.disableAnimationsOf(context)
                                    ? null
                                    : () =>
                                        setState(() => _playing = !_playing),
                                icon: Icon(
                                    _playing ? Icons.pause : Icons.play_arrow),
                                label: Text(store.reduceMotion ||
                                        MediaQuery.disableAnimationsOf(context)
                                    ? 'Motion reduced'
                                    : _playing
                                        ? 'Pause animation'
                                        : 'Play animation')),
                            if (!store.reduceMotion &&
                                !MediaQuery.disableAnimationsOf(context))
                              const Tooltip(
                                  message:
                                      'Double-tap the illustration to replay',
                                  child: Icon(Icons.replay, size: 18)),
                          ]),
                        )),
                    _stepRail(tool),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: const Color(0xFF152B37),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: .07))),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NOW PRACTISING',
                                style: TextStyle(
                                    color: _accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2)),
                            const SizedBox(height: 9),
                            Text(
                                step.title
                                    .replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 12),
                            Text(step.instruction,
                                style:
                                    const TextStyle(fontSize: 16, height: 1.6)),
                          ]),
                    ),
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
      ),
    );
  }

  Widget _lessonHeader(ToolModel tool, bool finished) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF112630),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _accent.withValues(alpha: .24)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
              spacing: 10,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                      color: _accent.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(tool.category.toUpperCase(),
                      style: TextStyle(
                          color: _accent,
                          fontSize: 10,
                          letterSpacing: .8,
                          fontWeight: FontWeight.w800)),
                ),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.schedule_rounded,
                      size: 15, color: Colors.white54),
                  const SizedBox(width: 5),
                  Text('${tool.minutes} min',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ]),
          const SizedBox(height: 13),
          Text(tool.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
              finished
                  ? 'You completed all ${tool.steps.length} steps.'
                  : 'Step ${_step + 1} of ${tool.steps.length}',
              style: TextStyle(
                  color: _accent, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: finished ? 1 : (_step + 1) / tool.steps.length,
              minHeight: 7,
              color: _accent,
              backgroundColor: Colors.white.withValues(alpha: .10),
              semanticsLabel: 'Lesson progress',
            ),
          ),
        ]),
      );

  Widget _stepRail(ToolModel tool) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFF10222C),
            borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          const Icon(Icons.route_rounded, size: 19, color: Colors.white60),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(spacing: 7, runSpacing: 7, children: [
              for (var i = 0; i < tool.steps.length; i++)
                Tooltip(
                  message: tool.steps[i].title
                      .replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _goTo(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _step == i
                            ? _accent
                            : Colors.white.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${i + 1}',
                          style: TextStyle(
                              color: _step == i
                                  ? const Color(0xFF11212A)
                                  : Colors.white70,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
            ]),
          ),
        ]),
      );

  Widget _note(
          BuildContext context, IconData icon, String title, String body) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: const Color(0xFF132833),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accent.withValues(alpha: .16))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: _accent.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: _accent, size: 20)),
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
