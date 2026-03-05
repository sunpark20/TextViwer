import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// TTS 음성 안내 + 진동 이중 피드백 서비스
class FeedbackService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(0.6);
    await _tts.setVolume(0.8);
    _isInitialized = true;
  }

  /// 진동 + TTS 피드백을 제공한다.
  Future<void> giveFeedback(String message) async {
    // 진동 먼저 (즉각적)
    HapticFeedback.mediumImpact();
    // TTS
    if (_isInitialized) {
      await _tts.speak(message);
    }
  }

  void dispose() {
    _tts.stop();
  }
}
