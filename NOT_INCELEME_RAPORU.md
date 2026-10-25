# 📝 Notlar Modülü İnceleme & Rakip Analizi Raporu

_LifeSync (com.aedev.kisisel) — Notlar (Notlarım) bölümü_
_Hazırlanma: 2026-10-24_

---

## 1. Özet

Notlar modülü aslında **beklenenden zengin**: metin + Markdown + checklist + çizim/el yazısı tuvali + renk + klasör + kilit + paylaşım hepsi mevcut. Ancak birkaç özellik **yarım kalmış veya hiç çalışmıyor** — kullanıcı arayüzde görüyor ama arkada bağlı değil. Önceliğimiz önce **bozuk olanı tamir etmek**, sonra rakip eşiğini yakalamak (etiket, çalışan hatırlatıcı, ek senkronu, widget), en son modern/AI katmanı olmalı.

**En kritik 3 bulgu:**
1. 🔴 **Not hatırlatıcıları bildirim üretmiyor** — tarih kaydediliyor ama gönderen zamanlanmış görev yok.
2. 🔴 **Ses kaydı ve dosya ekleri kayboluyor** — editörde toplanıyor, kaydederken atılıyor.
3. 🟠 **Görseller yalnız cihazda** — backend'de hazır ek altyapısı kullanılmıyor, cihaz değişince kaybolur.

---

## 2. Bizde VAR olan özellikler

| Kategori | Özellik | Durum |
|---|---|---|
| **İçerik** | Başlık + metin | ✅ |
| | Markdown (parser mevcut) | ✅ |
| | Checklist (☐/☑ — karttan hızlı işaretleme) | ✅ iyi |
| | Madde imi (bullet) | ✅ |
| | Renk kodlama | ✅ |
| | Çizim / el yazısı tuvali (PNG olarak eklenir) | ✅ |
| **Organizasyon** | Klasör / kategori (ikon + renk, CRUD) | ✅ |
| | Sabitleme (pin) | ✅ |
| | Arşivleme | ✅ |
| | Filtreler (kategori, pin, kilit, arşiv) | ✅ |
| | Arama (başlık + içerik) | ✅ basit |
| | Grid / liste görünümü | ✅ |
| **Güvenlik** | PIN kilidi (sunucu doğrulamalı) | ✅ |
| **Ekler** | Görsel ekleme | ⚠️ yalnız yerel |
| | Ses kaydı | ❌ kaydedilmiyor |
| | Dosya ekleme | ❌ kaydedilmiyor |
| **Diğer** | Hatırlatıcı tarihi seçme | ⚠️ bildirim gitmiyor |
| | Paylaş (metin) + panoya kopyala | ✅ |
| | Kelime / karakter sayısı | ✅ |
| | Premium not limiti + paywall | ✅ |

---

## 3. Tespit edilen sorunlar / tutarsızlıklar

### 🔴 1. Not hatırlatıcıları fiilen çalışmıyor
- `reminder_date` + `reminder_enabled` saklanıyor, `Note` modelinde "hatırlatılacaklar" scope'u bile var.
- **Ama** sunucuda yalnızca `SendTaskReminders`, `SendHabitReminders`, `SendSubscriptionReminders`, `SendCalendarEventReminders` komutları mevcut — **`SendNoteReminders` yok**. İstemci tarafında da zamanlanmış yerel bildirim görünmüyor.
- Sonuç: Kullanıcı hatırlatıcı kuruyor, hiçbir zaman bildirim almıyor.

### 🔴 2. Ses kaydı ve dosya ekleri kaydedilmiyor
- Editör ses kaydı (`_voiceNotePath`) ve dosya (`_pickedFiles`) topluyor.
- `createNote`/`updateNote` yalnız **görselleri** bağlıyor (`_attachImagesToNote`); ses ve dosya hiçbir yere yazılmadan `resetNoteForm` ile siliniyor.
- Backend'de **polimorfik `attachments` tablosu + `Note.attachments()` ilişkisi HAZIR** ama hiç kullanılmıyor.
- Sonuç: Kullanıcı sesli not / dosya ekliyor, kaydedince yok oluyor.

