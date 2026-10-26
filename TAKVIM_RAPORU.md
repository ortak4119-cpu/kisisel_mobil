# 📅 Takvim Modülü — İnceleme Raporu

> LifeSync (com.aedev.kisisel) — Takvim (Takvim) modülü. Finans / Notlar / Görevler-Alışkanlıklar raporlarıyla aynı desende: rakip analizi + mevcut envanter + tutarsızlıklar + eklenebilir/çıkarılabilir + fazlı yol haritası.
> Tarih: 2026-10-25. Kod tabanı: istemci `C:\PYTHON-PROJELER\kisisel_mobil\kisisel_mobil`. Backend sadece sunucuda (yerelde PHP yok — bulgular istemci çağrılarından geri-türetildi).

---

## 1. Yönetici özeti

Takvim modülü **görsel olarak zengin ama veri katmanı çok zayıf**. Form kullanıcıya renk, kategori, hatırlatıcı, konum, tekrar, bitiş saati, tüm-gün gibi 9 alan sunuyor — ama bunların **hiçbiri backend'e gitmiyor.** Hepsi cihazda `SharedPreferences` (`event_meta_v1`) içinde tutuluyor. Sonuç:

- 🔴 **Uygulama silinince / yeni cihazda / önbellek temizlenince renk, kategori, hatırlatıcı, konum, tekrar, bitiş saati, tüm-gün bilgilerinin TAMAMI kalıcı olarak kayboluyor.** Sadece başlık/açıklama/tarih/saat sunucuda yaşadığı için kurtuluyor.
- 🔴 **Hatırlatıcılar hiç bildirim göndermiyor** — sadece görsel bir "zil" rozeti ve "Yaklaşan hatırlatıcılar" listesi. `flutter_local_notifications` pakedi ekli ama etkinlik için zamanlama yapan tek satır kod yok. (Görevlerdeki "X dk önce hatırlat çalışmıyordu" bug'ının aynısı.)
- 🔴 **Tekrarlayan etkinlikler kozmetik** — "Haftalık" seçilse bile etkinlik tek bir tarihte görünüyor, hiç tekrarlamıyor.

Bu, finans (`color` null 500), notlar (`task_meta` yerel-only) ve görevlerdeki (meta yerel-only + reminder_before çalışmıyor) **tam olarak aynı kalıbın** takvimdeki tekrarı: backend yoksayıyor → UI yerel saklıyor → veri uçuyor.

Ayrıca ciddi miktarda **ölü kod** var (kullanılmayan `table_calendar` paketi, 3 ölü servis metodu, ölü enum, yetim ay-nokta sistemi, eski çeviri anahtarları).

---

## 2. Rakip analizi — kullanıcılar en çok ne istiyor?

Araştırmada öne çıkan, kişisel takvim uygulamalarında kullanıcıların en çok değer verdiği özellikler:

| Özellik | Kimde öne çıkıyor | Bizde durum |
|---|---|---|
| **Doğal dil ile etkinlik girişi** ("yarın 14:00 dişçi") | Fantastical (en çok övülen özelliği), Calendars by Readdle | ❌ Yok — **ama görevlerde `NlTaskParser` olarak ZATEN yazdık, yeniden kullanılabilir** |
| **Tekrarlayan etkinlikler (RRULE)** | Tüm ciddi takvimler standart sayıyor | 🟡 Sadece kozmetik |
| **Çalışan hatırlatıcılar, çoklu önceden-uyarı** | AnySchedule (4 öncelik + birden çok uyarı), Agenda ("zamanında varış" uyarısı) | 🔴 Hiç bildirim atmıyor |
| **Ajanda / zaman-çizelgesi (timeline) görünümü** | AnySchedule (çakışan etkinlikler görünür), Structured (günü tek görsel) | 🟡 Ajanda sekmesi var ama restart'ta aya dönüyor |
| **Zaman bloklama (time blocking)** | Notion Calendar (sürükle-bırak), Motion/Reclaim (otomatik) | ❌ Yok |
| **GitHub tarzı ısı haritası / tutarlılık** | AnySchedule heatmap | 🟡 Alışkanlıklarda var, takvimde yok |
| **Hava durumu widget'ı** | Fantastical (AccuWeather 5 günlük) | ❌ Yok |
| **Ana ekran / kilit ekranı widget'ı** | AnySchedule (Live Activity), Fantastical | 🟡 Görev/not widget altyapısı var, takvime uyarlanabilir |
| **Sesli giriş** | Agenda (sesle to-do), AnySchedule | ❌ Yok — **ama notlarda STT (`stt_service`) ZATEN var** |
| **Harici takvim senkronu (Google/Apple/Outlook)** | Structured, Agenda, Calendars — hepsi | ❌ Yok (ağır iş) |
| **Modüller arası birleşik gün görünümü** | Tüm "all-in-one" planlayıcılar | 🟢 **Bizim güçlü yanımız** — görev/not/günlük/harcama/abonelik/taksit gün kartında birleşiyor |

**Çıkarım:** En büyük açıklarımız (doğal dil, hatırlatıcı, sesli giriş) için **altyapı zaten başka modüllerde mevcut** — tekrar yazmaya gerek yok, uyarlamak yeter. Birleşik gün görünümü ise rakiplerin çoğunda olmayan bir güçlü yanımız; onu öne çıkarmalıyız.

**Kaynaklar:** [ClickUp — Google Calendar alternatives](https://clickup.com/blog/google-calendar-alternatives/) · [Jotform — Top 5 alternatives](https://www.jotform.com/blog/google-calendar-alternatives/) · [efficient.app — Fantastical review](https://efficient.app/apps/fantastical) · [usecarly — Notion Calendar alternatives](https://www.usecarly.com/blog/notion-calendar-alternatives/) · [toolradar — best calendar apps guide](https://toolradar.com/guides/best-calendar-apps) · [AnySchedule (App Store)](https://apps.apple.com/us/app/-/id6759487521) · [Agenda: Planner, Notes & Tasks](https://apps.apple.com/app/id1135683789)

---

## 3. Mevcut envanter — bizde ne var?

**Dosyalar (4):**
- `lib/models/calender/calendar_models.dart` — `CalendarEvent`, `CalendarEventRequest`, `CalendarEventUpdateRequest`, `MonthViewResponse`, `DayViewResponse`, enum `CalendarEventType`.
- `lib/service/calender/calendar_service.dart` — `ICalendarService` + `CalendarService`.
- `lib/presentation/calender/viewmodel/calender_viewmodel.dart` — `CalendarViewModel` + yerel `EventMeta` + `CalendarViewType` enum.
- `lib/presentation/calender/view/calender_view.dart` (~2025 satır) — `CalendarView` + `_EventFormSheet`.

**Görünümler (4):** Ay / Hafta / Gün / Ajanda sekmeleri. Ek olarak arama modu + "Yaklaşan hatırlatıcılar" alt sayfası (zil ikonu).

**Takvim ızgarası:** Tamamen **elle çizilmiş** (`GridView.count(crossAxisCount: 7)`). `table_calendar` paketi ekli ve import ediliyor ama **hiç kullanılmıyor.**

**Etkinlik CRUD:** Oluştur / düzenle / sil — hepsi UI'dan çalışıyor.

**Backend'e GİDEN alanlar:** `title`, `description`, `event_type`, `event_date`, `event_time` (+ opsiyonel `reference_id`/`reference_type`).

**Form topluyor ama backend'e GİTMEYEN alanlar:** `kind`, `category`, `color`, `endTime`, `allDay`, `reminders`, `location`, `recurrence`, `tag` → hepsi yerel `EventMeta`.

**Modül entegrasyonu (okuma, güçlü yan):** Görev (dueDate), Not (kilitli/açık + PIN ile aç), Günlük, Harcama, Abonelik (billingDate), Taksit (hesaplanan vade) — gün kartında birleşiyor.

**CalendarEvent alanları:** `id, user_id, title, description?, event_type, event_date, event_time?, reference_id?, reference_type?`.

**Backend uçları (geri-türetilmiş):** `GET /calendar/events` (list), `GET/POST /calendar/events`, `PUT/DELETE /calendar/events/{id}`, `GET /calendar/month/{y}/{m}`, `GET /calendar/day/{date}`. (Son ikisi + tekil GET istemciden **hiç çağrılmıyor.**)

---

## 4. Tutarsızlıklar & ölü kod (EN ÖNEMLİ bölüm)

### 🔴 Kritik (veri kaybı / çalışmayan özellik)
1. **`EventMeta` tamamen cihaz-yerel** (`event_meta_v1`), backend event id ile anahtarlanıyor. 9 alan sunucuya hiç gitmiyor → **silme/yeni cihaz/önbellek temizliği = renk+kategori+hatırlatıcı+konum+tekrar+bitiş+tüm-gün kaybı.** Başka cihazda oluşturulan etkinliğin meta'sı hiç yok, varsayılana düşüyor.
2. **Hatırlatıcılar hiç bildirim atmıyor** — sadece görsel. Zamanlama (`zonedSchedule`) yok. Backend'e de gitmiyor.
3. **Tekrar kozmetik** — yerel chip olarak duruyor, etkinlik asla tekrarlamıyor. RRULE / genişletme yok.
4. **`event_type` kayda girerken çöküyor:** `_formKind == 'reminder' ? 'reminder' : 'custom'`. 4 UI türü (toplantı/hatırlatıcı/doğum günü/odak) backend'de sadece `reminder`/`custom` olarak kalıyor; ayrım yalnız yerel meta'da.

### 🟡 Orta
5. **Bitiş tarih/saati büyük ölçüde kozmetik** — sadece başlangıç (`event_date`/`event_time`) gönderiliyor. `endTime` yerel meta'ya, **`formEndDate` hiçbir yere** yazılmıyor → çok-günlü etkinlik sunucuda imkânsız.
6. **Tüm-gün bayrağı yerel-only** — kayıtta sadece `event_time`'ı null yapıyor; backend tüm-gün ile saatsiz etkinliği ayırt edemiyor.
7. **İki paralel ay-nokta sistemi, biri yetim:** `getEventsForMonth()` (not/günlük/görev/harcama dahil) **kullanılmıyor**; görünüm `eventCategoryDots()` kullanıyor (sadece takvim-etkinliği + abonelik + taksit). → **Görev/günlük/not ay ızgarasında nokta olarak GÖRÜNMÜYOR** (hesaplayan kod var ama bağlı değil).
8. **Sabit kodlanmış GMT+3** `CalendarEvent.fromJson` içinde — ISO tarihe cihaz saat diliminden bağımsız +3s ekliyor; TR dışı kullanıcıda tarih kayar.
9. **Görünüm-tipi kalıcılığı kayıplı** — gün/ajanda seçimi restart'ta sessizce aya dönüyor (yalnız hafta/ay saklanıyor).

### ⚪ Temizlik (çıkarılabilir ölü kod)
10. `table_calendar` paketi + import → **kullanılmıyor**, kaldırılabilir.
11. Ölü servis metodları: `getEvent`, `getMonthView`, `getDayView` + modeller `MonthViewResponse`/`DayViewResponse` → hiç çağrılmıyor.
12. Ölü viewmodel metodu: `createCalendarEvent` (form doğrudan servisi çağırıyor). `getEventsForMonth`, `hasEvents`, `hasLockedNotesOnDate`, `getNotesCountForSelectedDate`, `getCalendarEventsByType` → yetim.
13. Ölü enum `CalendarEventType` — hiç referans yok (event_type ham string geçiliyor).
14. Kullanılmayan asset `assets/images/empty_calendar.svg` (boş-gün ikon kullanıyor).
15. ~15 eski/kullanılmayan `calendar.*` çeviri anahtarı (weeklyView, eventDetail, deleteConfirm, paymentDay, enterPin, untitledNote, diaryTitle, notesTitle, ...).

---

## 5. Neler eklenebilir / çıkarılabilir

**Eklenebilir (değer sırasına göre):**
- ✅ Meta'yı backend'e taşı (renk/kategori/hatırlatıcı/konum/tekrar/bitiş/tüm-gün) — **veri kaybını bitirir, her şeyin önkoşulu.**
- ✅ Çalışan yerel bildirimler (çoklu önceden-uyarı) — `flutter_local_notifications` zaten ekli.
- ✅ Gerçek tekrarlayan etkinlikler (RRULE veya basit günlük/haftalık/aylık genişletme).
- ✅ Doğal dil girişi — `NlTaskParser`'ı takvime uyarla (zaten var).
- ✅ Ay ızgarasında görev/günlük/not noktalarını göster (`getEventsForMonth` zaten hesaplıyor, sadece bağla).
- ✅ Sesli etkinlik girişi — notların `stt_service`'i yeniden kullan.
- 🔸 Çok-günlü etkinlik + doğru tüm-gün.
- 🔸 Ana ekran "bugünün ajandası" widget'ı (görev/not widget altyapısından).
- 🔹 (Büyük/opsiyonel) Harici takvim senkronu, hava durumu, zaman bloklama.

**Çıkarılabilir:** `table_calendar` paketi/importu, ölü servis/viewmodel metodları, ölü `CalendarEventType` enum, kullanılmayan SVG, ~15 eski çeviri anahtarı, GMT+3 sabit kodu (cihaz saat dilimiyle değiştir).

---

## 6. Önerilen fazlı yol haritası

**Faz 1 — Veri bütünlüğü (kritik, backend gerektirir):** `calendar_events` tablosuna `color/category/kind/end_date/end_time/all_day/location/recurrence_rule/tag/reminder_minutes(json)` kolonları + migration; Controller fillable/validation; istemci Request/Model bu alanları gönderir; `EventMeta` yerelden backend'e göç (tek seferlik, görevlerdeki `migrateLocalTaskMetaOnce` deseni). GMT+3 sabitini kaldır. → **Veri kaybı biter.**

**Faz 2 — Çalışan hatırlatıcılar + tekrar:** Etkinlik için `flutter_local_notifications` zamanlaması (çoklu önceden-uyarı); tekrarlayan etkinlik genişletme (günlük/haftalık/aylık/yıllık); tüm-gün ve çok-günlü doğru render.

**Faz 3 — Hız & akıl (altyapı yeniden kullanımı):** Doğal dil girişi (`NlTaskParser`), sesli giriş (`stt_service`), ay ızgarasında modül noktaları (görev/günlük/not), ajanda görünüm kalıcılığı, ana ekran "bugün" widget'ı.

**Faz 0 — Temizlik (düşük risk, istenirse önce):** ölü kod/paket/çeviri/asset silme.

---

> **Not:** Önceki modüllerde olduğu gibi önce bir fazı onayınla uygulayıp emülatörde doğrularım, push etmem (senin "güncellemeler bitince ben pushlarım" kuralın geçerli). Hangi fazdan başlayalım? Önerim: **Faz 1 (veri bütünlüğü)** — çünkü diğer tüm özellikler verinin sunucuda yaşamasına bağlı.
