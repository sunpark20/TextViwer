# 얼굴 제스처 기반 페이지 넘기기 — 아키텍처 설계서

> **목표:** 눈 깜빡임(다음 페이지) + 웃음(이전 페이지) 인식으로 핸즈프리·보이스프리 페이지 전환
> **피드백:** TTS 음성 안내 + HapticFeedback 진동 이중 피드백

---

## 1. 제스처 규칙 (최종 사양)

| 제스처 | 조건 | 동작 |
|--------|------|------|
| 두 눈 3번 깜빡임 | 3초 이내, 양쪽 눈 동시 `eyeOpenProb < 0.3` | 다음 페이지 |
| 크게 웃기 | `smilingProb > 0.85` 1초 지속 | 이전 페이지 |
| 쿨다운 | 제스처 트리거 후 3초 | 모든 제스처 무시 |
| 카메라 미리보기 | 우하단 원형, 탭 토글 (100×100) | UI 표시/숨김 |

---

## 2. 신규 의존성

```yaml
# pubspec.yaml 추가분
dependencies:
  camera: ^0.11.0+2               # 카메라 스트림
  google_mlkit_face_detection: ^0.11.0  # ML Kit 얼굴 감지
  flutter_tts: ^4.2.0             # TTS 피드백
```

### 플랫폼 설정

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.front" android:required="false" />
```

**Android** (`android/app/build.gradle`):
```groovy
android {
    defaultConfig {
        minSdkVersion 21  // ML Kit 최소 요구
    }
}
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>얼굴 제스처로 페이지를 넘기기 위해 카메라 접근이 필요합니다</string>
```

---

## 3. 전체 아키텍처 다이어그램

```
┌─────────────────────────────────────────────────────────────────┐
│                        main.dart                                │
│  MultiProvider                                                  │
│  ├── ReaderProvider          (기존)                              │
│  ├── SpeechProvider          (기존)                              │
│  ├── FacialGestureProvider   (신규 ★)                            │
│  └── FeedbackProvider        (신규 ★)                            │
└────────────────────────┬────────────────────────────────────────┘
                         │
            ┌────────────▼────────────┐
            │      ReaderScreen       │
            │  (기존 + 카메라 오버레이)  │
            └────────────┬────────────┘
                         │
        ┌────────────────┼────────────────┐
        ▼                ▼                ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────────┐
│ SpeechProvider│ │FacialGesture │ │  FeedbackProvider │
│ (음성 명령)   │ │  Provider    │ │  (TTS + 진동)     │
│              │ │  (얼굴 감지)  │ │                  │
└──────┬───────┘ └──────┬───────┘ └────────┬─────────┘
       │                │                   │
       │         ┌──────▼───────┐          │
       │         │  Domain      │          │
       │         │  Services    │          │
       │         ├──────────────┤          │
       │         │FaceDetection │          │
       │         │  Service     │          │
       │         ├──────────────┤          │
       │         │BlinkDetector │          │
       │         ├──────────────┤          │
       │         │SmileDetector │          │
       │         └──────────────┘          │
       │                                   │
       └──────────► ReaderProvider ◄───────┘
                    .executeCommand()
```

### 데이터 흐름 (Sequence)

```
Camera Stream (30fps)
    │
    ▼ (프레임 스로틀: 매 3번째 프레임만 = ~10fps)
FaceDetectionService.processFrame(CameraImage)
    │
    ├── ML Kit FaceDetector.processImage(InputImage)
    │       ├── leftEyeOpenProbability
    │       ├── rightEyeOpenProbability
    │       └── smilingProbability
    │
    ▼
FacialGestureProvider._onFaceDetected(Face)
    │
    ├── BlinkDetector.registerFrame(leftEyeProb, rightEyeProb)
    │       ├── eyes open → closed 전환 감지
    │       ├── closed → open 전환 = 1 blink 카운트
    │       ├── 3 blinks within 3초? → GestureEvent.nextPage
    │       └── 타이머 3초 초과시 카운트 리셋
    │
    ├── SmileDetector.registerFrame(smilingProb)
    │       ├── smilingProb > 0.85 시작 시각 기록
    │       ├── 연속 1초 이상? → GestureEvent.previousPage
    │       └── 0.85 미만 시 타이머 리셋
    │
    └── 쿨다운 체크 (3초)
            │
            ▼
    ReaderProvider.executeCommand(VoiceCommand.next / previous)
            │
            ▼
    FeedbackProvider.giveFeedback("다음 페이지" / "이전 페이지")
        ├── TTS.speak("다음 페이지")
        └── HapticFeedback.mediumImpact()
