# Recognition validation

The bundled model is a real COCO SSD MobileNet V1 detector, and successful
native execution does not establish accuracy on kitchen tools. Automatic
recognition currently covers 3 of the 39 tools in the app (`knife`, `bowl`,
`kitchen_shears` via COCO `scissors`); everything else opens
from the library. Treat the numbers below as claims that still need measuring.

## Device checks

- Open scanner, allow camera permission, and confirm a live square preview.
- Verify the preview is upright in both supported portrait orientations.
- Turn the torch on/off, including on a camera without torch support.
- Background/resume repeatedly; verify only one stream is active.
- Leave during startup or inference; confirm no crash or retained camera.
- Deny access, then grant it in Settings and return.
- Choose a manual lesson while a prediction is being processed.
- Confirm a proposed result; return and scan another tool.

## Field evaluation

For each tool, use different physical examples, distances, orientations, lighting,
and backgrounds. Keep evaluation tools/capture sessions separate from training.
Include unrelated objects and spoons, which the model names but the app does not
map to a lesson. Keep the entire object within the square preview and aim its
center inside the guide. Never demonstrate unsafe handling just to obtain a scan.

Record observations locally; the app does not capture or upload test images.

| Device | Actual object | Lighting/background | Distance | Proposed tool | Time to confirmation | Correct? |
|---|---|---|---|---|---|---|
| | | | | | | |

Summarize per class: correct proposals / all proposals (precision), successful
recognitions / attempts (recognition rate), false proposals on unrelated scenes,
and median/p95 latency. Include sample counts and conditions with every result.
Agree acceptance targets before using the results to tune thresholds.

## Widening coverage

Decide which tools are worth scanning, then collect licensed, annotated images
for them alongside knives, bowls, and negative scenes. Fine-tune or source a
detector with those classes, export it against the contract in README.md, add
the new label→tool-id entries to `ToolDetector.labelToToolId` and the matching
`classId` to each tool, then repeat native and field evaluation. Do not alias spoon to
whisk or assign unrelated COCO indices to new tools.
