# LifeSync — Otomatik Bildirim Sistemi · Uygulama Planı (Master / Onaya Hazır)

**Tarih:** 2026-11-03
**Durum:** ONAY BEKLİYOR. Onaylandığında Faz 1'den uygulanır.
**Bu belge** önceki 3 raporu tek yere toplar + yeni istekleri ekler:
- Admin panele **"Otomatik Bildirimler"** bölümü (Bildirimler altında, orada görülebilecek/yönetilebilecek).
- **11 dil için saat dilimine göre** gönderim — **gece saatine denk gelmez**.
- **Kullanıcının dil seçimine göre** bildirimler otomatik ayarlanır (hem içerik dili hem gönderim saati).

> Detay içerik takvimi (gün gün, 90 gün) ve editöryal metinler için: `BILDIRIM_90GUN_DONGU_PLANI.md`, `BILDIRIM_ICERIK_PLANI.md`. Bu belge mimari + yönetim + zamanlama odaklı, uygulama sırasını verir.

---

## 1. Amaç ve ilkeler (özet)

- **Amaç:** Özendirici/ön-bilgilendirici bildirimlerle kullanıcıyı tutmak (alışkanlık edindir, özellik keşfettir), **boğmadan**.
- **Sıklık:** Günde **MAX 1 (bazen 2, bazen 0)**. Sessiz saatlerde asla gönderilmez.
- **Dil:** Kullanıcının uygulama dilinde (11 dil), metin havuzu + rotasyon (tekrar etmez).
- **Zaman:** Kullanıcının **yerel saatine** göre; **gece (22:00–08:00) gönderim yok**.
- **Kontrol:** Kullanıcı tür bazında kapatabilir; admin global yönetir.

---

## 2. ⭐ 11 Dil × Saat Dilimi — Gece saatine denk gelmeyecek gönderim

### 2.1 Mantık (iki katmanlı)
1. **Birincil — cihaz saat dilimi (en doğru):** Uygulama, kullanıcının cihaz timezone'unu backend'e kaydeder (`users.timezone`, örn. `Europe/Istanbul`). Bildirim bu yerel saate göre gönderilir. Takvim modülü zaten GMT/offset işliyor — aynı altyapı kullanılır.
2. **Yedek — dile göre temsilî saat dilimi:** Cihaz timezone'u yoksa, **seçilen uygulama diline** göre temsilî bir saat dilimi atanır (aşağıdaki tablo). Böylece "dil seçtiğinde bildirimler ona göre ayarlanmış olur".

### 2.2 Gönderim pencereleri (her kullanıcının YEREL saatine göre)
- **Sabah brief:** 09:00
- **Akşam recap / etkileşim:** 20:00
- **Sessiz saatler:** 22:00 – 08:00 → bu aralığa düşen hiçbir bildirim gönderilmez (ertelenir/atlanır).

### 2.3 Dil → temsilî saat dilimi (yedek) tablosu
| Dil | Kod | Temsilî saat dilimi | UTC offset |
|---|---|---|---|
| Türkçe | tr | Europe/Istanbul | +3 |
| İngilizce | en | (cihaz TZ; yedek Europe/London) | 0 |
| Çince | zh | Asia/Shanghai | +8 |
| Hintçe | hi | Asia/Kolkata | +5:30 |
| İspanyolca | es | Europe/Madrid (LatAm için cihaz TZ) | +1 |
| Arapça | ar | Asia/Riyadh | +3 |
| Fransızca | fr | Europe/Paris | +1 |
| Rusça | ru | Europe/Moscow | +3 |
| Portekizce | pt | America/Sao_Paulo (PT için cihaz TZ) | −3 |
| Almanca | de | Europe/Berlin | +1 |
| Japonca | ja | Asia/Tokyo | +9 |