```

---

## 4. 파일 구조 (신규 파일만)

```
lib/
├── domain/
│   ├── enums/
│   │   └── gesture_event.dart              ★ 제스처 이벤트 열거형
│   └── services/
│       ├── face_detection_service.dart      ★ ML Kit 래퍼 (프레임→Face)
│       ├── blink_detector.dart              ★ 깜빡임 상태 머신
│       ├── smile_detector.dart              ★ 웃음 상태 머신
│       └── feedback_service.dart            ★ TTS + 진동 서비스
├── presentation/
│   ├── providers/
│   │   ├── facial_gesture_provider.dart     ★ 카메라+감지 통합 Provider
│   │   └── feedback_provider.dart           ★ 피드백 Provider
│   └── widgets/
│       └── camera_preview_overlay.dart      ★ 원형 카메라 미리보기
```

---

## 5. 각 컴포넌트 상세 설계

### 5-1. `gesture_event.dart` — 제스처 이벤트 열거형

```dart
enum GestureEvent {
  nextPage,      // 3회 깜빡임 → 다음 페이지
  previousPage,  // 1초 웃음 → 이전 페이지
}
```

### 5-2. `blink_detector.dart` — 깜빡임 상태 머신

**핵심 알고리즘:**

```
상태: EYES_OPEN ↔ EYES_CLOSED

프레임마다:
1. bothEyesClosed = (leftProb < 0.3 AND rightProb < 0.3)
2. bothEyesOpen   = (leftProb > 0.6 AND rightProb > 0.6)

상태 전환:
  EYES_OPEN + bothEyesClosed → EYES_CLOSED
  EYES_CLOSED + bothEyesOpen → EYES_OPEN, blinkCount++

blinkCount 관리:
  - 첫 번째 깜빡임 시 windowStart = DateTime.now()
  - blinkCount == 3 → 트리거! + 리셋
  - DateTime.now() - windowStart > 3초 → 리셋 (너무 느림)
```

**설계 포인트:**
- 순수 Dart 클래스, Flutter 의존성 없음 → 단위 테스트 용이
- Hysteresis: `closed < 0.3`, `open > 0.6` 분리로 경계값 떨림 방지
- 양쪽 눈 동시 감지 필수 → 한쪽 눈 깜빡임(윙크) 필터링

```dart
class BlinkDetector {
  static const double _closedThreshold = 0.3;
  static const double _openThreshold = 0.6;
  static const int _requiredBlinks = 3;
  static const Duration _windowDuration = Duration(seconds: 3);

  bool _eyesClosed = false;
  int _blinkCount = 0;
  DateTime? _windowStart;

  /// 프레임 데이터 입력. 깜빡임 3회 달성 시 true 반환.
  bool registerFrame(double leftEyeProb, double rightEyeProb) {
    final bothClosed = leftEyeProb < _closedThreshold
                    && rightEyeProb < _closedThreshold;
    final bothOpen = leftEyeProb > _openThreshold
                  && rightEyeProb > _openThreshold;

    if (!_eyesClosed && bothClosed) {
      _eyesClosed = true;
    } else if (_eyesClosed && bothOpen) {
      _eyesClosed = false;
      _blinkCount++;
      _windowStart ??= DateTime.now();

      // 윈도우 초과 체크
      if (DateTime.now().difference(_windowStart!) > _windowDuration) {
        reset();
        return false;
      }

      if (_blinkCount >= _requiredBlinks) {
        reset();
        return true; // 트리거!
      }
    }
    return false;
  }

  void reset() {
    _eyesClosed = false;
    _blinkCount = 0;
    _windowStart = null;
  }
}
```

### 5-3. `smile_detector.dart` — 웃음 상태 머신

```dart
class SmileDetector {
  static const double _smileThreshold = 0.85;
  static const Duration _requiredDuration = Duration(seconds: 1);

  DateTime? _smileStart;

  /// 프레임 데이터 입력. 1초 지속 웃음 시 true 반환.
  bool registerFrame(double smilingProb) {
    if (smilingProb > _smileThreshold) {
      _smileStart ??= DateTime.now();
      if (DateTime.now().difference(_smileStart!) >= _requiredDuration) {
        reset();
        return true; // 트리거!
      }
    } else {
      _smileStart = null; // 웃음 중단 → 리셋
    }
    return false;
  }

