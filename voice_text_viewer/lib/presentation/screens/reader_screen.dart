import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/reader_provider.dart';
import '../providers/speech_provider.dart';
import '../widgets/page_view_reader.dart';
import '../widgets/voice_control_button.dart';

/// 메인 텍스트 리더 화면
class ReaderScreen extends StatefulWidget {
  final String textContent;
  final String title;

  const ReaderScreen({
    super.key,
    required this.textContent,
    this.title = '음성 텍스트 뷰어',
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 마이크 권한 요청
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('마이크 권한이 필요합니다'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    // Provider 초기화
    if (mounted) {
      final readerProvider = context.read<ReaderProvider>();
      final speechProvider = context.read<SpeechProvider>();

      // 텍스트 로드
      readerProvider.loadText(widget.textContent);

      // 음성 인식 초기화
      await speechProvider.initialize();

      // 음성 명령 콜백 설정
      speechProvider.onCommandRecognized = readerProvider.executeCommand;
    }
  }

  void _showLanguageDialog(BuildContext context, SpeechProvider speech) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('언어 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇰🇷'),
              title: const Text('한국어'),
              trailing: speech.isKorean
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                speech.setKorean();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇺🇸'),
              title: const Text('English'),
              trailing: !speech.isKorean
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                speech.setEnglish();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // 언어 전환 버튼
          Consumer<SpeechProvider>(
            builder: (context, speech, _) => IconButton(
              icon: const Icon(Icons.language),
              onPressed: () => _showLanguageDialog(context, speech),
              tooltip: '언어 선택',
            ),
          ),
          // 정보 버튼
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showHelpDialog(context),
            tooltip: '도움말',
          ),
        ],
      ),
      body: Column(
        children: [
          // 음성 인식 상태 표시
          Consumer<SpeechProvider>(
            builder: (context, speech, _) {
              if (speech.isListening && speech.lastRecognizedText.isNotEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.mic, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '인식됨: ${speech.lastRecognizedText}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // 페이지 표시기
          Consumer<ReaderProvider>(
            builder: (context, reader, _) {
              if (reader.pages.isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${reader.currentPage + 1} / ${reader.totalPages}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),

          // 텍스트 뷰어
          Expanded(
            child: Consumer<ReaderProvider>(
              builder: (context, reader, _) => PageViewReader(
                pages: reader.pages,
                controller: reader.pageController,
                onPageChanged: reader.onPageChanged,
              ),
            ),
          ),

          // 명령어 가이드
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Consumer<SpeechProvider>(
              builder: (context, speech, _) {
                final commands = speech.isKorean
                    ? '명령어: "다음", "이전", "처음", "끝"'
                    : 'Commands: "next", "previous", "first", "last"';
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      commands,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: const VoiceControlButton(),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용 방법'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '음성 명령어',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              Text('• "다음" 또는 "next" - 다음 페이지'),
              Text('• "이전" 또는 "previous" - 이전 페이지'),
              Text('• "처음" 또는 "first" - 첫 페이지'),
              Text('• "끝" 또는 "last" - 마지막 페이지'),
              Text('• "멈춰" 또는 "stop" - 음성 인식 중지'),
              SizedBox(height: 16),
              Text(
                '사용 팁',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              Text('1. 마이크 버튼을 눌러 음성 인식을 시작하세요'),
              Text('2. 명령어를 또렷하게 말씀하세요'),
              Text('3. 언어 버튼으로 한국어/영어를 전환할 수 있습니다'),
              Text('4. 스와이프로도 페이지를 넘길 수 있습니다'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
