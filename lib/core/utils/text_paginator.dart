/// 텍스트 페이지 분할 유틸리티
class TextPaginator {
  /// 긴 텍스트를 페이지 단위로 분할
  ///
  /// [text]: 분할할 텍스트
  /// [charsPerPage]: 페이지당 최대 문자 수 (기본값: 800)
  /// Returns: 페이지 리스트
  static List<String> paginate(String text, {int charsPerPage = 800}) {
    if (text.isEmpty) {
      return [];
    }

    final pages = <String>[];

    // 문단 단위로 분리 (이중 개행 기준)
    final paragraphs = text.split('\n\n');

    String currentPage = '';

    for (final paragraph in paragraphs) {
      final trimmedParagraph = paragraph.trim();

      if (trimmedParagraph.isEmpty) {
        continue;
      }

      // 현재 페이지에 문단을 추가했을 때 길이 확인
      final potentialLength = currentPage.length + trimmedParagraph.length + 2;

      if (potentialLength > charsPerPage && currentPage.isNotEmpty) {
        // 현재 페이지를 저장하고 새 페이지 시작
        pages.add(currentPage.trim());
        currentPage = trimmedParagraph;
      } else {
        // 현재 페이지에 문단 추가
        if (currentPage.isNotEmpty) {
          currentPage += '\n\n';
        }
        currentPage += trimmedParagraph;
      }
    }

    // 마지막 페이지 추가
    if (currentPage.isNotEmpty) {
      pages.add(currentPage.trim());
    }

    // 페이지가 하나도 없으면 전체 텍스트를 하나의 페이지로
    if (pages.isEmpty && text.isNotEmpty) {
      pages.add(text.trim());
    }

    return pages;
  }

  /// 단순하게 문자 수로만 분할 (단어 중간에서도 자름)
  static List<String> paginateSimple(String text, {int charsPerPage = 800}) {
    if (text.isEmpty) {
      return [];
    }

    final pages = <String>[];
    int start = 0;

    while (start < text.length) {
      final end = (start + charsPerPage < text.length)
          ? start + charsPerPage
          : text.length;

      pages.add(text.substring(start, end));
      start = end;
    }

    return pages;
  }

  /// 문장 단위로 분할 (문장이 잘리지 않도록)
  static List<String> paginateBySentence(String text, {int charsPerPage = 800}) {
    if (text.isEmpty) {
      return [];
    }

    final pages = <String>[];
    // 문장 분리 (마침표, 느낌표, 물음표 기준)
    final sentences = text.split(RegExp(r'([.!?])\s+'));

    String currentPage = '';

    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i].trim();

      if (sentence.isEmpty) {
        continue;
      }

      if ((currentPage.length + sentence.length) > charsPerPage && currentPage.isNotEmpty) {
        pages.add(currentPage.trim());
        currentPage = sentence;
      } else {
        currentPage += ' ' + sentence;
      }
    }

    if (currentPage.isNotEmpty) {
      pages.add(currentPage.trim());
    }

    return pages.isEmpty ? [text] : pages;
  }
}