  void reset() {
    _smileStart = null;
  }
}
```

### 5-4. `face_detection_service.dart` — ML Kit 래퍼

**핵심 설계 원칙:**
- `_isBusy` 플래그로 프레임 겹침 방지 (중복 inference 차단)
- `enableClassification: true` 필수 (눈/웃음 확률값 활성화)
- `performanceMode: fast` (실시간 처리 최적화)

```dart
class FaceDetectionService {
  late final FaceDetector _faceDetector;
  bool _isBusy = false;

  FaceDetectionService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,  // 눈/웃음 확률 필수
        enableContours: false,       // 불필요 → 성능 절약
        enableLandmarks: false,      // 불필요 → 성능 절약
        enableTracking: false,       // 단일 사용자 → 불필요
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.3,
      ),
    );
  }

  /// CameraImage를 처리하여 Face 리스트 반환.
  /// 이전 프레임 처리 중이면 null 반환 (스킵).
  Future<List<Face>?> processImage(InputImage inputImage) async {
    if (_isBusy) return null;
    _isBusy = true;
    try {
      return await _faceDetector.processImage(inputImage);
    } finally {
      _isBusy = false;
    }
  }

  void dispose() {
    _faceDetector.close();
  }
}
```

### 5-5. `feedback_service.dart` — TTS + 진동

```dart
class FeedbackService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(0.6);  // 자연스러운 속도
    await _tts.setVolume(0.8);
    _isInitialized = true;
  }

  Future<void> giveFeedback(String message) async {
    // 진동 먼저 (즉각적)
    HapticFeedback.mediumImpact();
    // TTS (약간의 딜레이 허용)
    if (_isInitialized) {
      await _tts.speak(message);
    }
  }

  void dispose() {
    _tts.stop();
  }
}
```

### 5-6. `facial_gesture_provider.dart` — 핵심 통합 Provider

**이것이 전체 시스템의 오케스트레이터.**

```dart
class FacialGestureProvider extends ChangeNotifier {
  // === 서비스 ===
  final FaceDetectionService _faceService = FaceDetectionService();
  final BlinkDetector _blinkDetector = BlinkDetector();
  final SmileDetector _smileDetector = SmileDetector();

  // === 카메라 ===
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isActive = false;          // 제스처 감지 활성 여부

  // === 쿨다운 ===
  DateTime? _lastTriggerTime;
  static const Duration _cooldownDuration = Duration(seconds: 3);

  // === UI 상태 ===
  bool _showPreview = false;       // 미리보기 표시 여부
  int _blinkCount = 0;             // UI용 현재 깜빡임 횟수

  // === 콜백 ===
  void Function(VoiceCommand)? onGestureCommand;  // ReaderProvider 연결용
  void Function(String)? onFeedback;               // FeedbackProvider 연결용

  // --- Getters ---
  bool get isInitialized => _isInitialized;
  bool get isActive => _isActive;
  bool get showPreview => _showPreview;
  int get blinkCount => _blinkCount;
  CameraController? get cameraController => _cameraController;

