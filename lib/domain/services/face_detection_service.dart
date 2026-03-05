import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// ML Kit 얼굴 감지 서비스 래퍼
///
/// - enableClassification: true (눈/웃음 확률값 필수)
/// - contours/landmarks/tracking: OFF (불필요 → 성능 절약)
/// - performanceMode: fast (실시간 처리 우선)
/// - _isBusy 플래그로 프레임 겹침 방지
class FaceDetectionService {
  late final FaceDetector _faceDetector;
  bool _isBusy = false;

  FaceDetectionService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableContours: false,
        enableLandmarks: false,
        enableTracking: false,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.3,
      ),
    );
  }

  /// InputImage를 처리하여 Face 리스트를 반환한다.
  /// 이전 프레임 처리 중이면 null을 반환한다 (스킵).
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
