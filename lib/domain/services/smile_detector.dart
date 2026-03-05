/// 웃음 감지 상태 머신
///
/// smilingProbability가 임계값(0.85)을 초과한 상태가
/// 1초 이상 연속 지속되면 트리거를 발생시킨다.
/// 임계값 미만으로 떨어지면 타이머가 리셋된다.
class SmileDetector {
  static const double _smileThreshold = 0.85;
  static const Duration _requiredDuration = Duration(seconds: 1);

  DateTime? _smileStart;

  /// 현재 웃음이 시작된 이후 경과 시간 (UI 표시용)
  Duration get smileDuration {
    if (_smileStart == null) return Duration.zero;
    return DateTime.now().difference(_smileStart!);
  }

  /// 프레임 데이터를 입력받아 웃음 상태를 업데이트한다.
  /// 1초 지속 웃음 달성 시 true를 반환한다.
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

  /// 상태 초기화
  void reset() {
    _smileStart = null;
  }
}