  // --- 초기화 ---
  Future<void> initialize() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.low,       // 성능 최적화: 낮은 해상도 충분
      enableAudio: false,          // 오디오 불필요
      imageFormatGroup: ImageFormatGroup.nv21,  // ML Kit 최적 포맷
    );

    await _cameraController!.initialize();
    _isInitialized = true;
    notifyListeners();
  }

  // --- 제스처 감지 시작/중지 ---
  void startDetection() {
    if (!_isInitialized || _isActive) return;
    _isActive = true;
    _frameCount = 0;

    _cameraController!.startImageStream(_onCameraFrame);
    notifyListeners();
  }

  void stopDetection() {
    if (!_isActive) return;
    _isActive = false;
    _cameraController?.stopImageStream();
    _blinkDetector.reset();
    _smileDetector.reset();
    notifyListeners();
  }

  // --- 프레임 스로틀 ---
  int _frameCount = 0;
  static const int _processEveryNthFrame = 3;  // 매 3번째만 처리 (~10fps)

  void _onCameraFrame(CameraImage image) {
    _frameCount++;
    if (_frameCount % _processEveryNthFrame != 0) return;

    // 쿨다운 체크
    if (_isInCooldown()) return;

    final inputImage = _convertToInputImage(image);
    if (inputImage == null) return;

    _faceService.processImage(inputImage).then((faces) {
      if (faces == null || faces.isEmpty) return;
      _onFaceDetected(faces.first);
    });
  }

  // --- 얼굴 감지 결과 처리 ---
  void _onFaceDetected(Face face) {
    final leftEye = face.leftEyeOpenProbability;
    final rightEye = face.rightEyeOpenProbability;
    final smile = face.smilingProbability;

    if (leftEye == null || rightEye == null || smile == null) return;

    // 1) 깜빡임 체크
    if (_blinkDetector.registerFrame(leftEye, rightEye)) {
      _triggerGesture(GestureEvent.nextPage);
      return;
    }

    // 2) 웃음 체크
    if (_smileDetector.registerFrame(smile)) {
      _triggerGesture(GestureEvent.previousPage);
      return;
    }
  }

  // --- 제스처 트리거 ---
  void _triggerGesture(GestureEvent event) {
    _lastTriggerTime = DateTime.now();

    // 감지기 리셋
    _blinkDetector.reset();
    _smileDetector.reset();

    switch (event) {
      case GestureEvent.nextPage:
        onGestureCommand?.call(VoiceCommand.next);
        onFeedback?.call('다음 페이지');
        break;
      case GestureEvent.previousPage:
        onGestureCommand?.call(VoiceCommand.previous);
        onFeedback?.call('이전 페이지');
        break;
    }

    notifyListeners();
  }

  bool _isInCooldown() {
    if (_lastTriggerTime == null) return false;
    return DateTime.now().difference(_lastTriggerTime!) < _cooldownDuration;
  }

  // --- 미리보기 토글 ---
  void togglePreview() {
    _showPreview = !_showPreview;
    notifyListeners();
  }

  // --- CameraImage → InputImage 변환 ---
  InputImage? _convertToInputImage(CameraImage image) {
    // google_mlkit_commons의 InputImage.fromBytes() 사용
    // NV21/YUV420 → InputImage 변환 로직
    // (플랫폼별 rotation 보정 포함)
    // ... 구현 상세는 구현 단계에서
  }

  @override
  void dispose() {
    stopDetection();
    _cameraController?.dispose();
    _faceService.dispose();
    super.dispose();
  }
}
```

### 5-7. `feedback_provider.dart` — 피드백 상태 관리

```dart
class FeedbackProvider extends ChangeNotifier {
  final FeedbackService _service = FeedbackService();
  bool _isInitialized = false;
  String _lastFeedback = '';

  String get lastFeedback => _lastFeedback;

  Future<void> initialize() async {
    await _service.initialize();
    _isInitialized = true;
  }

  Future<void> giveFeedback(String message) async {
    _lastFeedback = message;
    notifyListeners();
    await _service.giveFeedback(message);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
```

### 5-8. `camera_preview_overlay.dart` — 원형 미리보기 위젯

```dart
class CameraPreviewOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FacialGestureProvider>(
      builder: (context, gesture, _) {
        if (!gesture.isInitialized) return const SizedBox.shrink();

        return Positioned(
          right: 16,
          bottom: 80, // FAB 위
          child: GestureDetector(
            onTap: gesture.togglePreview,
            child: gesture.showPreview
                ? _buildPreview(gesture)
                : _buildToggleButton(gesture),
          ),
        );
      },
    );
  }

