# Kusina — Kitchen Tool Learning

An offline Flutter learning app with 39 kitchen-tool lessons, animated 3D tool demonstrations, saved progress, and a camera recognition pipeline.

## Available now

- Redesigned Home, Library, and Settings screens with a consistent dark theme.
- 39 tools across six categories, each with a full multi-step lesson, grip and target-angle coaching, safety tips, and warnings.
- Every tool drawn as bespoke solid 3D geometry, animated per technique and orbitable by drag, with no network or image assets.
- Search, category filters, favorites, and empty-state recovery.
- Recently viewed tools and a Continue learning shortcut.
- Camera-independent lessons with previous/next controls, pause, restart, and completion.
- Persistent onboarding, lesson progress, favorites, and reduced-motion preference.
- Scrollable layouts for small screens and larger text.
- Android host configuration, camera permission, optional camera hardware, and branded launcher icon.
- iOS host project with camera usage text and camera permission build configuration.

Learning data is stored locally with shared_preferences. The app needs no account for its built-in lessons. Storage failures are displayed instead of silently losing changes.

## Current recognition status

`assets/models/ssd_mobilenet.tflite` is a real, unmodified **SSD MobileNet V1** detector (4,185,175 bytes, TFL3) trained on COCO, with the 90-class label order in `assets/models/labels.txt`. See [assets/models/MODEL_CARD.md](assets/models/MODEL_CARD.md) for provenance, license, and SHA-256.

The honest limit is class coverage, not model validity. The bundled COCO model can only name **3 of the 39** tools in this app, because only COCO classes 48 (`knife`), 50 (`bowl`), and 86 (`scissors` → `kitchen_shears`) are mapped. Every other tool is reached through **Choose tool manually**, and the scanner states the coverage limit on screen instead of implying it can see the whole library. Spoon (49) is deliberately not mapped to the whisk lesson.

The app never identifies tools from camera frame dimensions. Real recognition accuracy still requires on-device evaluation, recorded per [docs/SCANNER_VALIDATION.md](docs/SCANNER_VALIDATION.md).

## Model integration contract

The bundled model must match this contract, and loading fails closed if it does not:

- One uint8 RGB input tensor: `[1, 300, 300, 3]`, values 0–255, sampled from a center crop of the upright frame.
- Four float32 outputs, in order: boxes `[1, 10, 4]` (ymin/xmin/ymax/xmax), classes `[1, 10]`, scores `[1, 10]`, and detection count `[1]`.
- Class indices are zero-based indices into `assets/models/labels.txt`, whose 90 lines preserve the model's embedded class positions. A label count other than 90, or a `knife`/`bowl` label at any other index, is rejected.
- Mapped tool IDs live in `ToolDetector.labelToToolId` (COCO label → catalog tool id) and must exist in the catalog. `supportedToolIds` is derived for UI. Unmapped labels are ignored rather than guessed at.

Loading rejects placeholder assets, label/model mismatches, and unsupported tensor layouts. Shape validation cannot establish that labels, normalization, or predictions are semantically correct; verify those against the model's training/export configuration. To widen coverage, fine-tune a detector and update `supportedToolIds` with the matching class indices.

## Reliability behavior

- Three consecutive processed frames at confidence >= 0.65 confirm a tool. A miss, low confidence, or different tool resets the streak.
- A second, moderated-confidence tracker (floor 0.40, five steady frames) can offer a tool the strict gate would refuse. Such a match is presented as a *proposal* with its confidence shown, and only a user tap can open a lesson — a proposal can never open one by itself.
- A confirmed match shows the tool's animated 3D model for verification before the lesson opens; rejecting it re-arms scanning in one tap.
- Sub-threshold detections surface as guidance instead of a dead end ("Looks like a knife — hold it steady to confirm"), and detections outside the center guide are told apart from off-center ones. Guidance copy can never open a lesson.
- COCO classes the camera commonly sees that have no lesson (spoon, fork, cup, bottle, and similar) are named in the HUD rather than silently ignored, and are never aliased to a lesson.
- Unsupported classes, non-finite values, invalid scores, and output slots beyond the reported detection count cannot trigger recognition.
- Frames are processed at most every 250 ms, with only one inference in flight.
- Android YUV420 and iOS BGRA8888 conversion respect plane row strides.
- Camera startup and disposal are serialized; stale sessions are ignored after navigation or app backgrounding.
- Camera startup retries up to three times. Permanent permission denial offers Settings, and manual selection remains available.

## Development

Validated with Flutter 3.44.4 / Dart 3.12.2.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter run -d <device-id>
```

Android debug builds are available at `build/app/outputs/flutter-apk/app-debug.apk`. The Android application ID remains `com.example.kitchen_tool_scanner` to preserve the existing project's identity. Configure your final ID and production signing before store publication; the current build is for development.

iOS requires macOS, Xcode, CocoaPods, and signing configuration. On a Mac, run `flutter pub get`, then `cd ios && pod install`, and open `Runner.xcworkspace`. The iOS deployment target is 15.0. iOS builds have not been validated from this Windows environment; the iOS app icon still needs final branding.

The inference dependency is 0.12.1; see its [release notes](https://pub.dev/packages/tflite_flutter/changelog) for native build requirements.

Regression tests cover catalogue and lesson integrity, 3D geometry coverage, pixel-level rendering (shading, animation, camera drag, per-step framing), confirmation streaks, invalid model outputs, placeholder handling, the searchable manual picker, saved-state round trips, write failures, onboarding, favorite filtering, and lesson completion with large text.

The Android debug APK has been built and installed on an Android 11 device. Real recognition accuracy and camera lifecycle behavior still require device testing with the bundled model. See [ROADMAP.md](ROADMAP.md) for remaining model and release work.
