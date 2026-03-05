import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../domain/enums/gesture_event.dart';
import '../../domain/enums/voice_command.dart';
import '../../domain/services/blink_detector.dart';
import '../../domain/services/face_detection_service.dart';
import '../../domain/services/smile_detector.dart';

/// 얼굴 제스처 감지 통합 Provider
///
/// 카메라 스트림 → ML Kit 얼굴 감지 → 깜빡임/웃음 상태 머신 → 명령 발행
/// 의 전체 파이프라인을 오케스트레이션한다.
class FacialGestureProvider extends ChangeNotifier {
  // === 서비스 ===
  final FaceDetectionService _faceService = FaceDetectionService();
  final BlinkDetector _blinkDetector = BlinkDetector();
  final SmileDetector _smileDetector = SmileDetector();

  // === 카메라 ===
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isActive = false;

  // === 쿨다운 ===
  DateTime? _lastTriggerTime;
  static const Duration _cooldownDuration = Duration(seconds: 3);

  // === UI 상태 ===
  bool _showPreview = false;

  // === 프레임 스로틀 ===
  int _frameCount = 0;
  static const int _processEveryNthFrame = 3; // ~10fps

  // === 콜백 ===
  void Function(VoiceCommand)? onGestureCommand;
  void Function(String)? onFeedback;

  // --- Getters ---
  bool get isInitialized => _isInitialized;
  bool get isActive => _isActive;
  bool get showPreview => _showPreview;
  int get blinkCount => _blinkDetector.blinkCount;
  CameraController? get cameraController => _cameraController;

  /// 카메라 초기화 (전면 카메라 우선)
  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final frontCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('FacialGestureProvider: 카메라 초기화 실패 - $e');
    }
  }

  /// 제스처 감지 시작
  void startDetection() {
    if (!_isInitialized || _isActive) return;
    _isActive = true;
    _frameCount = 0;

    _cameraController!.startImageStream(_onCameraFrame);
    notifyListeners();
  }

  /// 제스처 감지 중지
  void stopDetection() {
    if (!_isActive) return;
    _isActive = false;
    _cameraController?.stopImageStream();
    _blinkDetector.reset();
    _smileDetector.reset();
    notifyListeners();
  }

  /// 감지 활성/비활성 토글
  void toggleDetection() {
    if (_isActive) {
      stopDetection();
    } else {
      startDetection();
    }
  }

  /// 카메라 미리보기 토글
  void togglePreview() {
    _showPreview = !_showPreview;
    notifyListeners();
  }

  // === 내부 로직 ===

  void _onCameraFrame(CameraImage image) {
    _frameCount++;
    if (_frameCount % _processEveryNthFrame != 0) return;
    if (_isInCooldown()) return;

    final inputImage = _convertToInputImage(image);
    if (inputImage == null) return;

    _faceService.processImage(inputImage).then((faces) {
      if (faces == null || faces.isEmpty) return;
      _onFaceDetected(faces.first);
    });
  }

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

    // UI 업데이트 (깜빡임 카운트 표시)
    notifyListeners();
  }

  void _triggerGesture(GestureEvent event) {
    _lastTriggerTime = DateTime.now();
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

  /// CameraImage → InputImage 변환
  InputImage? _convertToInputImage(CameraImage image) {
    final camera = _cameraController;
    if (camera == null) return null;

    final sensorOrientation = camera.description.sensorOrientation;
    InputImageRotation? rotation;

    if (Platform.isAndroid) {
      // Android: 전면 카메라 회전 보정
      final rotationCompensation =
          camera.description.lensDirection == CameraLensDirection.front
              ? (sensorOrientation + 360) % 360
              : (sensorOrientation + 360) % 360;
      rotation = _rotationIntToImageRotation(rotationCompensation);
    } else if (Platform.isIOS) {
      rotation = _rotationIntToImageRotation(sensorOrientation);
    }

    if (rotation == null) return null;

    final format = Platform.isAndroid
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;

    // 평면 데이터 합치기
    final bytes = _concatenatePlanes(image.planes);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  InputImageRotation? _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return null;
    }
  }

  @override
  void dispose() {
    stopDetection();
    _cameraController?.dispose();
    _faceService.dispose();
    super.dispose();
  }
}
