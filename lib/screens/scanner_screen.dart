import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/tool_model.dart';
import '../services/detector.dart';
import '../services/detection_gate.dart';
import '../services/frame_preprocessor.dart';
import '../services/tool_catalog.dart';
import '../services/learning_store.dart';
import '../widgets/tutorial_3d_painter.dart';
import 'tutorial_screen.dart';

class ScannerScreen extends StatefulWidget {
  final ToolModel? preSelectedTool;
  final ToolDetector? detector;

  const ScannerScreen({super.key, this.preSelectedTool, this.detector});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  late final ToolDetector _detector;
  final DetectionGate _gate = DetectionGate(requiredConsecutiveMatches: 3);

  /// Moderated-confidence tracker. A real knife or pair of shears often scores
  /// 0.4–0.65 on this model, so demanding 0.65 on every frame misses it
  /// entirely. This gate watches the lower band and, when a tool is seen
  /// consistently, offers it as a *proposal* the user confirms. It can never
  /// open a lesson on its own, so a false positive still costs one tap.
  final DetectionGate _proposalGate = DetectionGate(
      requiredConsecutiveMatches: 5,
      minConfidence: ToolDetector.candidateFloor);

  bool _torchOn = false;
  int _darkFrames = 0;
  bool _choosingTool = false;
  bool _isCameraReady = false;
  bool _isCameraBusy = false;
  String? _cameraErrorMessage;
  bool _isProcessingFrame = false;
  bool _requestingPermission = false;
  bool _openSettings = false;
  bool _foreground = true;
  int _cameraGeneration = 0;
  Future<void> _cameraWork = Future<void>.value();
  DateTime? _lastFrameAt;

  // Detection & Tutorial states
  String _hudStatusMessage = "Position tool inside frame";
  ToolModel? _activeTool;
  bool _lessonRequested = false;
  bool _proposalMatch = false;
  double _matchConfidence = 0;
  ToolModel? _streakCandidate;

