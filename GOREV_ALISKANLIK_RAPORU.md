# Görevler & Alışkanlıklar İnceleme Raporu

> LifeSync `tasks_habits` modülü. Finans/Notlar incelemeleriyle aynı yöntem: rakip analizi → bizde olan/olmayan → tutarsızlıklar → fazlı yol haritası. **Önce Görevler, sonra Alışkanlıklar.**

Modül: `lib/presentation/tasks_habits/` (görev + alışkanlık tek ekran). Backend: `TaskController`, `HabitController`, `SharedHabitController` + `Task`/`Habit`/`HabitLog` modelleri.

---

## BÖLÜM 1 — GÖREVLER (önce bunu yapıyoruz)

### 1.1 Rakiplerde en çok kullanılan özellikler
Kaynaklar: Todoist, TickTick, Microsoft To Do, Google Tasks, Any.do karşılaştırmaları.
- **Doğal dil girişi** — "yarın 15:00 fatura öde !!1" yazınca tarih/saat/öncelik otomatik ayrışır. Todoist'in en çok övülen özelliği; kullanıcıların #1 tercih sebebi.
- **Çoklu görünüm** — Liste / Pano (Kanban) / Takvim. Todoist & TickTick'te standart.
- **Alt görevler + ilerleme** — ana görevde "2/5 tamamlandı" sayacı.
- **Öncelikler** — 3–4 seviye (bizde 0/1/2 var).
- **Yinelenen görevler** — "her Pazartesi", "her ayın 1'i".
- **Güvenilir hatırlatıcılar** — mutlak saat + "X dk önce"; en sık şikâyet: bildirim gelmemesi.
- **Pomodoro / odak sayacı** (TickTick), **Eisenhower matrisi** (TickTick).
- **Hızlı ekleme + ana ekran widget'ı**.

