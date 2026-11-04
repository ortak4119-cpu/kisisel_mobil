# LifeSync — Otomatik Bildirim Yığını (Detaylı Rapor)

**Tarih:** 2026-11-03
**Kapsam:** "Dear Me / Kompanion" ve benzeri alışkanlık/günlük uygulamalarının bildirim stratejisini inceleyip, LifeSync için otomatik, çok dilli (11 dil), kişiselleştirilmiş bir bildirim yığını planı.
**Amaç:** Elde tutma (retention) ve günlük aktif kullanıcı (DAU) artışı — kullanıcıyı bunaltmadan, uygulamaya geri getiren düzenli, anlamlı bildirimler.

> Not: Bu bir **plan/karar raporudur**. Henüz hiçbir şey yazılmadı. Onay verince Faz 1'den başlanır.

---

## 1. Neden? (Hedef ve mantık)

Kişisel üretkenlik/alışkanlık uygulamalarında **kullanım sıklığı = yaşam süresi**. Kullanıcı ilk hafta içinde günlük bir alışkanlık edinmezse büyük oranda kaybedilir. Bildirimler bu alışkanlığı kurmanın en güçlü kaldıracıdır — ama yanlış kullanılırsa (çok sık, alakasız, hep aynı metin) kapatılır veya uygulama silinir.

**Ölçmek istediğimiz asıl metrikler:**
- **D1 / D7 / D30 retention** (kurulumdan 1/7/30 gün sonra hâlâ açanlar)
- **DAU / MAU oranı** (yapışkanlık)
- **Bildirim açılma oranı** (tıklanıp uygulamayı açma)
- **Opt-out oranı** (bildirimi/izni kapatanlar — fazla artarsa strateji yanlış demektir)

Hedef: bildirimlerin **retention'ı artırması**, opt-out'u düşük tutması. Bunu ancak gerçek verilerle ölçüp ayarlayabiliriz (bkz. Bölüm 8).

---

## 2. Rakip Analizi (ne yapıyorlar?)

İncelenen türler: **Dear Me / Kompanion** (günlük/journaling), ve benzerleri **Finch, Fabulous, Daylio, Reflectly, Duolingo, Streaks**.

| Uygulama | Bildirim deseni | Öne çıkan taktik |
|---|---|---|
| **Dear Me / Kompanion** | Günde 1–2 sıcak, kişisel/yansıtıcı mesaj ("Bugün nasıl hissediyorsun?") | Birinci tekil, samimi dil; sabit saat; "kendine not" tonu |
| **Finch** | Günlük self-care hatırlatması + evcil karakter "seni özledi" | Duygusal bağ (karakter), nazik dil, seri koruma |
| **Fabulous** | Sabah rutini tetikleyici, koçvari | Zamanlanmış rutin anları; motivasyon cümleleri |
| **Daylio** | Akşam "bugününü kaydet" tek bildirim | Minimal, tek net CTA, kişinin seçtiği saat |
| **Duolingo** | Streak koruma + suçluluk/mizah + re-engagement | Seri vurgusu, kişiselleştirilmiş saat, agresif ama ünlü mizah |
| **Streaks** | Sadece kullanıcının kurduğu hatırlatıcılar | Spam yok; güven = sadakat |

**Ortak çıkarımlar (bizim için kurallar):**
1. **Günde en fazla 1 "etkileşim" bildirimi** (hatırlatıcılar ayrı). Fazlası opt-out yapar.
2. **Kullanıcının yerel saatine göre** (sabah ~09:00 veya akşam ~20:00) — gece gönderme.
3. **Sıcak, birinci tekil, kişisel dil** ("Bugün bir şey yazmak ister misin?") — kurumsal değil.
4. **Metin rotasyonu** — aynı cümle tekrar etmesin (havuzdan dönüşümlü).
5. **Seri (streak) ve kilometre taşları** güçlü tetikleyici.
6. **Geri kazanım (dormant)** için ayrı, daha nazik bir ton.
7. **Her zaman kolay kapatma** (ayarlarda tür bazında aç/kapa) — güven.

---

## 3. Bildirim Taksonomisi (türler)

LifeSync modülleri: **Notlar, Görevler, Alışkanlıklar, Takvim, Finans, Profil/Sosyal**. Bildirimleri 7 türe ayırıyorum. (✅ = altyapı kısmen/tamamen var, 🆕 = yeni)

### A. Günlük Etkileşim ("Dear Me" tarzı) — 🆕 **ana yenilik**
Günde 1, kullanıcının yerel sabah/akşam saatinde. Modül-bağımsız, sıcak tetikleyici.
> *"Güne küçük bir notla başla ☕ — aklında ne var?"*
> *"Bugün için 3 görev belirle, akşam gülümseyerek bak 🌿"*