  @override
  void initState() {
    super.initState();
    _detector = widget.detector ?? ToolDetector();
    WidgetsBinding.instance.addObserver(this);

    if (widget.preSelectedTool != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openLesson(widget.preSelectedTool!);
      });
    } else {
      _initializeDetectorAndCamera();
    }
  }

  Future<void> _initializeDetectorAndCamera() async {
    setState(() {
      _isCameraBusy = true;
      _hudStatusMessage = 'Preparing recognition...';
    });
    await _detector.loadModel();
    if (!mounted) return;
    if (!_detector.isLoaded) {
      setState(() {
        _cameraErrorMessage = _detector.loadError;
        _isCameraBusy = false;
      });
      return;
    }
    if (_foreground) await _setupCamera();
  }

  Future<void> _setupCamera() {
    final generation = ++_cameraGeneration;
    _cameraWork = _cameraWork.then((_) => _openCamera(generation));
    return _cameraWork;
  }

  bool _isCurrent(int generation) =>
      mounted && _foreground && generation == _cameraGeneration;

  Future<void> _openCamera(int generation) async {
    if (!_isCurrent(generation) || !_detector.isLoaded) return;
    await _disposeCameraOnly();
    if (!_isCurrent(generation)) return;
    setState(() {
      _isCameraBusy = true;
      _cameraErrorMessage = null;
      _openSettings = false;
      _resetDetection();
      _lastFrameAt = null;
      _torchOn = false;
      _hudStatusMessage = 'Starting camera...';
    });
    for (var attempt = 0; attempt < 3; attempt++) {
      CameraController? controller;
      try {
        _requestingPermission = true;
        final status = await Permission.camera.request();
        _requestingPermission = false;
        if (!_isCurrent(generation)) return;
        if (!status.isGranted) {
          setState(() {
            _isCameraBusy = false;
            _openSettings = status.isPermanentlyDenied || status.isRestricted;
            _cameraErrorMessage = _openSettings
                ? 'Enable camera access in Settings, or choose a tool below.'
                : 'Camera access is needed to scan. Retry or choose a tool below.';
          });
          return;
        }
        final cameras = await availableCameras();
        if (!_isCurrent(generation)) return;
        if (cameras.isEmpty) throw StateError('No camera available');
        final camera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
        controller = CameraController(camera, ResolutionPreset.medium,
            enableAudio: false,
            imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
                ? ImageFormatGroup.bgra8888
                : ImageFormatGroup.yuv420);
        await controller.initialize();
        if (!_isCurrent(generation)) {
          await controller.dispose();
          return;
        }
        _cameraController = controller;
        setState(() {
          _isCameraReady = true;
          _isCameraBusy = false;
          _hudStatusMessage = 'Hold steady (30-50 cm)';
        });
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (_isCurrent(generation)) await _startDetectionLoop();
        return;
      } catch (error) {
        _requestingPermission = false;
        if (identical(_cameraController, controller)) _cameraController = null;
        try {
          await controller?.dispose();
        } catch (_) {}
        if (!_isCurrent(generation)) return;
        setState(() => _isCameraReady = false);
        if (attempt == 2) {
          setState(() {
            _isCameraBusy = false;
            _cameraErrorMessage =
                'Camera unavailable. Retry or choose a tool below.';
          });
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
    }
  }

  /// Clears both streak trackers and their HUD state. Every path that returns
  /// the camera to searching goes through here, so the two gates can never
  /// drift apart.
  void _resetDetection() {
    _gate.reset();
    _proposalGate.reset();
    _streakCandidate = null;
    _darkFrames = 0;
    _proposalMatch = false;
    _matchConfidence = 0;
  }

  Future<void> _disposeCameraOnly() async {
    if (_cameraController != null) {
      final old = _cameraController!;
      _cameraController = null;
      try {
        if (old.value.isStreamingImages) {
          await old.stopImageStream();
        }
      } catch (_) {}
      try {
        await old.dispose();
      } catch (_) {}
    }
    _isCameraReady = false;
  }

  /// Phase 3: Live image processing pipeline that feeds each frame into the detector.
  Future<void> _startDetectionLoop() async {
    if (!_detector.isLoaded ||
        !_foreground ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _activeTool != null ||
        _isProcessingFrame) {
      return;
    }

    if (_cameraController!.value.isStreamingImages) {
      return;
    }

    final controller = _cameraController!;
    final generation = _cameraGeneration;
    await controller.startImageStream((CameraImage image) async {
      if (!_isCurrent(generation) ||
          _activeTool != null ||
          _choosingTool ||
          _isProcessingFrame ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return;
      }

      final now = DateTime.now();
      // While a match streak is building, sample faster so the three frames
      // that confirm a tool land in quick succession; back off when idle so
      // searching does not burn battery.
      final cadence = (_gate.currentCount > 0 ||
              _proposalGate.currentCount > 0)
          ? const Duration(milliseconds: 180)
          : const Duration(milliseconds: 250);
      if (_lastFrameAt != null && now.difference(_lastFrameAt!) < cadence) {
        return;
      }
      _lastFrameAt = now;
      _isProcessingFrame = true;

      try {
        final rotation = defaultTargetPlatform == TargetPlatform.iOS
            ? 0
            : androidFrameRotation(controller.description.sensorOrientation,
                controller.value.deviceOrientation,
                frontFacing: controller.description.lensDirection ==
                    CameraLensDirection.front);
        final result =
            await _detector.processCameraImage(image, rotation: rotation);

        if (!_isCurrent(generation) || _activeTool != null || _choosingTool) {
          return;
        }

        // Sustained darkness is a lighting problem, not a scanning problem:
        // turn the torch on automatically so the user does not have to find
        // the button in the dark. Reset whenever frames become readable.
        if (result.autoTorchRecommended) {
          _darkFrames++;
          if (_darkFrames == 3 && !_torchOn) await _toggleTorch();
        } else {
          _darkFrames = 0;
        }

        // A first lock on a candidate is worth a quiet tick: the user learns
        // the tool is being tracked without looking at the HUD.
        if (_gate.currentCount == 0 &&
            _proposalGate.currentCount == 0 &&
            result.tool != null) {
          HapticFeedback.selectionClick();
        }

        final confirmed = _gate.feed(result);
        // Only one gate advances per frame: a strong streak does not also pad
        // the proposal streak, so a confirmed match can never look like a
        // proposal (or the other way around).
        final proposed =
            confirmed == null ? _proposalGate.feed(result) : null;
        // Name the tool the streak is building on so the HUD answers
        // 'what does it see?' while the confirmation counts up.
        _streakCandidate = result.tool;
        setState(() => _hudStatusMessage = result.statusMessage);
        final matched = confirmed ?? proposed;
        if (matched != null) {
          HapticFeedback.mediumImpact();
          // Latch _activeTool FIRST so a second queued frame can't also confirm.
          setState(() {
            _activeTool = matched;
            _lessonRequested = false;
            _proposalMatch = confirmed == null;
            _matchConfidence = result.confidence;
            _hudStatusMessage = "Confirmed: ${matched.name}!";
          });
          if (_cameraController != null &&
              _cameraController!.value.isStreamingImages) {
            await _cameraController!.stopImageStream();
          }
          // Stay on the scanner: the animated 3D preview card lets the user
          // verify the match before committing to the lesson. A wrong match is
          // one tap to reject; a right one starts the lesson from the card.
        }
      } catch (_) {
        _resetDetection();
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  /// Opens the lesson from an auto-detection. Uses [Navigator.push] so the
  /// scanner remains underneath and we can resume the detection loop on return.
  Future<void> _openLessonFromDetection(ToolModel tool) async {
    _lessonRequested = true;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TutorialScreen(tool: tool)),
    );
    // Resume scanning when the lesson is popped.
    if (!mounted) return;
    setState(() {
      _activeTool = null;
      _lessonRequested = false;
      _resetDetection();
      _hudStatusMessage = "Position tool inside frame";
    });
    _startDetectionLoop().catchError((Object error) {
      if (mounted) {
        setState(() {
          _cameraErrorMessage = 'Unable to start scanning. Retry the camera.';
          _isCameraReady = false;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_requestingPermission && state == AppLifecycleState.inactive) return;
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      if (_detector.isLoaded) _setupCamera();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _foreground = false;
      ++_cameraGeneration;
      _resetDetection();
      _cameraWork = _cameraWork.then((_) => _disposeCameraOnly());
      if (mounted) setState(() => _isCameraReady = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ++_cameraGeneration;
    _foreground = false;
    _cameraWork = _cameraWork.then((_) => _disposeCameraOnly());
    _detector.dispose();
    super.dispose();
  }

  Future<void> _chooseTool() async {
    _choosingTool = true;
    _resetDetection();
    final tool = await showModalBottomSheet<ToolModel>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ToolPickerSheet(),
    );
    _choosingTool = false;
    if (!mounted || tool == null) return;
    _openLesson(tool);
  }

  void _openLesson(ToolModel tool) {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => TutorialScreen(tool: tool)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        title: Text(
          _activeTool != null ? _activeTool!.name : "Tool scanner",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isCameraReady && _activeTool == null)
            IconButton(
                tooltip: _torchOn ? 'Turn torch off' : 'Turn torch on',
                onPressed: _toggleTorch,
                icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off)),
          IconButton(
              onPressed: _chooseTool,
              tooltip: 'Choose tool manually',
              icon: const Icon(Icons.list_alt)),
        ],
      ),
      body: Stack(
        children: [
          // 1. Camera Preview or Error Fallback
          if (_isCameraReady && _cameraController != null)
            _buildCameraPreview()
          else
            _buildCameraFallback(),

          // 2. Alignment Reticle HUD (when searching for tool)
          if (_activeTool == null && _isCameraReady && _detector.isLoaded)
            _buildScanningReticle(),

          // 3. Recognition preview: the confirmed tool, animated in 3D, so the
          // match can be verified before the lesson opens.
          if (_activeTool != null && !_lessonRequested)
            Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: SafeArea(child: _buildRecognitionCard(_activeTool!))),
        ],
      ),
    );
  }

  /// The 'is this your tool?' card. Runs the same animated 3D demonstration as
  /// the lesson view, so what the user verifies is what they are about to learn
  /// with. Rejecting re-arms the detection loop immediately.
  Widget _buildRecognitionCard(ToolModel tool) {
    final motionAllowed = !MediaQuery.disableAnimationsOf(context) &&
        !LearningScope.of(context).reduceMotion;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: const Color(0xFF162937).withValues(alpha: .97),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF3D5B4C))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Semantics(
          label: 'Recognized ${tool.name}, animated illustration',
          child: Container(
            height: 220,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                color: const Color(0xFF0F1D28),
                borderRadius: BorderRadius.circular(18)),
            child: FittedBox(
              child: SizedBox(
                width: 380,
                height: 320,
                child: Tutorial3DView(
                    tool: tool, stepIndex: 0, isPlaying: motionAllowed),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(_proposalMatch ? 'POSSIBLE MATCH' : 'RECOGNIZED',
            style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.6,
                color: _proposalMatch
                    ? const Color(0xFFFFC66D)
                    : const Color(0xFF8AD4B0),
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Is this your ${tool.name}?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
            _proposalMatch
                ? '${(_matchConfidence * 100).round()}% confidence — please '
                    'check it is the right tool.'
                : '${(_matchConfidence * 100).round()}% confidence — always '
                    'check before starting.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: Colors.white.withValues(alpha: .55))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton(
                onPressed: _rejectMatch,
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24)),
                child: const Text('Not this tool')),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
                onPressed: () => _openLessonFromDetection(tool),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start lesson')),
          ),
        ]),
      ]),
    );
  }

  /// Clears the confirmation and puts the camera back to work. A wrong match
  /// should cost one tap, not a trip through the picker.
  Future<void> _rejectMatch() async {
    setState(() {
      _activeTool = null;
      _lessonRequested = false;
      _resetDetection();
      _hudStatusMessage = 'Position tool inside frame';
    });
    await _startDetectionLoop();
  }

  Widget _buildCameraFallback() {
    return Container(
      color: const Color(0xFF090D16),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isCameraBusy) ...[
                const CircularProgressIndicator(color: Colors.amber),
                const SizedBox(height: 16),
                Text(_hudStatusMessage,
                    style: const TextStyle(color: Colors.white70)),
              ] else if (_cameraErrorMessage != null) ...[
                const Icon(Icons.camera_alt_outlined,
                    color: Colors.amber, size: 54),
                const SizedBox(height: 16),
                Text(
                  _cameraErrorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 20),
                if (_detector.isLoaded)
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_openSettings) {
                        await openAppSettings();
                      } else {
                        await _setupCamera();
                      }
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                    icon: const Icon(Icons.refresh, color: Colors.black),
                    label: Text(
                        _openSettings ? "Open Settings" : "Retry Camera",
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
              ],
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _chooseTool,
                icon: const Icon(Icons.list_alt),
                label: const Text('Choose tool manually'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleTorch() async {
    final controller = _cameraController;
    if (controller == null) return;
    try {
      await controller.setFlashMode(_torchOn ? FlashMode.off : FlashMode.torch);
      if (mounted && identical(controller, _cameraController)) {
        setState(() => _torchOn = !_torchOn);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Torch is unavailable on this camera.')));
      }
    }
  }

  Widget _buildCameraPreview() {
    final controller = _cameraController!;
    final size = controller.value.previewSize!;
    return Center(
        child: AspectRatio(
      aspectRatio: 1,
      child: ClipRect(
          child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
            width: size.height,
            height: size.width,
            child: CameraPreview(controller)),
      )),
    ));
  }

  Widget _buildScanningReticle() {
    return Positioned.fill(
        child: SafeArea(
      child: Stack(children: [
        Center(
            child: FractionallySizedBox(
          widthFactor: .7,
          child: AspectRatio(
              aspectRatio: 1,
              child: IgnorePointer(
                child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: _gate.currentCount > 0
                                ? const Color(0xFF8AD4B0)
                                : const Color(0xFFFFC66D),
                            width: _gate.currentCount > 0 ? 3 : 2),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: _gate.currentCount > 0
                            ? [
                                BoxShadow(
                                    color: const Color(0xFF8AD4B0).withValues(
                                        alpha: .18 + .10 * _gate.currentCount),
                                    blurRadius: 18,
                                    spreadRadius: 2)
                              ]
                            : null)),
              )),
        )),
        Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(18)),
              child: Column(children: [
                const Text(ToolDetector.supportedToolsMessage,
                    style: TextStyle(
                        color: Color(0xFFFFC66D), fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(_hudStatusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white)),
              ]),
            )),
        Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(18)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _gate.currentCount > 0
                      ? Text(
                          'Keep the ${_streakCandidate?.name ?? 'tool'} steady '
                              '— match ${_gate.currentCount} of '
                              '${_gate.requiredConsecutiveMatches}',
                          key: const ValueKey('streak'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Color(0xFFFFC66D),
                              fontWeight: FontWeight.w700))
                      : const Text('Hold one tool steady in the frame.',
                          key: ValueKey('idle'),
                          textAlign: TextAlign.center),
                ),
                const SizedBox(height: 6),
                Text(ToolDetector.recognitionScopeNotice,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9BB0BD))),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _gate.progress),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      semanticsLabel: 'Recognition confirmation',
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(8)),
                ),
                TextButton.icon(
                    onPressed: _chooseTool,
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Choose tool manually')),
              ]),
            )),
      ]),
    ));
  }
}


