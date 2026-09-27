# Bundled recognition model

- Publisher: TensorFlow
- Model: SSD MobileNet V1, TFLite metadata variant, version 2
- Dataset: COCO
- License: Apache 2.0 (see LICENSE-2.0.txt)
- Model card: https://www.kaggle.com/models/tensorflow/ssd-mobilenet-v1/tfLite/metadata/2
- Official example download reference: https://github.com/tensorflow/examples/blob/master/lite/examples/object_detection/android/app/download_models.gradle
- Download: https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/object_detection/android/lite-model_ssd_mobilenet_v1_1_metadata_2.tflite
- Retrieved: 2026-09-27
- SHA-256: CBDECD08B44C5DEA3821F77C5468E2936ECFBF43CDE0795A2729FDB43401E58B
- Size: 4,185,175 bytes

The binary is unmodified. labels.txt is extracted from its embedded labelmap.txt,
preserving the 90 zero-based class positions and the unknown placeholders.

## Runtime contract

- Input: uint8 RGB, shape [1, 300, 300, 3], values 0–255.
- Output 0: float32 boxes [1, 10, 4], coordinates ymin/xmin/ymax/xmax.
- Output 1: float32 class indices [1, 10].
- Output 2: float32 scores [1, 10].
- Output 3: float32 detection count [1].
- App mappings: index 48 = knife; index 50 = bowl.
- Spoon (49) is not mapped to whisk. No other tutorial is inferred.

Camera input is oriented upright, center-cropped to a square, and sampled to
300 × 300. Android YUV420 and iOS BGRA8888 have separate conversion paths.
Conversion and inference run in a background worker; native interpreter lifetime
extends until an in-flight worker finishes.

## Intended use and limits

Experimental, offline suggestions for a knife or bowl followed by explicit user
confirmation. The model cannot distinguish chef's knives from other knives or
mixing bowls from other bowls. The user must confirm the suggested tutorial fits
their actual tool. It does not determine safe grip, tool condition, or safe use.

Whisks, peelers, tongs, and mandolines remain manual selections. They require
custom labeled data and a trained model before camera support can be claimed.

Scores are model confidence, not measured correctness probabilities. A threshold
of 0.65 and three consecutive processed frames are provisional defaults, not an
accuracy guarantee. Predictions whose centers fall outside the central 70% are
ignored to match the aiming guide.

## Validation

Run unit/widget tests with flutter test. Run native inference and disposal checks:

    flutter test integration_test/model_smoke_test.dart -d <android-device-id>

The native test uses a uniform gray image to verify actual execution and basic
negative behavior. It is not a representative accuracy benchmark. Record field
results using docs/SCANNER_VALIDATION.md before changing thresholds or advertising
accuracy.