### B. Modül Hatırlatıcıları — ✅ (çoğu var)
Kullanıcının **kendi kurduğu** hatırlatıcılar:
- Not hatırlatıcısı (`SendNoteReminders` komutu — VAR)
- Görev son tarihi / hatırlatıcısı
- Alışkanlık günlük hatırlatıcısı (çoklu hatırlatıcı — VAR)
- Takvim etkinliği (`reminder_minutes` + tekrar — VAR)
- Finans: yaklaşan ödeme/abonelik/taksit hatırlatıcısı (🆕 — veri var, bildirim eklenebilir)

### C. Seri (Streak) Koruma — 🆕
Alışkanlık serisi riske girince nazik dürtme.
> *"🔥 7 günlük serin var — bugünü kaçırma!"*
> *"Serin gece yarısı sıfırlanacak, 1 dakikanı ayır 💪"*

### D. Geri Kazanım / Win-back (Dormant) — 🆕
3 / 7 / 14 / 30 gün açmayan kullanıcıya kademeli, nazik.
> *"Seni özledik 🌱 Bıraktığın yerden devam et."*
> *"3 günlük notların seni bekliyor — bir göz at?"*

### E. Kilometre Taşı / Kutlama — 🆕
Başarı anlarında pozitif pekiştirme (retention'ı en çok artıran tür).
> *"🎉 50. notunu yazdın! Harikasın."*
> *"30 günlük alışkanlık serisi — efsane! 🏆"*

### F. Bağlamsal / Akıllı — 🆕 (Faz 2+)
Kullanıcının verisine bakan dinamik bildirim.
> *"Bugün 3 görevin var, 1'i bitti 👏 Devam?"*
> *"Bu ay bütçenin %80'ine ulaştın 💸"*

### G. Sosyal / Paylaşım — ✅ (kısmen var)
Arkadaş aktivitesi (davet, ortak görev/alışkanlık tamamlama).
> *"Ahmet ortak alışkanlığı tamamladı ✅"* (VAR)
> *"Yeni arkadaşlık isteği 👋"* (VAR)

**Faz 1'in odağı:** A (günlük etkileşim) + C (seri) + D (geri kazanım) + E (kilometre taşı). B ve G zaten büyük ölçüde var; F ve Finans-B Faz 2.

---

## 4. Çok Dilli İçerik Stratejisi (11 dil)

Diller: **tr, en, zh, hi, es, ar, fr, ru, pt, de, ja**.

**Prensipler:**
- Her bildirim türü için **mesaj havuzu** (örn. günlük etkileşim için 20–40 varyant), her dilde ayrı.
- **Rotasyon + tekrar penceresi:** son N (örn. 10) bildirimde kullanılan varyant tekrar seçilmez → kullanıcı hep farklı mesaj görür.
- **Ton yerelleştirmesi:** birebir çeviri değil, kültüre uygun. (Örn. ja/ar'da samimiyet düzeyi farklı; emoji kullanımı dile göre ayarlanır.)
- **Değişken enjeksiyonu:** `{name}`, `{streak}`, `{count}`, `{taskTitle}` gibi yer tutucular — kişiselleştirme.
- **Mevcut i18n ile uyum:** backend'de zaten `lang/*/notifications.php` var (sosyal + paylaşım anahtarları). Yeni türler buraya `engagement`, `streak`, `winback`, `milestone` blokları olarak eklenir — aynı desen.
- **Kalite:** metinleri önce tr+en yazıp, diğer 9 dile çeviri + en az bir anadil gözden geçirmesi ( japonca/çince/arapça için özellikle). İlk sürümde makine + benim düzeltmem, sonra iyileştirme.

**Havuz boyutu önerisi (Faz 1):** tür başına 15–25 varyant × 11 dil. Günlük etkileşim için en geniş havuz (çünkü her gün gider).

---

## 5. Teknik Mimari

### 5.1 Mevcut altyapı (VAR — üzerine inşa edeceğiz)
- **FCM** (kreait/firebase-php) + `FirebaseNotificationService` (tipli metotlar: friend/share/habit).
- **Cihaz token'ları** kullanıcı başına saklı.
- **Scheduler** çalışıyor: `SendNoteReminders` her dakika, idempotent (`reminder_sent_at`).
- **Uygulama içi bildirim** kaydı + push birlikte.
- **Profil'de 7 bildirim aç/kapa** toggle'ı + genel opt-out (VAR).
- Çok dilli `lang/*/notifications.php`.

### 5.2 Yeni bileşenler (🆕)

**a) Veri modeli**
- `notification_logs` tablosu: `user_id`, `type`, `variant_key`, `locale`, `sent_at`, `opened_at`, `fcm_message_id`, `dedupe_key`. → idempotency + metrik + tekrar penceresi.
- Kullanıcı tercih kolonları (profil ayarlarını genişlet):
  - `engagement_enabled` (günlük etkileşim aç/kapa — **ayrı toggle**)
  - `winback_enabled`, `streak_enabled`, `milestone_enabled`
  - `quiet_hours_start` / `quiet_hours_end` (sessiz saatler, örn. 22:00–08:00)
  - `preferred_send_hour` (kullanıcı tercih ederse sabit saat; yoksa akıllı varsayılan)
  - `timezone` (cihazdan alınır; takvim zaten GMT+3 işliyor → aynı mantık)
- `notification_templates` (opsiyonel): havuzu DB'de tutup admin'den düzenlenebilir yapmak — ya da ilk sürümde `lang/*` dosyalarında tutmak (daha basit). **Öneri: Faz 1 dosyada, Faz 2 DB + admin.**

**b) Komutlar (Artisan) + Scheduler**
- `notifications:send-engagement` — günde 1 kez (her kullanıcının yerel sabah/akşam saatine denk gelecek şekilde saatlik tetiklenir, o saatte yereli uygun olanları seçer).
- `notifications:send-streak-guard` — akşam, serisi risk altında olanlara.
- `notifications:send-winback` — günde 1, 3/7/14/30 gün eşiklerine takılanlara.
- `notifications:check-milestones` — kilometre taşı eşiği geçenlere (not/görev/seri sayısı).
- Hepsi **idempotent** (`dedupe_key` + `notification_logs`), **batch FCM** (çok sayıda token tek seferde), **geçersiz token temizliği** (FCM `UNREGISTERED` dönerse sil).

