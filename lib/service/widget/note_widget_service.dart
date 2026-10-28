import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/init/locator.dart';

/// Ana ekran not widget'ını günceller: en son 3 (arşivlenmemiş, kilitsiz)
/// notun başlık + kısa içeriğini home_widget üzerinden Android'e yazar.
class NoteWidgetService {
  static Future<void> update() async {
    try {
      final response = await noteService.getAllNotes(isArchived: false);
      if (!response.isSuccess || response.data == null) return;

      final notes = response.data!
          .where((n) => !n.isArchived && !n.isLocked)
          .take(3)
          .toList();

      await HomeWidget.saveWidgetData<int>('note_count', notes.length);

      for (var i = 0; i < 3; i++) {
        final n = i < notes.length ? notes[i] : null;
        final title = (n?.title ?? '').trim();
        await HomeWidget.saveWidgetData<String>(
          'note_title_${i + 1}',
          title.isEmpty ? '—' : title,
        );
        await HomeWidget.saveWidgetData<String>(
          'note_snip_${i + 1}',
          _snippet(n?.content),
        );
      }

      await HomeWidget.updateWidget(
        androidName: 'NoteWidgetProvider',
      );
    } catch (e) {
      debugPrint('Note widget update error: $e');
    }
  }

  static String _snippet(String? content) {
    if (content == null) return '';
    // İlk boş olmayan satır, tek satıra indirgenmiş, en fazla 60 karakter.
    var firstLine = content
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');
    // Uygulamadaki kart önizlemesiyle tutarlı olsun diye liste/markdown
    // işaretçilerini temizle (☐ ☑ •, ** __ * _).
    if (firstLine.startsWith('☐ ') || firstLine.startsWith('☑ ')) {
      firstLine = firstLine.substring(2);
    }
    if (firstLine.startsWith('• ')) firstLine = firstLine.substring(2);
    // Yalnızca eşleşen (çift) işaretçileri soy; sarılan metni koru.
    firstLine = firstLine.replaceAllMapped(
        RegExp(r'(\*\*|__|\*|_)(.+?)\1'), (m) => m.group(2) ?? '');
    final flat = firstLine.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length > 60 ? '${flat.substring(0, 60)}…' : flat;
  }
}
