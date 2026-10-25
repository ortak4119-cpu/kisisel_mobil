import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../core/init/locator.dart';
import '../../models/note/note_models.dart';
import '../widget/note_widget_service.dart';

/// Başka uygulamadan "Paylaş" ile gelen düz metni yeni bir nota dönüştürür.
/// Hem soğuk başlangıçta (uygulama paylaşımla açıldığında) hem de uygulama
/// açıkken gelen paylaşımları dinler.
class ShareIntentHandler {
  /// SnackBar göstermek için global anahtar (main.dart'ta MaterialApp'e verilir).
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static StreamSubscription<List<SharedMediaFile>>? _sub;

  static void init() {
    try {
      // Uygulama açıkken gelen paylaşımlar
      _sub = ReceiveSharingIntent.instance.getMediaStream().listen(
        _handle,
        onError: (e) => debugPrint('Share stream error: $e'),
      );

      // Uygulama paylaşımla açıldıysa (soğuk başlangıç)
      ReceiveSharingIntent.instance.getInitialMedia().then((files) {
        _handle(files);
        ReceiveSharingIntent.instance.reset();
      });
    } catch (e) {
      debugPrint('ShareIntentHandler init error: $e');
    }
  }

  static void dispose() {
    _sub?.cancel();
  }

  static Future<void> _handle(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;

    final text = files
        .where((f) =>
            f.type == SharedMediaType.text || f.type == SharedMediaType.url)
        .map((f) => f.path)
        .where((t) => t.trim().isNotEmpty)
        .join('\n')
        .trim();

    if (text.isEmpty) return;
    await _createNote(text);
  }

  static Future<void> _createNote(String text) async {
    try {
      final firstLine = text
          .split('\n')
          .map((l) => l.trim())
          .firstWhere((l) => l.isNotEmpty, orElse: () => '');
      var title = firstLine.isEmpty ? 'notes.newNote'.tr() : firstLine;
      if (title.length > 60) title = '${title.substring(0, 60)}…';

      final resp = await noteService.createNote(NoteRequest(
        title: title,
        content: text,
        isLocked: false,
        isPinned: false,
      ));

      if (resp.isSuccess) {
        await NoteWidgetService.update();
        _toast('success.noteAdded'.tr());
      }
    } catch (e) {
      debugPrint('Share -> note create error: $e');
    }
  }

  static void _toast(String message) {
    final messenger = messengerKey.currentState;
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
