import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/reader_provider.dart';
import 'presentation/providers/speech_provider.dart';
import 'presentation/screens/reader_screen.dart';
import 'data/sample_texts/sample_texts.dart';

void main() {
  runApp(const VoiceTextViewerApp());
}

class VoiceTextViewerApp extends StatelessWidget {
  const VoiceTextViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReaderProvider()),
        ChangeNotifierProvider(create: (_) => SpeechProvider()),
      ],
      child: MaterialApp(
        title: '음성 텍스트 뷰어',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

/// 홈 화면 - 샘플 텍스트 선택
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('음성 텍스트 뷰어'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '읽을 텍스트를 선택하세요',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // 한국어 샘플
            _buildSampleCard(
              context,
              title: '한국어 이야기',
              subtitle: '현명한 노인과 젊은이의 이야기',
              icon: Icons.menu_book,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReaderScreen(
                      textContent: SampleTexts.koreanSample,
                      title: '한국어 이야기',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 영어 샘플
            _buildSampleCard(
              context,
              title: 'English Story',
              subtitle: 'Story of a wise old man and a young person',
              icon: Icons.auto_stories,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReaderScreen(
                      textContent: SampleTexts.englishSample,
                      title: 'English Story',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 짧은 테스트
            _buildSampleCard(
              context,
              title: '빠른 테스트',
              subtitle: '음성 명령 테스트용 짧은 텍스트',
              icon: Icons.flash_on,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReaderScreen(
                      textContent: SampleTexts.shortTest,
                      title: '음성 명령 테스트',
                    ),
                  ),
                );
              },
            ),

            const Spacer(),

            // 사용 안내
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '사용 방법',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. 텍스트를 선택하세요\n'
                    '2. 마이크 버튼을 눌러 음성 인식을 시작하세요\n'
                    '3. "다음", "이전" 등의 명령어를 말씀하세요\n'
                    '4. 또는 스와이프로 페이지를 넘기세요',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
