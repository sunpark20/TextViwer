/// 음성 명령 열거형
enum VoiceCommand {
  /// 다음 페이지로 이동
  next,

  /// 이전 페이지로 이동
  previous,

  /// 첫 페이지로 이동
  first,

  /// 마지막 페이지로 이동
  last,

  /// 음성 인식 시작
  startListening,

  /// 음성 인식 중지
  stopListening,

  /// 인식되지 않은 명령
  unknown,
}
