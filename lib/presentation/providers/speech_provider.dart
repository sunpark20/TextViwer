import 'package:flutter/material.dart';
import '../../domain/enums/voice_command.dart';
import '../../domain/services/speech_recognition_service.dart';
import '../../domain/services/voice_command_processor.dart';

/// 음성 인식 상태 관리 Provider
class SpeechProvider extends ChangeNotifier {
  final SpeechRecognitionService _service = SpeechRecognitionService();
  final VoiceCommandProcessor _processor = VoiceCommandProcessor();

  bool _isListening = false;
  bool _isAvailable = false;
  String _lastRecognizedText = '';
  String _currentLocale = 'ko_KR'; // 기본: 한국어
  VoiceCommand _lastCommand = VoiceCommand.unknown;

  /// 음성 인식 중 여부
  bool get isListening => _isListening;

  /// 음성 인식 사용 가능 여부
  bool get isAvailable => _isAvailable;

  /// 마지막으로 인식된 텍스트
  String get lastRecognizedText => _lastRecognizedText;

  /// 현재 언어 설정
  String get currentLocale => _currentLocale;

  /// 마지막 인식된 명령
  VoiceCommand get lastCommand => _lastCommand;

  /// 음성 명령이 인식되었을 때 호출할 콜백
  Function(VoiceCommand)? onCommandRecognized;

  /// 음성 인식 초기화
  Future<void> initialize() async {
    _isAvailable = await _service.initialize();
    notifyListeners();
  }

  /// 음성 인식 시작/중지 토글
  Future<void> toggleListening() async {
    if (_isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  /// 음성 인식 시작
  Future<void> startListening() async {
    if (!_isAvailable) {
      print('Speech recognition not available');
      return;
    }

    try {
      _isListening = true;
      _lastRecognizedText = '';
      notifyListeners();

      await _service.startListening(
        onResult: _onSpeechResult,
        localeId: _currentLocale,
      );
    } catch (e) {
      print('Error starting listening: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  /// 음성 인식 중지
  Future<void> stopListening() async {
    try {
      await _service.stopListening();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      print('Error stopping listening: $e');
    }
  }

  /// 음성 인식 결과 처리
  void _onSpeechResult(String text) {
    _lastRecognizedText = text;

    // 음성 명령 처리
    final command = _processor.processCommand(text);
    _lastCommand = command;

    print('Recognized text: $text');
    print('Command: ${_processor.getCommandDescription(command)}');

    // 명령이 인식되면 콜백 호출
    if (command != VoiceCommand.unknown) {
      onCommandRecognized?.call(command);

      // 중지 명령이면 음성 인식 중지
      if (command == VoiceCommand.stopListening) {
        stopListening();
      }
    }

    notifyListeners();
  }

  /// 언어 설정 변경
  ///
  /// [localeId]: 'ko_KR' (한국어) 또는 'en_US' (영어)
  void setLocale(String localeId) {
    _currentLocale = localeId;
    notifyListeners();

    // 음성 인식 중이면 재시작
    if (_isListening) {
      stopListening().then((_) => startListening());
    }
  }

  /// 한국어로 전환
  void setKorean() {
    setLocale('ko_KR');
  }

  /// 영어로 전환
  void setEnglish() {
    setLocale('en_US');
  }

  /// 현재 한국어 모드인지 확인
  bool get isKorean => _currentLocale.startsWith('ko');

  /// 상태 초기화
  void reset() {
    _lastRecognizedText = '';
    _lastCommand = VoiceCommand.unknown;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
