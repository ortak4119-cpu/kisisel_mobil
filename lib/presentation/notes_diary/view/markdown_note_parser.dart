import 'package:flutter/material.dart';

List<TextSpan> parseMarkdownSpans(String text, TextStyle baseStyle) {
  if (text.isEmpty) {
    return [TextSpan(text: '', style: baseStyle)];
  }

  final spans = <TextSpan>[];
  // Daha sağlam bir Regex: İşaretçileri gruplayıp karşılığını (backreference) arar.
  // Grup 1: İşaretçi (** , __ , * , _)
  // Grup 2: İçerik
  final regex = RegExp(r'(\*\*|__|\*|_)(.+?)\1', dotAll: true);

  var lastIndex = 0;
  for (final match in regex.allMatches(text)) {
    // Eşleşme öncesindeki normal metni ekle
    if (match.start > lastIndex) {
      spans.add(TextSpan(
        text: text.substring(lastIndex, match.start),
        style: baseStyle,
      ));
    }

    final marker = match.group(1);
    final content = match.group(2);

    if (content != null) {
      TextStyle style = baseStyle;

      if (marker == '**' || marker == '__') {
        style = style.copyWith(fontWeight: FontWeight.bold);
      } else if (marker == '*') {
        style = style.copyWith(fontStyle: FontStyle.italic);
      } else if (marker == '_') {
        style = style.copyWith(decoration: TextDecoration.underline);
      }

      spans.add(TextSpan(text: content, style: style));
    }

    lastIndex = match.end;
  }

  // Kalan metni ekle
  if (lastIndex < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastIndex),
      style: baseStyle,
    ));
  }

  return spans;
}

class MarkdownNoteText extends StatelessWidget {
  const MarkdownNoteText({
    super.key,
    required this.text,
    required this.baseStyle,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle baseStyle;
  final int? maxLines;
  final TextOverflow overflow;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: parseMarkdownSpans(text, baseStyle),
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: baseStyle,
    );
  }
}