**c) Zamanlama & sessiz saatler (kritik)**
- Scheduler **saatlik** çalışır; her çalışmada "şu an yerel saati = tercih edilen saat olan ve bugün etkileşim almamış" kullanıcıları seçer.
- Sessiz saatler içindeyse gönderme (ertele/atla).
- Varsayılan gönderim: sabah **09:00** (etkileşim) ve akşam **20:00** (seri/özet) — kullanıcı değiştirebilir.

**d) Sıklık & yorgunluk kontrolü (anti-spam)**
- **Günlük sert tavan:** kullanıcı başına en fazla 1 "pazarlama/etkileşim" bildirimi/gün (hatırlatıcılar hariç, onlar kullanıcının kendi kurduğu).
- **Tür bazında cooldown:** win-back en fazla haftada 1–2; milestone sadece gerçek eşikte.
- **Dedupe:** aynı gün aynı türü iki kez gönderme.
- **Global kill-switch:** sorun olursa tüm otomatik bildirimleri tek bayrakla durdurma.

**e) Segmentasyon motoru**
- **Yeni** (0–7 gün): onboarding odaklı, günlük nazik dürtme.
- **Aktif** (son 7 günde açmış): hafif etkileşim + seri.
- **Riskli** (3–7 gün sessiz): win-back başlar.
- **Dormant** (14–30+ gün): daha güçlü win-back, sonra sıklık azalt.
- **Modül kullanımına göre:** çok not yazan → not temalı; alışkanlık odaklı → seri temalı.

---

## 6. İçerik Havuzu Örnekleri (tr + en; 11 dilde yapılacak)

**A. Günlük etkileşim (tr):**
- "Günaydın ☀️ Bugün için küçük bir plan yapalım mı?"
- "Aklındakileri bir nota dök, kafan rahatlasın 🌿"
- "Bugün hangi alışkanlığını besleyeceksin? 💪"
- "Akşam oldu 🌙 Bugünü nasıl geçirdin, bir satır yaz."

**A. Daily engagement (en):**
- "Good morning ☀️ Shall we plan your day?"
- "Drop your thoughts into a note — clear your mind 🌿"
- "Which habit will you feed today? 💪"

**C. Seri (tr):** "🔥 {streak} günlük serin tehlikede — 1 dakikanı ayır!"
**D. Win-back (tr):** "Seni özledik 🌱 Notların ve hedeflerin bıraktığın yerde."
**E. Kilometre taşı (tr):** "🎉 {count}. notun! Harika gidiyorsun."

> Her varyant `{name}`, `{streak}`, `{count}` yer tutucularıyla kişiselleşir. Tam havuz Faz 1'de 11 dilde yazılır.

---

## 7. Ölçüm & Admin Paneli

