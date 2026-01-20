import 'package:speech_to_text/speech_to_text.dart';

/// 음성 인식 서비스 클래스
/// speech_to_text 패키지를 래핑하여 음성 인식 기능 제공
class SpeechRecognitionService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  /// 음성 인식 초기화
  ///
  /// Returns: 초기화 성공 여부
  Future<bool> initialize() async {
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) => print('Speech recognition status: $status'),
      );
      return _isInitialized;
    } catch (e) {
      print('Failed to initialize speech recognition: $e');
      return false;
    }
  }

  /// 음성 인식 시작
  ///
  /// [onResult]: 음성 인식 결과를 받을 콜백 함수
  /// [localeId]: 음성 인식 언어 (기본값: 한국어 'ko_KR')
  Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'ko_KR',
  }) async {
    if (!_isInitialized) {
      print('Speech recognition not initialized');
      return;
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          }
        },
        localeId: localeId,
        listenMode: ListenMode.confirmation,
        cancelOnError: false,
        partialResults: true,
        onSoundLevelChange: (level) {
          // 소리 레벨 변화 감지 (옵션)
        },
      );
    } catch (e) {
      print('Failed to start listening: $e');
    }
  }

  /// 음성 인식 중지
  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
    } catch (e) {
      print('Failed to stop listening: $e');
    }
  }

  /// 음성 인식 취소
  Future<void> cancel() async {
    try {
      await _speechToText.cancel();
    } catch (e) {
      print('Failed to cancel listening: $e');
    }
  }

  /// 현재 음성 인식 중인지 여부
  bool get isListening => _speechToText.isListening;

  /// 음성 인식 사용 가능 여부
  bool get isAvailable => _isInitialized;

  /// 사용 가능한 언어 목록 조회
  Future<List<LocaleName>> get locales async {
    if (!_isInitialized) return [];
    return await _speechToText.locales();
  }

  /// 음성 인식 리소스 정리
  void dispose() {
    _speechToText.stop();
  }
}