> **Önemli:** Tablo yalnızca YEDEK. Cihaz timezone'u varsa her zaman o kullanılır (en/es/pt gibi çok bölgeye yayılan diller için şart). Scheduler **saatlik** çalışır; her çalışmada "şu an yerel saati 09:00 (veya 20:00) olan ve sessiz saatte olmayan" kullanıcıları seçer → kimse gece uyandırılmaz.

### 2.4 Dil seçimine göre otomatik ayar
Kullanıcı uygulama dilini seçtiğinde (onboarding veya ayarlar):
- **İçerik dili** → o dil (metin havuzundan o dilde gönderilir).
- **Gönderim saat dilimi** → cihaz TZ varsa o, yoksa dile göre temsilî TZ (tablo).
- Kullanıcı isterse **tercih edilen saat** (örn. 08:00/19:00) ve **sessiz saatleri** ayarlardan değiştirebilir.

---

## 3. Bildirim türleri (Faz 1 odak)

| Tür | Açıklama | Durum |
|---|---|---|
| **A. Günlük etkileşim** | Günde 1, yerel sabah/akşam — özendirici (alışkanlık edin, görev oluştur, aboneliğini kaydet…) | 🆕 |
| **C. Seri koruma** | Alışkanlık serisi riskteyken nazik dürtme | 🆕 |
| **D. Geri kazanım (win-back)** | 3/7/14/30 gün sessiz kalana | 🆕 |
| **E. Kilometre taşı** | Başarı anında kutlama | 🆕 |
| B. Modül hatırlatıcıları | Kullanıcının kurduğu not/görev/alışkanlık/takvim | ✅ var |
| G. Sosyal/paylaşım | Arkadaş aktivitesi | ✅ var |

İçerik ve gün-gün akış: `BILDIRIM_90GUN_DONGU_PLANI.md` (90 günlük döngü, baştan tekrar eder).

---

## 4. Teknik mimari

### 4.1 Mevcut (üzerine inşa)
FCM (kreait/firebase-php) + `FirebaseNotificationService`, cihaz token'ları, scheduler (`SendNoteReminders` her dakika, idempotent), profilde bildirim toggle'ları, `lang/*/notifications.php`.

### 4.2 Yeni bileşenler
**Veri modeli:**
- `users`: `timezone`, `locale`, `engagement_enabled`, `streak_enabled`, `winback_enabled`, `milestone_enabled`, `quiet_hours_start` (vars. 22:00), `quiet_hours_end` (vars. 08:00), `preferred_morning_hour` (09:00), `preferred_evening_hour` (20:00).
- `notification_logs`: `user_id`, `type`, `variant_key`, `locale`, `sent_at`, `opened_at`, `fcm_message_id`, `dedupe_key` → idempotency + metrik + tekrar penceresi.
- `notification_templates` (Faz 2'de admin düzenlemesi için DB; Faz 1'de `lang/*` dosyalarında havuz).

**Komutlar + scheduler (saatlik, yerel saat + sessiz saat mantığı):**
- `notifications:send-engagement`
- `notifications:send-streak-guard`
- `notifications:send-winback`
- `notifications:check-milestones`
- Hepsi idempotent, batch FCM, geçersiz token temizliği.

**Anti-spam:** günlük tavan (1 etkileşim/gün), tür cooldown, dedupe, global kill-switch.
**Segmentasyon:** yeni / aktif / riskli / dormant + modül kullanımı.

---

## 5. ⭐ Admin Panel — "Otomatik Bildirimler" bölümü

**Konum:** Admin paneli → **Bildirimler** → yeni sekme/bölüm **"Otomatik Bildirimler"** (mevcut Laravel Blade paneline eklenir; bkz admin-panel çalışması).

### 5.1 Faz 1 (temel yönetim + görünürlük)
- **Durum kartı:** her türün (etkileşim/seri/win-back/kilometre taşı) **açık/kapalı** toggle'ı + son çalışma zamanı.
- **Global kill-switch:** tüm otomatik bildirimleri tek tuşla durdur.
- **Saat/dil ayarları:** varsayılan sabah/akşam saati, sessiz saatler; **dil → saat dilimi tablosu** (görüntüle/düzenle).
- **Test gönderimi:** seçilen bir kullanıcıya/cihaza anında test bildirimi gönder.
- **Son gönderimler listesi:** `notification_logs`'tan son N kayıt (kullanıcı, tür, dil, zaman, açıldı mı).

