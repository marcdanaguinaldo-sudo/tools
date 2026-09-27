# Implementation status

## Implemented and locally verified

- Home, Library, Settings, onboarding, tool details, and standalone offline lessons.
- 39 tools across six categories, each with a complete multi-step lesson, grip and target-angle coaching, safety tips, and warnings.
- Bespoke solid 3D geometry for every tool, drawn by a shared offline renderer with per-technique animation, drag orbit, and per-step camera framing.
- Favorites, recent tools, resume progress, completion, and reduced-motion preference.
- Search/category filtering, reset filters, storage-error feedback, and learning reset.
- Searchable, category-grouped manual picker for the tools the camera cannot name.
- Android debug build and installation on a physical Android 11 phone.
- Unit and widget coverage of persistence, search, onboarding, large text, tutorial completion, and scanner output validation.
- Pixel-level rendering tests that fail if a tool draws nothing, loses its shading, stops animating, or ignores the camera.

## Model work — the artifact ships, the coverage does not

The bundled SSD MobileNet V1 / COCO model is real and loads; what is missing is class coverage. It maps only `knife` and `bowl`, so 2 of 39 tools are scannable and the rest open from the library. The remaining work is coverage and validation, not producing a model.

1. Collect licensed images for the tools to be scannable, plus unrelated objects and empty scenes.
2. Split training/validation/test data by physical tool and capture session to avoid near-duplicate leakage.
3. Fine-tune a detector on that data, or source one with matching classes, and export the tensor format described in README.md.
4. Verify label order, input normalization, crop/resize policy, and camera orientation against the exported model.
5. Add the new class indices to `ToolDetector.supportedToolIds` and the matching `classId` to each tool.
6. Measure per-tool precision/recall, false confirmations on non-tools, and latency on the target phone.
7. Choose confidence thresholds and supported classes from measured results. Do not advertise an unvalidated class.
8. Verify permission denial, Settings return, camera interruptions, repeated scans, lighting, clutter, rotation, and multiple objects on physical devices.
9. Consider an inference isolate if measured processing causes dropped UI frames.

Until then, the app states its coverage limit on screen and never implies the camera understands the whole library. Manual lessons remain fully available.

## Before release

- Build and test iOS on a Mac; finish iOS app icon and signing.
- Set production application IDs and signing. Do not publish the debug-signed build.
- Review the instructional content with a cooking instructor.
- Run TalkBack/VoiceOver and contrast checks on the final screens.
- Test offline startup, persistence across process restarts, and migration on multiple devices.
- Measure battery, memory, and startup performance on a lower-powered phone.
- Prepare store screenshots, final privacy disclosures, and a small user trial.

No store deployment, model fine-tuning, or production accuracy claim has been made.
