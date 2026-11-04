import 'package:flutter/material.dart';

// Biçim işaretçileri: * = italik, ** = kalın, *** = kalın+italik.
// (_ = altı çizili, __ = kalın, ___ = kalın+altı çizili — eski/uyumluluk.)
// Eşleşen çiftin işaretleri KULLANICIYA GÖSTERİLMEZ; ayrıca eşleşmeyen tekil
// işaretler de gizlenir, böylece kullanıcı asla *, ** gibi işaret görmez.
final RegExp _emphasisRegex = RegExp(r'(\*{1,3}|_{1,3})(.+?)\1', dotAll: true);

/// İşaretçinin verdiği stili döndürür.
TextStyle mdStyleFor(String marker, TextStyle base) {
  final bool asterisk = marker.startsWith('*');
  final int n = marker.length;
  if (asterisk) {
    if (n == 1) return base.copyWith(fontStyle: FontStyle.italic);
    if (n == 2) return base.copyWith(fontWeight: FontWeight.bold);
    return base.copyWith(
        fontWeight: FontWeight.bold, fontStyle: FontStyle.italic); // ***
  } else {
    if (n == 1) return base.copyWith(decoration: TextDecoration.underline);
    if (n == 2) return base.copyWith(fontWeight: FontWeight.bold);
    return base.copyWith(
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline); // ___
  }
}

/// Metni düz parçalara böler ama tekil (eşleşmeyen) * ve _ karakterlerini
/// [markerStyle] ile (görünmez) ekler — böylece ekranda hiç işaret görünmez.
void _appendHidingStrayMarkers(List<TextSpan> out, String text,
    TextStyle normalStyle, TextStyle markerStyle) {
  final buf = StringBuffer();
  void flush() {
    if (buf.isNotEmpty) {
      out.add(TextSpan(text: buf.toString(), style: normalStyle));
      buf.clear();
    }
  }

  for (int i = 0; i < text.length; i++) {
    final ch = text[i];
    if (ch == '*' || ch == '_') {
      flush();
      out.add(TextSpan(text: ch, style: markerStyle));
    } else {
      buf.write(ch);
    }
  }
  flush();
}

/// Kart/önizleme için: işaretleri TAMAMEN kaldırır, biçimi uygular.
List<TextSpan> parseMarkdownSpans(String text, TextStyle baseStyle) {
  if (text.isEmpty) {
    return [TextSpan(text: '', style: baseStyle)];
  }
  String strip(String s) => s.replaceAll(RegExp(r'[*_]'), '');

  final spans = <TextSpan>[];
  var lastIndex = 0;
  for (final match in _emphasisRegex.allMatches(text)) {
    if (match.start > lastIndex) {
      spans.add(TextSpan(
          text: strip(text.substring(lastIndex, match.start)),
          style: baseStyle));
    }
    final marker = match.group(1)!;
    final content = match.group(2)!;
    spans.add(TextSpan(text: strip(content), style: mdStyleFor(marker, baseStyle)));
    lastIndex = match.end;
  }
  if (lastIndex < text.length) {
    spans.add(TextSpan(text: strip(text.substring(lastIndex)), style: baseStyle));
  }
  return spans;
}

/// Not editöründe canlı markdown gösterimi için controller.
/// İşaretçileri (* , ** , *** , _) metinde KORUR (imleç/seçim konumu
/// bozulmasın diye) ama GÖRÜNMEZ yapar (şeffaf + ~sıfır boyut). Kullanıcı
/// yalnızca biçimlenmiş metni görür; hiçbir işaret görünmez. Eşleşmeyen
/// tekil işaretler de gizlenir.
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

    final markerStyle = base.copyWith(
      color: const Color(0x00000000),
      fontSize: 0.01,
      letterSpacing: 0,
      height: 0.01,
    );

    final children = <TextSpan>[];
    var last = 0;
    for (final m in _emphasisRegex.allMatches(src)) {
      if (m.start > last) {
        _appendHidingStrayMarkers(
            children, src.substring(last, m.start), base, markerStyle);
      }
      final marker = m.group(1)!;
      final content = m.group(2)!;
      final cs = mdStyleFor(marker, base);
      children.add(TextSpan(text: marker, style: markerStyle));
      // İçerik içinde kalan tekil işaretler de gizlensin.
      _appendHidingStrayMarkers(children, content, cs, markerStyle);
      children.add(TextSpan(text: marker, style: markerStyle));
      last = m.end;
    }
    if (last < src.length) {
      _appendHidingStrayMarkers(
          children, src.substring(last), base, markerStyle);
    }
    return TextSpan(style: base, children: children);
  }
}

/// Boş/sarkan biçim işaretçilerini (örn. "****", kullanıcı kalın açıp bir şey
/// yazmadan kapattığında kalan) kayıttan önce temizler.
String cleanNoteMarkers(String s) {
  var out = s;
  // Boş çiftleri kaldır: ****, **, ***, ______ vb. (içi boş).
  final empty = RegExp(r'(\*{1,3}|_{1,3})\1');
  String prev;
  do {
    prev = out;
    out = out.replaceAll(empty, '');
  } while (out != prev);
  return out;
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