### 5.2 Faz 2 (içerik + metrik)
- **İçerik havuzu editörü:** her tür × 11 dil varyantlarını panelden ekle/düzenle/sil (DB'ye taşınır).
- **90 günlük takvim görünümü:** gün ↔ tür/konu eşleşmesini görüntüle/düzenle.
- **Metrik paneli:** tür/dil bazında gönderim, açılma oranı, opt-out oranı, D1/D7/D30 (A/B: bildirim alan vs almayan).
- **Segment önizleme:** her segmentte kaç kullanıcı var.

---

## 6. Flutter (uygulama) tarafı

- **Profil → Bildirim ayarları** genişletilir: 4 yeni tür toggle'ı (etkileşim/seri/win-back/kilometre taşı) + **sessiz saatler** + **tercih edilen saat** seçici.
- **Dil seçimi** (onboarding/ayarlar): seçilen dil backend'e `locale` olarak, cihaz `timezone`'u ile birlikte kaydedilir → bildirimler otomatik o dile+saate ayarlanır.
- Android 13+ `POST_NOTIFICATIONS` izni (zaten FCM akışı var).

---

## 7. Uygulama sırası (onaylanınca)

**Faz 1 — MVP (çekirdek):**
1. `users` tercih kolonları + `timezone`/`locale` kaydı (Flutter'dan gönderim) + `notification_logs`.
2. `notifications:send-engagement` komutu + saatlik scheduler (yerel saat + sessiz saat + dil→TZ yedeği).
3. Günlük etkileşim havuzu (11 dil, ~15–20 varyant) + rotasyon.
4. Seri/win-back/kilometre taşı komutları + havuzları.
5. Anti-spam (günlük tavan, dedupe, kill-switch).
6. **Admin "Otomatik Bildirimler" bölümü (Faz 1 özellikleri)** — toggle, kill-switch, saat/dil-TZ ayarı, test gönderimi, son gönderimler.
7. Flutter profil toggle'ları + sessiz saat/saat seçici + dil/timezone kaydı.

**Faz 2 — akıllılaştırma + metrik:** bağlamsal bildirimler, finans hatırlatıcıları, admin içerik editörü + metrik paneli + A/B.

**Faz 3 — optimizasyon:** en iyi gönderim saatini öğrenme, içerik kişiselleştirme, metriğe göre iyileştirme.

---

## 8. Riskler & önlemler
- **Gece gönderimi:** sessiz saat + yerel saat kontrolü (çift güvenlik: cihaz TZ → yoksa dil→TZ).
- **Spam/opt-out:** günlük tavan + kolay kapatma + kill-switch.
- **Çok bölgeli diller (en/es/pt):** cihaz TZ önceliği şart; dil→TZ sadece yedek.
- **Çeviri kalitesi:** 11 dil havuzunda anadil gözden geçirmesi (özellikle ja/zh/ar).
- **Ölçememe:** `notification_logs` + açılma takibi Faz 1'den.

---

## 9. Onay

**Onaylıyor musun?** Onaylarsan **Faz 1 çekirdeğinden** başlıyorum:
`users` tercih/timezone/locale + `notification_logs` → `send-engagement` komutu + saatlik scheduler (yerel saat + sessiz saat + dil→TZ) → günlük etkileşim havuzu (11 dil) → **admin "Otomatik Bildirimler" bölümü** → Flutter profil toggle'ları + dil/timezone kaydı. Sonra seri/win-back/kilometre taşı.

Değiştirmek/eklemek istediğin bir şey var mı (saatler, diller, türlerin sırası, admin özellikleri)?