### 1.2 Bizde ne VAR (envanter)
Backend/model oldukça zengin:
- ✅ Başlık, açıklama, tür (`task_type`), bitiş tarihi+saati, öncelik (0/1/2).
- ✅ **Alt görevler** (`parent_task_id`) — backend'e gerçek görev olarak kaydediliyor, senkron. (İlerleme sayacı yok.)
- ✅ **Yinelenen görevler** — `is_recurring` + `recurring_pattern` + `last_reset_at`; görev çekildiğinde tembel sıfırlama (`resetRecurringTasks`, TaskController'da). Çalışıyor.
- ✅ Tamamla / geri al / arşivle; günlük / haftalık / gecikmiş / tamamlanan listeleri (ayrı endpoint'ler).
- ✅ Hatırlatıcı push **dile çevriliyor** (`notifications.task_reminder_title`, kullanıcı diline göre).
- ✅ Filtre (tür/öncelik/durum) + sıralama parametreleri.

### 1.3 🔴 TUTARSIZLIKLAR (bulgular)
1. **🔴 KRİTİK — Kategori / etiket / konum / bağlantı / ekler SADECE YERELDE.**
   Kullanıcı bu alanları editörde giriyor ve görüyor, ama backend tasks tablosunda bu kolonlar **yok**. Hepsi cihazda `SharedPreferences` (`task_meta_v1`) + yerel dosya olarak tutuluyor (`_saveTaskMeta`/`loadTaskMeta`/`_copyTaskFilesToDir`).
   → **Sonuç:** cihaz değişince / uygulama silinince bu veriler kaybolur, cihazlar arası senkron yok. (Notlardaki ek sorununun aynısı — Faz 1'de çözmüştük.)

2. **🔴 KRİTİK — "X dakika önce hatırlat" HİÇ çalışmıyor.**
   Arayüz "15 / 30 / 60 dk önce" seçeneği sunuyor (`setReminderBeforeMinutes`). İstemci bu durumda `reminder_time`'ı null, `reminder_before_minutes`'ı dolu gönderiyor. Ama `SendTaskReminders` **yalnız mutlak `reminder_time`'ı** şimdiki dakikayla eşleştiriyor; `reminder_before_minutes`'ı hiç kullanmıyor (bitiş tarihinden geri sayım yok).
   → **Sonuç:** "X dk önce" seçen kullanıcıya bildirim **hiç gitmez**.

3. **🟡 ORTA — Süre tahmini/gerçekleşen kullanılmıyor.**
   `estimated_duration_minutes` / `actual_duration_minutes` backend+modelde var; `createTask` bunu sabit `null` gönderiyor, arayüzde giriş yok. Ölü kapasite.

4. **🟡 DÜŞÜK — Tek seferlik görev hatırlatıcısı her gün tekrarlayabilir.**
   `SendTaskReminders` tamamlanmamış + `reminder_time`'ı eşleşen her görevi tetikler; bitiş tarihi geçmiş olsa da tamamlanana kadar her gün aynı saatte nag eder (tarih guard'ı yok, `reminder_sent_at` benzeri idempotent bayrak yok).

### 1.4 Görevler — önerilen yol haritası (fazlı)
**Faz 1 — Tutarsızlıkları kapat (önce bunlar):**
- Meta'yı backend'e taşı: tasks tablosuna `category`, `tags` (json), `location`, `link` kolonları + görev eki endpoint'i (notlardaki `attachments` deseniyle). Yerel `task_meta_v1`'den tek seferlik göç.
- `SendTaskReminders`'a `reminder_before_minutes` desteği: `due_date`+`due_time` − X dk == şimdi ise gönder. İdempotentlik için `reminder_sent_at` kolonu.
- Tek seferlik görevlerde tarih guard'ı (geçmiş görev nag etmesin).

**Faz 2 — Yüksek değerli özellikler:**
- **Doğal dil girişi** (yerel, ücretsiz parser): "yarın 15:00 … !!1" → tarih/saat/öncelik.
- **Alt görev ilerleme sayacı** (ana kartta 2/5).
- **Sürükle-bırak sıralama** (notlardaki gibi `order_index`).

**Faz 3 — Görünüm/odak:**
- Takvim görünümü / Pano (Kanban), Pomodoro odak sayacı (süre alanlarını da buradan besler), ana ekran "Bugünkü görevler" widget'ı.

---

## BÖLÜM 2 — ALIŞKANLIKLAR (görevlerden sonra)

### 2.1 Rakiplerde en çok kullanılan özellikler
Kaynaklar: Streaks, Habitica, Habitify, HabitNow, Way of Life, TickTick.
- **Seri (streak) + geçmiş ısı haritası/takvim** — en çok motive eden öğe.
- **Esnek sıklık** — günde X, haftada X, belirli günler.
- **Günde birden çok hatırlatıcı**.
- **Atla / dinlenme günü** (seriyi bozmadan).
- **Oyunlaştırma** (Habitica), **Apple Health entegrasyonu** (Streaks).
- **Cue–Reward (Atomic Habits döngüsü)**: ipucu + ödül + "neden".
- **Günlük log'a not**.

### 2.2 Bizde ne VAR — ve 🔴 kullanılmayan güçlü backend
Model ÇOK zengin ama arayüz bunun küçük bir kısmını kullanıyor:
- ✅ **Seri** (current/longest), toplam tamamlama, zorluk seviyesi, belirli günler, tek hatırlatıcı — arayüzde var.
- ✅ Tamamla; en iyi seri kartta gösteriliyor; hatırlatıcı push dile çevriliyor.
- 🔴 **Cue / Reward / MotivationQuote (Atomic Habits döngüsü)** — model+backend'de VAR, `_buildHabitRequest` bunları **sabit null** gönderiyor. Hiç yüzeye çıkmamış.
- 🔴 **Alışkanlık paylaşımı** — `SharedHabitController` + 14 route backend'de HAZIR; arayüz `isPublic: false` sabitliyor. Tamamen kullanılmıyor.
- 🔴 **Günde çok hatırlatıcı** — model `reminder_times` (liste) destekliyor, backend eşleştiriyor; arayüz tek saat yolluyor.
- 🔴 **Sıklık türü** — model çeşitli (`target_frequency_type`); arayüz sabit `times_per_day`.
- 🔴 **Atla (skip) + sebep** — model+backend (`HabitLog.skipped/skip_reason`) var; arayüzde **skip hiç yok** (sadece tamamla).
- 🟡 **Geçmiş ısı haritası / completionRate / HabitStats** — `HabitStats` modeli, `completion_rate`, haftalık/aylık sayaçlar backend'de var; arayüzde takvim/ısı haritası görünmüyor (yalnız seri sayısı).
- 🟡 **Log notu** — `HabitLog.notes` var; arayüzde kullanılmıyor.

### 2.3 Alışkanlıklar — ön değerlendirme
Alışkanlık tarafında ana iş **yeni backend değil**, zaten var olan güçlü kapasiteyi **arayüze açmak**: cue/reward/neden, çoklu hatırlatıcı, skip+sebep, sıklık türleri, geçmiş ısı haritası (completionRate/log'lardan), ve (isteğe bağlı) hazır paylaşım altyapısını yüzeye çıkarmak. Detaylı fazlama görevler bitince netleştirilecek.

---

## Özet öncelik sırası
1. **Görev Faz 1** (tutarsızlıklar): yerel meta → backend senkron, "X dk önce" hatırlatıcı düzeltmesi, tek-seferlik nag guard'ı.
2. **Görev Faz 2**: doğal dil girişi, alt görev ilerleme, sürükle-bırak sıralama.
3. **Alışkanlık**: var olan zengin backend'i arayüze açmak (cue/reward, çoklu hatırlatıcı, skip, ısı haritası).
