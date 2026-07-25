# Markdown Biçimlendirme Düzeltme Planı (Revize)

Kullanıcı, yaptığımız değişikliğin ardından hala kalın ve italik metinlerin çalışmadığını belirtti. Yapılan detaylı incelemede, önceki Regex mantığının bazı durumlarda eşleşme sağlayamadığı veya hatalı eşleştiği (örneğin `**` işaretini `*` olarak algılamak gibi) düşünülmektedir.

## Kullanıcı İncelemesi Gerekenler

> [!NOTE]
> Bu düzeltme ile Markdown ayrıştırıcı mantığı daha sağlam (robust) bir hale getirilecek ve Flutter'ın standart `Text.rich` bileşeni kullanılarak tema uyumluluğu artırılacaktır.

## Önerilen Değişiklikler

### [Markdown Ayrıştırıcı Bileşeni]

#### [MODIFY] [markdown_note_parser.dart](file:///C:/PYTHON-PROJELER/kisisel_mobil/kisisel_mobil/lib/presentation/notes_diary/view/markdown_note_parser.dart)
*   **Regex Güncellemesi:** Backreference (`\1`) kullanılarak işaretçilerin (`**`, `__`, `*`, `_`) kendi eşleriyle tam olarak eşleşmesi sağlanacak: `r'(\*\*|__|\*|_)(.+?)\1'`.
*   **Mantık Düzenlemesi:** İşaretçiler daha net bir şekilde ayrıştırılacak. `**` ve `__` kalın, `*` italik, `_` altı çizili olarak işlenecek.
*   **Widget Değişikliği:** `RichText` yerine, Flutter temasıyla daha iyi entegre olan ve miras alınan stilleri (inheritance) daha güvenli yöneten `Text.rich` kullanılacak.
*   **Stil Uygulama:** `FontWeight.bold` ve `FontStyle.italic` gibi Flutter'ın standart sabitleri kullanılarak okunurluk ve güvenilirlik artırılacak.

## Doğrulama Planı

### Manuel Doğrulama
*   Aşağıdaki metin örnekleri hem Notlarda hem Günlükte test edilecek:
    *   `**Kalın Metin**` -> Kalın görünmeli.
    *   `*İtalik Metin*` -> İtalik görünmeli.
    *   `_Altı Çizili_` -> Altı çizili görünmeli.
    *   `Normal **Kalın** Normal` -> Karışık kullanımın doğruluğu kontrol edilecek.
