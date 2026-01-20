import 'package:flutter/material.dart';
import '../../core/utils/text_paginator.dart';
import '../../domain/enums/voice_command.dart';

/// 텍스트 뷰어 상태 관리 Provider
class ReaderProvider extends ChangeNotifier {
  final PageController pageController = PageController();

  List<String> _pages = [];
  int _currentPage = 0;

  /// 현재 페이지 번호 (0부터 시작)
  int get currentPage => _currentPage;

  /// 전체 페이지 수
  int get totalPages => _pages.length;

  /// 페이지 리스트
  List<String> get pages => _pages;

  /// 첫 페이지 여부
  bool get isFirstPage => _currentPage == 0;

  /// 마지막 페이지 여부
  bool get isLastPage => _currentPage == _pages.length - 1;

  /// 텍스트 로드 및 페이지 분할
  ///
  /// [text]: 표시할 텍스트
  /// [charsPerPage]: 페이지당 문자 수
  void loadText(String text, {int charsPerPage = 800}) {
    _pages = TextPaginator.paginate(text, charsPerPage: charsPerPage);
    _currentPage = 0;

    // PageController 초기화
    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }

    notifyListeners();
  }

  /// 페이지 변경 이벤트 처리
  void onPageChanged(int page) {
    _currentPage = page;
    notifyListeners();
  }

  /// 다음 페이지로 이동
  void goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 이전 페이지로 이동
  void goToPreviousPage() {
    if (_currentPage > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 첫 페이지로 이동
  void goToFirstPage() {
    if (_pages.isNotEmpty) {
      pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 마지막 페이지로 이동
  void goToLastPage() {
    if (_pages.isNotEmpty) {
      pageController.animateToPage(
        _pages.length - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 특정 페이지로 이동
  void goToPage(int pageNumber) {
    if (pageNumber >= 0 && pageNumber < _pages.length) {
      pageController.animateToPage(
        pageNumber,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 음성 명령 실행
  ///
  /// [command]: 실행할 음성 명령
  void executeCommand(VoiceCommand command) {
    switch (command) {
      case VoiceCommand.next:
        goToNextPage();
        break;
      case VoiceCommand.previous:
        goToPreviousPage();
        break;
      case VoiceCommand.first:
        goToFirstPage();
        break;
      case VoiceCommand.last:
        goToLastPage();
        break;
      default:
        // 다른 명령은 여기서 처리하지 않음
        break;
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
