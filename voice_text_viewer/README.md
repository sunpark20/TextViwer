# 음성 텍스트 뷰어 (Voice Text Viewer)

음성 명령으로 페이지를 넘길 수 있는 혁신적인 텍스트 뷰어 앱입니다.

## 주요 기능

- **음성 명령 페이지 넘김**: "다음", "이전" 등의 음성 명령으로 핸즈프리 페이지 이동
- **다국어 지원**: 한국어와 영어 음성 인식 지원
- **직관적인 UI**: 깔끔하고 사용하기 쉬운 인터페이스
- **크로스 플랫폼**: iOS와 Android 모두 지원
- **실시간 피드백**: 인식된 음성을 화면에 표시

## 지원 음성 명령어

### 한국어
- **다음**: 다음 페이지로 이동
- **이전**: 이전 페이지로 이동
- **처음**: 첫 페이지로 이동
- **끝**: 마지막 페이지로 이동
- **멈춰**: 음성 인식 중지

### 영어
- **next**: Go to next page
- **previous**: Go to previous page
- **first**: Go to first page
- **last**: Go to last page
- **stop**: Stop listening

## 설치 방법

### 사전 요구사항
- Flutter SDK 3.2.0 이상
- Dart SDK 3.0.0 이상
- iOS: Xcode 14 이상
- Android: Android Studio 및 Android SDK 21 이상

### 설치 단계

1. **Flutter 의존성 설치**
```bash
cd voice_text_viewer
flutter pub get
```

2. **iOS 설정 (iOS 개발 시)**
```bash
cd ios
pod install
cd ..
```

3. **앱 실행**
```bash
# iOS 실행
flutter run -d ios

# Android 실행
flutter run -d android

# 특정 디바이스에서 실행
flutter devices  # 사용 가능한 디바이스 목록 확인
flutter run -d [device-id]
```

## 프로젝트 구조

```
voice_text_viewer/
├── lib/
│   ├── main.dart                          # 앱 진입점
│   ├── core/                              # 핵심 유틸리티
│   │   ├── constants/
│   │   │   └── voice_commands.dart        # 음성 명령어 정의
│   │   └── utils/
│   │       └── text_paginator.dart        # 텍스트 페이지 분할
│   ├── domain/                            # 도메인 계층
│   │   ├── enums/
│   │   │   └── voice_command.dart         # 음성 명령 열거형
│   │   └── services/
│   │       ├── speech_recognition_service.dart  # 음성인식 서비스
│   │       └── voice_command_processor.dart     # 명령 처리 로직
│   ├── data/                              # 데이터 계층
│   │   └── sample_texts/
│   │       └── sample_texts.dart          # 샘플 텍스트
│   └── presentation/                      # UI 계층
│       ├── providers/
│       │   ├── reader_provider.dart       # 뷰어 상태관리
│       │   └── speech_provider.dart       # 음성인식 상태관리
│       ├── screens/
│       │   └── reader_screen.dart         # 메인 리더 화면
│       └── widgets/
│           ├── page_view_reader.dart      # 페이지 뷰어 위젯
│           └── voice_control_button.dart  # 음성 제어 버튼
├── android/                               # Android 설정
├── ios/                                   # iOS 설정
└── pubspec.yaml                           # 의존성 정의
```

## 사용 방법

1. **앱 실행**: 앱을 실행하면 홈 화면에서 읽을 텍스트를 선택할 수 있습니다

2. **텍스트 선택**:
   - 한국어 이야기
   - English Story
   - 빠른 테스트 (짧은 텍스트)

3. **음성 인식 시작**:
   - 화면 하단의 마이크 버튼을 탭합니다
   - 마이크 권한을 허용합니다
   - 버튼이 빨간색으로 변하면 음성 인식이 시작된 것입니다

4. **음성 명령 사용**:
   - "다음" 또는 "next"라고 말하면 다음 페이지로 이동합니다
   - "이전" 또는 "previous"라고 말하면 이전 페이지로 이동합니다
   - 기타 명령어는 위의 "지원 음성 명령어" 섹션을 참조하세요

5. **언어 전환**:
   - 상단 우측의 언어 아이콘을 탭합니다
   - 한국어 또는 영어를 선택합니다

6. **수동 페이지 넘김**:
   - 화면을 좌우로 스와이프하여 페이지를 넘길 수도 있습니다

## 기술 스택

- **Flutter**: 크로스 플랫폼 UI 프레임워크
- **speech_to_text**: 음성 인식 패키지
- **permission_handler**: 권한 관리 패키지
- **provider**: 상태 관리 패키지

## 권한

### Android
- `RECORD_AUDIO`: 음성 인식을 위한 마이크 접근
- `INTERNET`: 음성 인식 서비스 이용

### iOS
- `NSMicrophoneUsageDescription`: 마이크 사용 권한
- `NSSpeechRecognitionUsageDescription`: 음성 인식 권한

## 테스트 방법

### 1. 짧은 테스트로 빠르게 확인
홈 화면에서 "빠른 테스트"를 선택하면 짧은 텍스트로 음성 명령을 테스트할 수 있습니다.

### 2. 음성 명령 테스트
```
1. 마이크 버튼 클릭
2. "다음" 말하기 → 다음 페이지로 이동 확인
3. "이전" 말하기 → 이전 페이지로 이동 확인
4. "처음" 말하기 → 첫 페이지로 이동 확인
5. "끝" 말하기 → 마지막 페이지로 이동 확인
```

### 3. 언어 전환 테스트
```
1. 언어 아이콘 클릭
2. English 선택
3. "next" 말하기 → 다음 페이지로 이동 확인
4. 언어 아이콘 클릭
5. 한국어 선택
6. "다음" 말하기 → 다음 페이지로 이동 확인
```

## 알려진 제한사항

- 음성 인식 정확도는 주변 소음, 발음, 기기 성능에 따라 달라질 수 있습니다
- 일부 Android 기기에서는 음성 인식이 지원되지 않을 수 있습니다
- 오프라인 음성 인식은 지원하지 않습니다 (인터넷 연결 필요)
- iOS 시뮬레이터에서는 음성 인식이 작동하지 않습니다 (실제 기기 필요)

## 문제 해결

### 음성 인식이 작동하지 않는 경우
1. 마이크 권한이 허용되었는지 확인하세요
2. 인터넷 연결을 확인하세요
3. 기기의 언어 설정이 올바른지 확인하세요
4. 앱을 재시작해보세요

### 권한 오류가 발생하는 경우
1. 설정 > 앱 > 음성 텍스트 뷰어 > 권한
2. 마이크 권한을 허용으로 변경

### iOS에서 앱이 실행되지 않는 경우
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

## 향후 개발 계획

- [ ] TTS (텍스트 음성 변환) 기능 추가
- [ ] 외부 텍스트 파일 불러오기
- [ ] 북마크 기능
- [ ] 다크 모드 지원
- [ ] 글꼴 크기 조절
- [ ] 읽기 진행률 저장
- [ ] PDF 파일 지원

## 라이선스

MIT License

## 기여

기여는 언제나 환영합니다! Pull Request를 보내주세요.

## 문의

문제가 발생하거나 제안 사항이 있으시면 Issue를 등록해주세요.

---

**Made with Flutter**