- **`notification_logs`** → gönderim, açılma (deep-link tıklama `opened_at`), tür/dil kırılımı.
- **Metrikler:** açılma oranı (tür bazında), D1/D7/D30 retention (bildirim alan vs almayan — A/B), opt-out oranı.
- **Admin paneli (Laravel Blade — mevcut panel genişletilir):**
  - Tür bazında gönderim/açılma grafiği
  - Havuz (template) düzenleme (Faz 2'de DB'ye taşınırsa)
  - Global kill-switch, segment önizleme, test gönderimi (tek kullanıcıya)
- **A/B testi:** kullanıcıları iki gruba böl (bildirim alan / almayan veya metin A / B), retention farkını ölç → stratejiyi veriye göre ayarla.

---

## 8. Uyumluluk & Gizlilik

- **İzin:** Android 13+ `POST_NOTIFICATIONS` runtime izni (uygulama zaten FCM kullanıyor, izin akışı var). İzin yoksa gönderme.
- **Play/Apple politikası:** pazarlama bildirimleri için kolay opt-out zorunlu → ayarlarda tür bazında toggle (VAR + genişletilecek). Yanıltıcı/clickbait içerik yok.
- **Sessiz saatler** varsayılan açık (gece rahatsız etmeme).
- **Veri:** token'lar zaten saklı; `notification_logs` kişisel veri → veri silme/hesap silme akışına dahil edilir (hesap silme zaten var).
- **Sıklık şeffaflığı:** kullanıcı "günde en fazla 1" garantisini ayarlarda görür.

---

## 9. Fazlı Yol Haritası

### Faz 1 — MVP (çekirdek motor + en etkili türler)
- Veri modeli: `notification_logs` + kullanıcı tercih kolonları (engagement/winback/streak/milestone toggle, quiet hours, preferred hour, timezone).
- Komutlar: `send-engagement`, `send-winback`, `send-streak-guard`, `check-milestones` + scheduler (saatlik, yerel saat + sessiz saat mantığı).
- İçerik havuzu: 4 tür × ~15–20 varyant × 11 dil (`lang/*/notifications.php`).
- Segmentasyon: yeni/aktif/riskli/dormant.
- Anti-spam: günlük tavan, dedupe, kill-switch.
- Profil UI: yeni toggle'lar + sessiz saat + saat seçimi (Flutter).
- **Çıktı:** kullanıcıya her gün yerel saatinde 1 anlamlı, dilinde, tekrar etmeyen bildirim + seri/win-back/kutlama.

### Faz 2 — Akıllılaştırma + ölçüm
- Bağlamsal bildirimler (F): "3 görevin var", "bütçenin %80'i".
- Finans hatırlatıcı bildirimleri (yaklaşan ödeme/abonelik).
- Admin paneli: metrik grafikleri, havuz DB + düzenleme, test gönderimi.
- A/B testi altyapısı + retention ölçümü.

### Faz 3 — Kişiselleştirme & optimizasyon
- Kullanıcı davranışına göre **en iyi gönderim saati** öğrenme (açma saatlerinden).
- İçerik kişiselleştirme (en çok kullandığı modüle göre tema).
- Metriğe göre havuz/strateji iyileştirme (düşük açılan varyantları ele).

---

## 10. Efor, Risk ve İlk Adım

**Efor (kabaca):**
- Faz 1 backend (model + 4 komut + scheduler + anti-spam + 11 dil havuz): orta-büyük.
- Faz 1 Flutter (profil toggle'ları + sessiz saat/saat seçici): küçük-orta.
- Faz 2–3: orta, veriye bağlı iteratif.

**Riskler & önlemler:**
- **Spam algısı → opt-out:** sert günlük tavan + sessiz saat + kolay kapatma.
- **Yanlış saatte gönderim (timezone):** takvimdeki GMT mantığını yeniden kullan; test kullanıcılarıyla doğrula.
- **Çeviri kalitesi:** anadil gözden geçirmesi, özellikle ja/zh/ar.
- **Geçersiz token birikmesi:** FCM hata kodunda otomatik temizlik.
- **Ölçememe:** `notification_logs` + açılma takibi en baştan (Faz 1), yoksa körüz.

**Önerilen ilk adım (onay verirsen):**
Faz 1'in **çekirdeği** — `notification_logs` + tercih kolonları + `notifications:send-engagement` komutu + scheduler (yerel saat + sessiz saat) + günlük etkileşim havuzu (11 dil) + profil toggle'ı. Yani önce **günde 1 akıllı etkileşim bildirimi** uçtan uca çalışsın; sonra seri/win-back/milestone'u ekleriz.

---

**Karar:** Bu plana göre Faz 1 çekirdeğinden başlayayım mı? Yoksa önce türlerden/sıralamadan bir şeyi değiştirmek ister misin (örn. "önce sadece günlük etkileşim + seri")?