/// Manual picker for the tools the bundled model cannot name.
///
/// The library is far wider than the model's coverage, so this is the primary
/// way into most lessons. It is searchable and grouped by category because a
/// flat list of every tool is not navigable.
class _ToolPickerSheet extends StatefulWidget {
  const _ToolPickerSheet();

  @override
  State<_ToolPickerSheet> createState() => _ToolPickerSheetState();
}

class _ToolPickerSheetState extends State<_ToolPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final matches = ToolCatalog.filterTools(kBuiltInTools,
        category: ToolCatalog.all, search: _query);
    final grouped = ToolCatalog.groupByCategory(matches);
    final theme = Theme.of(context);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(title: Text('Choose your kitchen tool')),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: false,
                decoration: const InputDecoration(
                  isDense: true,
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search tools or local names',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(ToolDetector.recognitionScopeNotice,
                  style: theme.textTheme.bodySmall),
            ),
            Expanded(
              child: matches.isEmpty
                  ? Center(
                      child: Text('No tools found',
                          style: theme.textTheme.bodyLarge))
                  : ListView(
                      children: [
                        for (final entry in grouped.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                            child: Text(entry.key,
                                style: theme.textTheme.titleSmall),
                          ),
                          for (final tool in entry.value)
                            ListTile(
                              title: Text(tool.name),
                              subtitle: Text(ToolDetector.supportedToolIds
                                      .contains(tool.id)
                                  ? 'Live scan match available'
                                  : 'Lesson ready'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.pop(context, tool),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
