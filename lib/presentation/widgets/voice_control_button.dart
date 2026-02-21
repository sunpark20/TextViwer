import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/speech_provider.dart';

/// 음성 제어 플로팅 버튼 위젯
class VoiceControlButton extends StatelessWidget {
  const VoiceControlButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SpeechProvider>(
      builder: (context, speech, _) {
        return FloatingActionButton.extended(
          onPressed: speech.isAvailable ? speech.toggleListening : null,
          backgroundColor: speech.isListening
              ? Colors.red
              : Theme.of(context).primaryColor,
          icon: Icon(
            speech.isListening ? Icons.mic : Icons.mic_none,
            color: Colors.white,
          ),
          label: Text(
            speech.isListening ? '듣는 중...' : '음성 명령',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}
