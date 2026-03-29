import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Renders [text] with every occurrence of [query] highlighted.
/// Used in the debounced search results to show matched characters.
class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    required this.style,
    this.highlightColor = AppColors.primary,
    this.maxLines = 1,
  });

  final String text;
  final String query;
  final TextStyle style;
  final Color highlightColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: style, maxLines: maxLines,
          overflow: TextOverflow.ellipsis);
    }

    final lc = text.toLowerCase();
    final lcQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int cursor = 0;

    while (cursor < text.length) {
      final matchStart = lc.indexOf(lcQuery, cursor);
      if (matchStart == -1) {
        spans.add(TextSpan(text: text.substring(cursor)));
        break;
      }
      // Text before match
      if (matchStart > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, matchStart)));
      }
      // Match itself
      spans.add(TextSpan(
        text: text.substring(matchStart, matchStart + query.length),
        style: style.copyWith(
          color: highlightColor,
          fontWeight: FontWeight.w700,
          backgroundColor: highlightColor.withOpacity(0.1),
        ),
      ));
      cursor = matchStart + query.length;
    }

    return Text.rich(
      TextSpan(children: spans, style: style),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
