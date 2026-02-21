import '../enums/voice_command.dart';
import '../../core/constants/voice_commands.dart';

/// 음성 명령 처리 클래스
/// 인식된 음성 텍스트를 VoiceCommand로 변환
class VoiceCommandProcessor {
  /// 인식된 텍스트를 분석하여 명령어로 변환
  ///
  /// [recognizedText]: 음성 인식된 텍스트
  /// Returns: 매칭되는 VoiceCommand 또는 unknown
  VoiceCommand processCommand(String recognizedText) {
    if (recognizedText.isEmpty) {
      return VoiceCommand.unknown;
    }

    final text = recognizedText.toLowerCase().trim();

    // 한국어 명령어 처리
    if (_matchesAny(text, VoiceCommands.nextKorean)) {
      return VoiceCommand.next;
    }
    if (_matchesAny(text, VoiceCommands.previousKorean)) {
      return VoiceCommand.previous;
    }
    if (_matchesAny(text, VoiceCommands.firstKorean)) {
      return VoiceCommand.first;
    }
    if (_matchesAny(text, VoiceCommands.lastKorean)) {
      return VoiceCommand.last;
    }
    if (_matchesAny(text, VoiceCommands.stopKorean)) {
      return VoiceCommand.stopListening;
    }

    // 영어 명령어 처리
    if (_matchesAny(text, VoiceCommands.nextEnglish)) {
      return VoiceCommand.next;
    }
    if (_matchesAny(text, VoiceCommands.previousEnglish)) {
      return VoiceCommand.previous;
    }
    if (_matchesAny(text, VoiceCommands.firstEnglish)) {
      return VoiceCommand.first;
    }
    if (_matchesAny(text, VoiceCommands.lastEnglish)) {
      return VoiceCommand.last;
    }
    if (_matchesAny(text, VoiceCommands.stopEnglish)) {
      return VoiceCommand.stopListening;
    }

    return VoiceCommand.unknown;
  }

  /// 텍스트가 명령어 리스트 중 하나와 매칭되는지 확인
  bool _matchesAny(String text, List<String> commands) {
    return commands.any((cmd) => text.contains(cmd.toLowerCase()));
  }

  /// 명령어 설명 반환 (디버깅/UI용)
  String getCommandDescription(VoiceCommand command) {
    switch (command) {
      case VoiceCommand.next:
        return '다음 페이지로 이동';
      case VoiceCommand.previous:
        return '이전 페이지로 이동';
      case VoiceCommand.first:
        return '첫 페이지로 이동';
      case VoiceCommand.last:
        return '마지막 페이지로 이동';
      case VoiceCommand.startListening:
        return '음성 인식 시작';
      case VoiceCommand.stopListening:
        return '음성 인식 중지';
      case VoiceCommand.unknown:
        return '알 수 없는 명령';
    }
  }
}