  Widget _buildPreview(FacialGestureProvider gesture) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: gesture.isActive ? Colors.green : Colors.grey,
          width: 3,
        ),
      ),
      child: ClipOval(
        child: CameraPreview(gesture.cameraController!),
      ),
    );
  }

  Widget _buildToggleButton(FacialGestureProvider gesture) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gesture.isActive
            ? Colors.green.withOpacity(0.8)
            : Colors.grey.withOpacity(0.8),
      ),
      child: Icon(
        gesture.isActive ? Icons.face : Icons.face_outlined,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
```

---

## 6. 기존 코드 수정 사항

### 6-1. `main.dart` — Provider 등록

```dart
// 기존 providers에 추가
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ReaderProvider()),
    ChangeNotifierProvider(create: (_) => SpeechProvider()),
    ChangeNotifierProvider(create: (_) => FacialGestureProvider()),  // ★ 추가
    ChangeNotifierProvider(create: (_) => FeedbackProvider()),       // ★ 추가
  ],
  child: MaterialApp(...),
)
```

### 6-2. `reader_screen.dart` — 초기화 + UI 통합

```dart
// _initialize() 수정
Future<void> _initialize() async {
  // 기존: 마이크 권한
  final micStatus = await Permission.microphone.request();
  // 추가: 카메라 권한
  final camStatus = await Permission.camera.request();

  if (mounted) {
    final readerProvider = context.read<ReaderProvider>();
    final speechProvider = context.read<SpeechProvider>();
    final gestureProvider = context.read<FacialGestureProvider>();  // ★
    final feedbackProvider = context.read<FeedbackProvider>();      // ★

    readerProvider.loadText(widget.textContent);
    await speechProvider.initialize();
    speechProvider.onCommandRecognized = readerProvider.executeCommand;

    // ★ 얼굴 제스처 초기화
    await feedbackProvider.initialize();
    if (camStatus.isGranted) {
      await gestureProvider.initialize();
      gestureProvider.onGestureCommand = readerProvider.executeCommand;
      gestureProvider.onFeedback = feedbackProvider.giveFeedback;
      gestureProvider.startDetection();
    }
  }
}

