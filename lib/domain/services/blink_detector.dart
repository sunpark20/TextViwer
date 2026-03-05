/// 눈 깜빡임 감지 상태 머신
///
/// 양쪽 눈이 동시에 감겼다 떠지는 전환(open→closed→open)을 추적하여
/// 3초 이내 3회 깜빡임 시 트리거를 발생시킨다.
///
/// 오인식 방지:
/// - Hysteresis: closed < 0.3, open > 0.6 (갭 0.3)
/// - 양쪽 눈 동시 감지 필수 (윙크 필터링)
/// - 3회 요구 (자연 깜빡임과 구분)
/// - 3초 윈도우 (산발적 깜빡임 누적 방지)
class BlinkDetector {
  static const double _closedThreshold = 0.3;
  static const double _openThreshold = 0.6;
  static const int _requiredBlinks = 3;
  static const Duration _windowDuration = Duration(seconds: 3);

  bool _eyesClosed = false;
  int _blinkCount = 0;
  DateTime? _windowStart;

  /// 현재 누적 깜빡임 횟수 (UI 표시용)
  int get blinkCount => _blinkCount;

  /// 프레임 데이터를 입력받아 깜빡임 상태를 업데이트한다.
  /// 3회 깜빡임 달성 시 true를 반환한다.
  bool registerFrame(double leftEyeProb, double rightEyeProb) {
    final bothClosed =
        leftEyeProb < _closedThreshold && rightEyeProb < _closedThreshold;
    final bothOpen =
        leftEyeProb > _openThreshold && rightEyeProb > _openThreshold;

    if (!_eyesClosed && bothClosed) {
      // 눈 감김 전환
      _eyesClosed = true;
    } else if (_eyesClosed && bothOpen) {
      // 눈 뜸 전환 = 1회 깜빡임 완료
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

  /// 상태 초기화
  void reset() {
    _eyesClosed = false;
    _blinkCount = 0;
    _windowStart = null;
  }
}