### 🟠 3. Görseller cihazlar arası senkronlanmıyor
- Görseller cihaz klasörüne kopyalanıp `SharedPreferences`'ta not id'siyle eşleniyor (kodun kendi notu: "cihazlar arası senkron olmaz").
- Yeniden kurulumda / başka cihazda kaybolur. Oysa backend ek altyapısı var (bkz. #2).

### 🟡 4. Kullanılmayan alanlar
- `version` alanı var ama **sürüm geçmişi** arayüzü/akışı yok.
- `order_index` var ama **sürükle-bırak sıralama** yok (sıralama sabit: pin → tarih).

---

## 4. Rakip karşılaştırması

| Özellik | **Biz** | Google Keep | Apple Notes | Notion | Evernote |
|---|---|---|---|---|---|
| Hızlı not + checklist | ✅ | ✅ | ✅ | ✅ | ✅ |
| Renk / etiket | 🎨 renk | 🎨 renk+etiket | 🏷️ etiket+klasör | 🏷️ | 🏷️ |
| Klasör / kategori | ✅ | ❌ (etiket) | ✅ | ✅ | ✅ |
| Hatırlatıcı | ⚠️ bozuk | ✅ (zaman+konum) | ❌ | ✅ | ✅ |
| Görsel/çizim/el yazısı | ✅ | ✅ | ✅ (Pencil) | ✅ | ✅ |
| Ses kaydı | ❌ (yarım) | ✅ | ✅ | ❌ | ✅ |
| Dosya eki | ❌ (yarım) | ❌ | ✅ | ✅ | ✅ |
| Cihazlar arası senkron | ⚠️ metin evet, ek hayır | ✅ | ✅ | ✅ | ✅ |
| Kilit / gizlilik | ✅ PIN | ❌ | ✅ | ❌ | ❌ |
| Paylaşım (dışa) | ✅ metin | ✅ | ✅ | ✅ | ✅ |
| Paylaş sayfasından içe aktarma | ❌ | ✅ | ✅ | ✅ | ✅ (Web Clipper) |
| İşbirliği / paylaşımlı not | ❌ | ✅ | ✅ | ✅ | ✅ |
| Ana ekran widget | ❌ | ✅ | ✅ | ✅ | ✅ |
| Zengin metin araç çubuğu | ⚠️ Markdown | ❌ | ✅ | ✅ | ✅ |
| Sürüm geçmişi | ❌ (alan var) | ❌ | ❌ | ✅ | ✅ |
| AI (özet/transkripsiyon/akıllı arama) | ❌ | kısmi | kısmi | ✅ | ✅ |

**Konum:** Keep'in sadeliğiyle Apple Notes'un gizlilik/ek zenginliği arasında bir yerdeyiz. Kilit (PIN) ve çizim/el yazısı bizde var ve iyi; eksiğimiz **etiket, çalışan hatırlatıcı, ek senkronu, widget ve paylaş-ile-içe-aktarma**.

---

## 5. Bizde OLMAYAN / eksik özellikler

### Yüksek değer (rekabet eşiği)
- **Etiketler (tags)** — yalnız klasör var; modern organizasyon folder **+** tag ister.
- **Çalışan hatırlatıcı bildirimi** — (var ama bozuk → düzeltilecek).
- **Ek senkronu** — görsel/ses/dosya backend'e (altyapı hazır).
- **Ana ekran widget** — hızlı not / checklist (finans widget'ını yaptık, aynı `home_widget` ile olur).
- **Paylaş sayfasından içe aktarma** — başka uygulamadan "Paylaş → LifeSync'e not" (Android share intent / iOS share extension).
- **Zengin metin araç çubuğu** — kalın/italik/başlık/liste düğmeleri (Markdown altyapısı zaten var).

### Orta
- **AI katmanı** — not özetleme, **sesli notu metne çevirme (transcribe)**, doğal dilli akıllı arama (2026'nın en güçlü trendi).
- **Sürüm geçmişi** — `version` alanı zaten var, üstüne inşa edilebilir.
- **Sürükle-bırak sıralama** — `order_index` zaten var.
- **Konum tabanlı hatırlatıcı** — "markete girince hatırlat" (Keep'in sevilen özelliği).
- **Paylaşımlı / işbirlikli not** — uygulamada `SharedBudget` / `SharedHabit` altyapısı var, nota genişletilebilir.
- **Not içinde tablo.**

### Düşük
- El yazısı tanıma (OCR), çizimi metne çevirme.
- Web clipper (tarayıcıdan kırpma).

---

## 6. Gereksiz / tartışmalı

- **Ses + dosya + çizim üçü birden** küçük bir kişisel uygulamada bakım yüküdür. Karar: madem UI'da duruyorlar, ya **çalışır** hale getirilmeli (önerilen) ya da **kaldırılmalı** — şu anki "görünüyor ama kaydolmuyor" durumu en kötüsü.
- **`version` alanı** kullanılmıyorsa ya sürüm geçmişine dönüştürülmeli ya temizlenmeli.
- Not + Günlük (diary) aynı modülde birleşik; bu bir sorun değil ama ileride ayrı sekme netliği düşünülebilir.

---

## 7. En çok kullanılan özellikler (ve bizim durumumuz)

| En çok kullanılan | Biz |
|---|---|
| Hızlı yakalama + checklist | ✅ iyi |
| Hatırlatıcı | ⚠️ bozuk → **1. öncelik** |
| Organizasyon (folder + **tag**) | ⚠️ folder var, tag yok |
| Arama | ✅ basit (AI/akıllı arama yok) |
| Senkron | ⚠️ metin evet, **ekler hayır** |
| Paylaşım | ✅ metin |
| Görsel / el yazısı | ✅ (ama görsel senkronsuz) |

---

## 8. Önerilen yol haritası (3 faz)

### Faz 1 — Bozukları tamir et (en yüksek öncelik)
> Kullanıcı özelliği görüp çalışmadığını fark ediyor; güven kaybı burada.
1. **Not hatırlatıcı bildirimi:** `SendNoteReminders` komutu + scheduler (mevcut `FirebaseNotificationService` ile, abonelik/görev hatırlatıcılarıyla aynı desen).
2. **Ekleri gerçekten kaydet:** ses + dosya + görseli backend `attachments` tablosuna bağla (altyapı hazır) → otomatik cihazlar arası senkron.

### Faz 2 — Rekabet eşiği
3. **Etiketler (tags)** — klasörle birlikte.
4. **Ana ekran not widget'ı** — hızlı not / checklist.
5. **Paylaş sayfasından içe aktarma** — share intent → yeni not.
6. **Zengin metin araç çubuğu** — kalın/italik/başlık/liste.

### Faz 3 — Modern / AI
7. **AI:** not özeti + sesli notu metne çevir + akıllı arama.
8. **Sürüm geçmişi** (`version`) + **sürükle-bırak sıralama** (`order_index`).
9. **Konum tabanlı hatırlatıcı** + **paylaşımlı not** (işbirliği).

---

## Kaynaklar
- [Zapier — Best note-taking apps](https://zapier.com/blog/best-note-taking-apps/)
- [ClickUp — Best note-taking apps](https://clickup.com/blog/note-taking-apps/)
- [Atlas — Google Keep alternatives](https://www.atlasworkspace.ai/blog/google-keep-alternatives)
- [emelia.io — Note taking apps hub](https://emelia.io/hub/note-taking-apps)
- [ClickUp — AI that listens and takes notes](https://clickup.com/blog/ai-that-listens-and-takes-notes)
- [Kripesh Adwani — Best AI note-taking apps](https://kripeshadwani.com/best-ai-note-taking-apps/)
