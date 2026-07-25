import 'package:base/presentation/notes_diary/view/markdown_note_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses bold, italic, and underline markers into styled spans', () {
    final spans = parseMarkdownSpans(
      'Hello **bold** and *italic* and _underline_.',
      const TextStyle(fontSize: 14),
    );

    expect(spans.length, 7);
    expect(spans[1].text, 'bold');
    expect(spans[1].style?.fontWeight, FontWeight.w700);
    expect(spans[3].text, 'italic');
    expect(spans[3].style?.fontStyle, FontStyle.italic);
    expect(spans[5].text, 'underline');
    expect(spans[5].style?.decoration, TextDecoration.underline);
  });
}
