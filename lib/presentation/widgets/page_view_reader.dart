import 'package:flutter/material.dart';

/// 텍스트 페이지 뷰어 위젯
class PageViewReader extends StatelessWidget {
  final List<String> pages;
  final PageController controller;
  final Function(int)? onPageChanged;

  const PageViewReader({
    super.key,
    required this.pages,
    required this.controller,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) {
      return const Center(
        child: Text(
          '표시할 텍스트가 없습니다',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      );
    }

    return PageView.builder(
      controller: controller,
      onPageChanged: onPageChanged,
      itemCount: pages.length,
      itemBuilder: (context, index) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Text(
            pages[index],
            style: const TextStyle(
              fontSize: 18,
              height: 1.8,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.justify,
          ),
        );
      },
    );
  }
}