// build() 수정 — Stack으로 카메라 오버레이 추가
@override
Widget build(BuildContext context) {
  return Scaffold(
    // ... 기존 AppBar + body ...
    body: Stack(
      children: [
        Column(/* 기존 body 내용 */),
        const CameraPreviewOverlay(),  // ★ 카메라 오버레이
      ],
    ),
    floatingActionButton: const VoiceControlButton(),
  );
}
```

### 6-3. `AndroidManifest.xml` — 카메라 권한

```xml
<!-- 기존 RECORD_AUDIO 아래 추가 -->
<uses-permission android:name="android.permission.CAMERA" />
```

---

## 7. 성능 최적화 전략

### 7-1. 프레임 스로틀링
| 전략 | 설명 |
|------|------|
| 매 3번째 프레임만 처리 | 30fps 카메라 → ~10fps 감지, 충분한 반응성 |
| `_isBusy` 플래그 | ML Kit 처리 중 추가 프레임 스킵 |
| `ResolutionPreset.low` | 얼굴 분류에 고해상도 불필요 |

### 7-2. ML Kit 최적화
| 설정 | 값 | 이유 |
|------|-----|------|
| `enableContours` | `false` | 윤곽선 불필요 → CPU 절약 |
| `enableLandmarks` | `false` | 랜드마크 불필요 → CPU 절약 |
| `enableTracking` | `false` | 단일 사용자 → 트래킹 불필요 |
| `enableClassification` | `true` | 눈/웃음 확률 **필수** |
| `performanceMode` | `fast` | 정확도 약간 희생, 속도 우선 |
| `minFaceSize` | `0.3` | 화면의 30% 이상만 감지 (원거리 필터) |

### 7-3. 메모리 관리
- `CameraController`의 `dispose()` 보장 (ReaderScreen 해제 시)
- `FaceDetector.close()` 보장
- `startImageStream` / `stopImageStream` 라이프사이클과 동기화
- AppLifecycleState 감지: `inactive` → 감지 중지, `resumed` → 재시작

### 7-4. 배터리 절약
- 제스처 감지는 명시적 토글로 ON/OFF 가능
- 카메라 미리보기 숨김 시에도 감지는 계속 (UI 렌더링만 절약)
- `ResolutionPreset.low` + 스로틀링으로 최소 전력 소비

---

## 8. 오인식 방지 전략

```
┌───────────────────────────────────────────────┐
│              오인식 방지 5중 장치               │
├───────────────────────────────────────────────┤
│ 1. Hysteresis 임계값                           │
│    closed < 0.3 / open > 0.6 (갭: 0.3)       │
│    → 경계값 떨림으로 인한 오감지 방지            │
├───────────────────────────────────────────────┤
│ 2. 양쪽 눈 동시 감지                           │
│    → 윙크(한쪽 눈)는 무시                      │
├───────────────────────────────────────────────┤
│ 3. 3회 깜빡임 요구                             │
│    → 자연스러운 깜빡임(단발)과 구분              │
├───────────────────────────────────────────────┤
│ 4. 시간 윈도우 (3초)                           │
│    → 산발적 깜빡임 누적 방지                    │
├───────────────────────────────────────────────┤
│ 5. 쿨다운 (3초)                               │
│    → 연속 트리거 방지                          │
└───────────────────────────────────────────────┘
```

---

## 9. 구현 순서 (단계별)

### Phase 1: 기반 (인프라)
1. `pubspec.yaml`에 의존성 추가
2. `AndroidManifest.xml` + iOS `Info.plist` 권한 설정
3. `gesture_event.dart` 열거형 생성

### Phase 2: 도메인 서비스
4. `blink_detector.dart` 구현 + 단위 테스트
5. `smile_detector.dart` 구현 + 단위 테스트
6. `face_detection_service.dart` ML Kit 래퍼 구현
7. `feedback_service.dart` TTS + 진동 구현

### Phase 3: 프레젠테이션 레이어
8. `facial_gesture_provider.dart` 구현 (카메라 + 서비스 통합)
9. `feedback_provider.dart` 구현
10. `camera_preview_overlay.dart` 위젯 구현

### Phase 4: 통합
11. `main.dart` Provider 등록
12. `reader_screen.dart` 초기화 + UI 통합
13. 도움말 다이얼로그 업데이트

### Phase 5: 안정화
14. 실기기 테스트 (성능 프로파일링)
15. 엣지 케이스 처리 (카메라 없는 기기, 권한 거부 등)
16. AppLifecycleState 대응

---

## 10. 엣지 케이스 처리

| 케이스 | 대응 |
|--------|------|
| 전면 카메라 없는 기기 | `cameras.firstWhere` fallback → 후면 카메라 사용 or 기능 비활성 |
| 카메라 권한 거부 | 음성 명령만 사용, 제스처 버튼 숨김, SnackBar 안내 |
| 얼굴 미감지 (카메라 가림 등) | 자동으로 감지 대기, 별도 에러 없음 |
| 안경 착용 | ML Kit가 자체 보정, 임계값 0.3은 안경에도 충분히 작동 |
| 어두운 환경 | `ResolutionPreset.low`에서도 ML Kit 동작하나 정확도 하락 → 피드백 없이 무시 |
| TTS + 음성 인식 동시 | TTS 발화 중 음성 인식은 SpeechProvider가 별도 관리 → 충돌 없음 |
| 앱 백그라운드 전환 | AppLifecycleState.inactive → 감지 중지 + 카메라 해제 |

---

## 11. 테스트 전략

### 단위 테스트 (순수 Dart)
- `BlinkDetector`: 3회 깜빡임 정확 감지, 윈도우 초과 리셋, 윙크 무시
- `SmileDetector`: 1초 지속 감지, 중단 시 리셋
- 쿨다운 로직: 3초 이내 재트리거 방지

### 위젯 테스트
- `CameraPreviewOverlay`: 토글 동작, 활성/비활성 상태 표시
- Provider 통합: 제스처 → executeCommand 연결

### 통합 테스트 (실기기)
- 실제 깜빡임/웃음으로 페이지 전환 확인
- 성능 프로파일링 (60fps 유지 확인)
- 배터리 소모 측정

---

## 12. 참고 자료

- [google_mlkit_face_detection](https://pub.dev/packages/google_mlkit_face_detection) — ML Kit 공식 패키지
- [Fritz AI — Blink Detection](https://fritz.ai/blink-detection-on-android-using-firebase-ml-kits-face-detection-api/) — 깜빡임 감지 알고리즘
- [M2P Fintech — Liveness Detection](https://m2pfintech.com/blog/unmask-the-power-of-face-liveness-detection-integrating-google-ml-kit-into-your-flutter-app/) — 라이브니스 감지 아키텍처
- [Flutter Liveness Detection (Medium)](https://medium.com/@codewithwan/flutter-liveness-detection-with-ml-kit-simplified-and-cool-9d2db2d46917) — 상태 머신 패턴
- [60 FPS Object Detection (2026)](https://medium.com/@cia1099/approached-60-fps-object-detection-without-any-frame-dropout-on-mobile-devices-with-flutter-6ab3c9dc5c4b) — 프레임 스로틀링 최적화
- [Flutter Camera State Management](https://colinchflutter.github.io/2023-10-10/09-01-02-673799-flutter-camera-state-management/) — Provider 기반 카메라 관리
- [Youblink-AI GitHub](https://github.com/ZaryabAlam/Youblink-AI) — 참조 구현
