import 'package:speech_to_text/speech_to_text.dart';

/// Cihaz-içi konuşma tanıma (dikte) sarmalayıcısı.
/// Mikrofona konuşulan metni canlı olarak döndürür; harici servis/gizli anahtar
/// gerektirmez (cihazın kendi konuşma tanıyıcısını kullanır).
class SttService {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;

  bool get isAvailable => _available;
  bool get isListening => _speech.isListening;

  Future<bool> init({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    _available = await _speech.initialize(
      onStatus: (s) => onStatus?.call(s),
      onError: (e) => onError?.call(e.errorMsg),
    );
    return _available;
  }

  /// Dinlemeyi başlatır. [onResult] her kısmi/son sonuçta çağrılır.
  Future<void> start({
    required String localeId,
    required void Function(String recognized, bool isFinal) onResult,
  }) async {
    await _speech.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        localeId: localeId,
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> stop() => _speech.stop();
  Future<void> cancel() => _speech.cancel();

  /// easy_localization dil kodunu cihaz STT locale id'sine çevirir.
  static String localeIdFor(String languageCode) {
    const map = {
      'tr': 'tr_TR',
      'en': 'en_US',
      'de': 'de_DE',
      'es': 'es_ES',
      'fr': 'fr_FR',
      'ar': 'ar_SA',
      'ru': 'ru_RU',
      'pt': 'pt_PT',
      'hi': 'hi_IN',
      'ja': 'ja_JP',
      'zh': 'zh_CN',
    };
    return map[languageCode] ?? 'en_US';
  }
}
