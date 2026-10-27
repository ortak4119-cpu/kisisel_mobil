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

/// Not editöründe canlı markdown gösterimi için controller.
/// Metindeki işaretçileri (** , * , _) KORUR (imleç/seçim konumu bozulmasın
/// diye) ama sardıkları metni kalın/italik/altı-çizili gösterir; işaretçiler
/// soluk renkte görünür.
class MarkdownEditingController extends TextEditingController {
  MarkdownEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    final src = text;
    if (src.isEmpty) return TextSpan(style: base, text: '');

    final children = <TextSpan>[];
    final regex = RegExp(r'(\*\*|__|\*|_)(.+?)\1', dotAll: true);
    final markerStyle = base.copyWith(
      color: (base.color ?? const Color(0xFF000000)).withValues(alpha: 0.30),
    );
    var last = 0;
    for (final m in regex.allMatches(src)) {
      if (m.start > last) {
        children.add(TextSpan(text: src.substring(last, m.start), style: base));
      }
      final marker = m.group(1)!;
      final content = m.group(2)!;
      TextStyle cs = base;
      if (marker == '**' || marker == '__') {
        cs = cs.copyWith(fontWeight: FontWeight.bold);
      } else if (marker == '*') {
        cs = cs.copyWith(fontStyle: FontStyle.italic);
      } else if (marker == '_') {
        cs = cs.copyWith(decoration: TextDecoration.underline);
      }
      children.add(TextSpan(text: marker, style: markerStyle));
      children.add(TextSpan(text: content, style: cs));
      children.add(TextSpan(text: marker, style: markerStyle));
      last = m.end;
    }
    if (last < src.length) {
      children.add(TextSpan(text: src.substring(last), style: base));
    }
    return TextSpan(style: base, children: children);
  }
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
