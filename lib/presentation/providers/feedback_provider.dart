import 'package:flutter/foundation.dart';

import '../../domain/services/feedback_service.dart';

/// TTS + 진동 피드백 상태 관리 Provider
class FeedbackProvider extends ChangeNotifier {
  final FeedbackService _service = FeedbackService();
  bool _isInitialized = false;
  String _lastFeedback = '';

  String get lastFeedback => _lastFeedback;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    await _service.initialize();
    _isInitialized = true;
  }

  /// 진동 + TTS 피드백을 제공하고 상태를 업데이트한다.
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
