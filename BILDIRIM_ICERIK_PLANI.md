# LifeSync — Bildirim & Rapor İçerik Planı (Günlük / Haftalık / Aylık, Gün Gün)

**Tarih:** 2026-11-03
**Bu belge neyi anlatır:** Bildirimlerde **ne konuşulacağını** — günlük, haftalık, aylık raporların içeriğini, hangi gün ne gönderileceğini (gün gün), ve her bildirimde nelerden bahsedilmesi gerektiğini. (Teknik altyapı ayrı belgede: `OTOMATIK_BILDIRIM_RAPORU.md`.)

**Besleyen modüller:** Notlar · Görevler · Alışkanlıklar · Takvim · Finans · Sosyal/Paylaşım.

---

## 0. Katmanlar: 4 tür "rapor/bildirim"

| Katman | Ne zaman | Kanal | Amaç |
|---|---|---|---|
| **A. Günlük anlık** | Gün içinde olay bazlı | Push | Hatırlatıcı, seri, bağlamsal dürtme |
| **B. Günlük özet** | Sabah ~09:00 + Akşam ~20:30 | Push → uygulama içi "Günün Özeti" ekranı | Güne hazırlan / günü kapat |
| **C. Haftalık rapor** | Pazar ~20:00 veya Pzt ~08:00 | Push → "Haftan" ekranı | Haftayı değerlendir + gelecek hafta |
| **D. Aylık rapor** | Ayın 1'i ~10:00 | Push → "Ayın" ekranı | Büyük resim, trend, başarı, hedef |

> **Önemli ayrım:** "Push" kısa bir tetikleyicidir (1–2 cümle); tıklayınca açılan **uygulama içi rapor ekranı** zengin içeriği (grafik, sayılar, ısı haritası) gösterir. Push kullanıcıyı içeri çeker, asıl rapor içeride durur.

---

## 1. GÜNLÜK

### 1A. Sabah Brief (~09:00) — "Güne hazırlan"
**Push örneği:** *"Günaydın ☀️ Bugün 3 görevin ve 2 alışkanlığın var. Hadi başlayalım!"*

**Açılan ekranda / içerikte nelerden bahsedilmeli:**
- Bugünün **görevleri** (sayı + ilk 3 başlık)
- Bugün **yapılacak alışkanlıklar** (ve mevcut serileri 🔥)
- Bugünün **takvim etkinlikleri** (saatleriyle)
- **Yaklaşan ödeme/abonelik** varsa uyarı (💸)
- Küçük bir **motivasyon / niyet** cümlesi ("Bugün en önemli 1 şey ne?")
- CTA: "Günü planla" → uygulama

### 1B. Akşam Recap (~20:30) — "Günü kapat"
**Push örneği:** *"Bugün 2/3 görevi bitirdin 👏 Alışkanlık serini korumak için 1 dakikan var mı?"*

**İçerikte nelerden bahsedilmeli:**
- Bugün **tamamlanan / kalan görevler** (2/3 gibi)
- **İşaretlenmemiş alışkanlıklar** (seri riski varsa vurgula)
- **Günlük/not yazma daveti** ("Bugün nasıldı? Bir satır yaz") — Dear Me tarzı
- Bugünün kısa **başarı özeti** (pozitif pekiştirme)
- Varsa yarının ilk etkinliği ("Yarın 10:00'da toplantın var")

### 1C. Gün içi anlık (olay bazlı)
- **Hatırlatıcılar** (kullanıcının kurduğu not/görev/alışkanlık/takvim) — VAR
- **Seri koruma** (akşam, seri gece sıfırlanacaksa)
- **Bağlamsal** ("3 görevin var, 1'i bitti — devam?")
- **Sosyal** (arkadaş ortak görevi/alışkanlığı tamamladı)
- **Kutlama** (kilometre taşı anında)

### 1D. Haftanın GÜN GÜN teması (düzenli kullanıcı için)
Aynı sabah/akşam iskeleti, ama **her günün bir teması** var → tekdüzelik kırılır:

| Gün | Sabah teması | Akşam teması |
|---|---|---|
| **Pazartesi** | Haftaya plan: "Bu haftanın 1 büyük hedefi ne?" | Hafta başladı, ilk günü değerlendir |
| **Salı** | Odak günü: en önemli göreve odaklan | Üretkenlik + alışkanlık kontrol |
| **Çarşamba** | Hafta ortası: "Yarı yoldasın, nasıl gidiyor?" | Alışkanlık serisi hatırlatması 🔥 |
| **Perşembe** | Fikir/not günü: "Aklındaki fikirleri bir yere yaz" | Görev temizliği: biriken küçük işler |
| **Cuma** | Haftayı kapatışa hazırlık + finans gözden geçir 💸 | Haftanın küçük zaferlerini say |
| **Cumartesi** | Hafif/kişisel: "Kendine zaman ayır 🌿" | Günlük yazma / yansıma daveti |
| **Pazar** | Dinlen + gelecek haftayı önizle | **HAFTALIK RAPOR** 📊 (bkz. Bölüm 2) |

> Not: Günde **en fazla 1 etkileşim + 1 özet** mantığı korunur; hatırlatıcılar bunun dışındadır (onları kullanıcı kurar). Sessiz saatlerde gönderilmez.

---

## 2. HAFTALIK RAPOR ("Haftan") — Pazar akşamı

**Push örneği:** *"📊 Haftan hazır! Bu hafta 14 görev bitirdin, en uzun serin 6 gün. Özete göz at →"*

**Rapor ekranında bölüm bölüm nelerden bahsedilmeli:**

1. **Başlık / genel skor** — "Harika bir hafta!" + küçük bir skor/yüzde (tamamlama oranı)
2. **Görevler** — tamamlanan / toplam, geçen haftaya göre değişim (↑↓), en verimli gün
3. **Alışkanlıklar** — her alışkanlığın **tutarlılık %**'si (7/7, 5/7…), en uzun seri, mini **haftalık ısı haritası** (7 kutu)
4. **Notlar** — kaç not/günlük yazıldı, en çok yazılan gün
5. **Takvim** — kaç etkinlik vardı / tamamlandı, gelecek hafta kaç etkinlik
6. **Finans** — haftalık gelir/gider özeti, bütçenin ne kadarı kullanıldı, en çok harcanan kategori 💸
7. **Seriler & rozetler** — bu hafta kazanılan başarılar 🏆
8. **En iyi günün** — "Çarşamba her şeyi hallettin!" (pozitif)
9. **Gelecek hafta önizleme** — kaç görev/etkinlik bekliyor, 1 öneri ("Pazartesi 3 görevin var, bu akşam planla")
10. **Nazik kapanış** — motivasyon + paylaşma seçeneği ("Haftanı arkadaşınla paylaş")

**Üslup:** kutlayıcı, suçlayıcı değil. Kötü hafta geçtiyse bile "yeni hafta temiz sayfa" tonu.

---

## 3. AYLIK RAPOR ("Ayın") — Ayın 1'i

**Push örneği:** *"🗓️ Ekim ayın özetin hazır! 58 görev, 3 alışkanlıkta 20+ gün seri. Rapora bak →"*

**Rapor ekranında nelerden bahsedilmeli:**

1. **Ay özeti kartı** — "Ekim'de neler başardın" + büyük sayılar (toplam görev, not, aktif gün sayısı)
2. **Aktiflik takvimi** — ay boyu **aylık ısı haritası** (hangi günler aktiftin)
3. **Alışkanlık derinliği** — her alışkanlığın aylık tutarlılığı, en uzun seri, en çok ilerleyen alışkanlık
4. **Görev trendi** — haftadan haftaya tamamlama grafiği, geçen aya göre değişim
5. **Finans ay kapanışı** — toplam gelir/gider, kategori dağılımı, bütçe tutturma, önceki aya kıyas, abonelik/taksit özeti 💸
6. **Notlar/günlük** — ay boyu kaç giriş, ruh hali dağılımı (günlük mood verisi varsa)
7. **Başarılar & kilometre taşları** — ay içinde kazanılanlar, "ilk kez" anları (ilk 30 günlük seri vb.) 🏆
8. **Yılın gidişatı** — bu ay yıllık hedeflere ne kadar katkı (varsa)
9. **Gelecek ay için hedef belirleme** — kullanıcıyı 1 hedef koymaya davet et (katılım + retention)
10. **Kutlama + paylaşım** — "Ayını özetleyen kartı paylaş" (sosyal büyüme)

**Üslup:** yıllık "Spotify Wrapped" hissi — gurur verici, görsel, paylaşılası.

---

## 4. YENİ KULLANICI — 30 GÜNLÜK GÜN GÜN PLAN

Yeni kurulan kullanıcı için kritik ilk 30 gün. Amaç: **alışkanlık kurdurmak** (günlük açtırmak), modülleri keşfettirmek, güven inşa etmek. İlk günlerde **az ve nazik**, sonra düzenli.

### Hafta 1 — Tanışma & güven (günde en fazla 1, yumuşak)
| Gün | Odak | Örnek bildirim |
|---|---|---|
| 1 | Hoş geldin + ilk not | "LifeSync'e hoş geldin 👋 İlk notunu yazmaya ne dersin?" |
| 2 | İlk görev | "Bugün için 1 küçük görev ekle — bitirince harika hissedeceksin ✅" |
| 3 | İlk alışkanlık | "Küçük bir alışkanlık seç (su içmek, okumak…) ve takibe başla 🌱" |
| 4 | Takvim keşfi | "Bu haftaki bir etkinliği takvime ekle, hiçbir şey kaçmasın 📅" |
| 5 | Not + etiket | "Fikirlerini etiketleyerek düzenle — ara sıra bak 🏷️" |
| 6 | İlk hafif gün | "Harika gidiyorsun 🌿 Bugün sadece kendine 5 dakika ayır." |
| 7 | 1. hafta kutlaması | "🎉 1 haftadır buradasın! İşte ilk mini özetin →" (küçük haftalık rapor) |

### Hafta 2 — Tutarlılık & seri (günlük ritim kuruluyor)
| Gün | Odak | Örnek |
|---|---|---|
| 8 | Seri başlat | "Alışkanlığını bugün de işaretle, seri başlasın 🔥" |
| 9 | Sabah brief'e geçiş | "Günaydın ☀️ Bugünün planı: 2 görev, 1 alışkanlık." |
| 10 | Finans tanıtımı | "Harcamalarını eklemeye başla — ay sonunda net göreceksin 💸" |
| 11 | Akşam recap'e geçiş | "Bugünü nasıl geçirdin? 1 satır yaz, günü kapat 🌙" |
| 12 | Seri koruma | "🔥 4 günlük serin var — bugünü kaçırma!" |
| 13 | Paylaşım tanıtımı | "Bir alışkanlığı arkadaşınla paylaş, birlikte daha kolay 👥" |
| 14 | 2. hafta raporu | "📊 2. haftan hazır — ilerlemene bak!" |

### Hafta 3 — Derinleşme & ilk kilometre taşları
| Gün | Odak | Örnek |
|---|---|---|
| 15 | Yarı yol kutlaması | "15 gündür buradasın 🎉 Alışkanlık oturuyor!" |
| 16 | Takvim + hatırlatıcı | "Önemli bir etkinliğe hatırlatıcı kur, aklından çıkmasın ⏰" |
| 17 | Not zenginleştirme | "Notlarına checklist ekle — alışveriş/planlar için pratik ☑️" |
| 18 | Bağlamsal | "Bugün 4 görevin var, 2'si bitti 👏 Son düzlük!" |
| 19 | Finans bütçe | "Aylık bütçe belirle, harcamaları kontrol altına al 💸" |
| 20 | Seri kilometre taşı | "🔥 10 günlük seri! Muhteşem gidiyorsun." |
| 21 | 3. hafta raporu | "📊 3 hafta doldu — en iyi haftan bu muydu?" |

### Hafta 4 — Pekiştirme & aylık kapanış
| Gün | Odak | Örnek |
|---|---|---|
| 22 | Yansıma | "Bu ay neyi başardın? Bir nota yaz, sonra gülümseyerek oku 🌿" |
| 23 | Paylaşımlı hedef | "Arkadaşınla ortak bir hedef koy — birlikte başarın 👥" |
| 24 | Bağlamsal finans | "Bu ay bütçenin %70'ine ulaştın — kalanına dikkat 💸" |
| 25 | Alışkanlık çeşitlendir | "Yeni bir küçük alışkanlık eklemeye hazır mısın? 🌱" |
| 26 | Hafif gün | "Kendine iyi davran 💛 Bugün sadece 1 küçük adım yeter." |
| 27 | Seri büyük eşik | "🏆 Neredeyse 20 günlük seri — efsane!" |
| 28 | 4. hafta raporu | "📊 4. haftan hazır — bir ayı tamamlamak üzeresin!" |
| 29 | Aylık rapora hazırlık | "Yarın ilk aylık özetin geliyor 🗓️ Harika bir ay oldu." |
| 30 | **AYLIK RAPOR** | "🎉 İlk ayını tamamladın! İşte ayının özeti →" (tam aylık rapor) |

> 30. günden sonra kullanıcı "düzenli" segmentine geçer: Bölüm 1D (haftanın gün gün teması) + haftalık/aylık raporlar devreye girer.

---

## 5. Her bildirimde "nelerden bahsedilmeli" — İçerik ilkeleri (checklist)

**Her mesajda olmalı:**
- **Tek net konu** (bir bildirim = bir mesaj; karıştırma)
- **Kişiselleştirme** — isim, sayı, seri, görev başlığı (`{name}`, `{streak}`, `{count}`, `{taskTitle}`)
- **Pozitif/nazik ton** — suçlama değil, davet ("kaçırdın" değil, "hâlâ zaman var")
- **Net CTA** — tek bir eylem ("Günü planla", "Serini koru", "Rapora bak")
- **Kısalık** — başlık ≤ ~40 karakter, gövde ≤ ~120 karakter (ekranda kesilmesin)
- **1 emoji** (bağlama uygun) — dile göre ayarlı

**Nelerden bahsedilebilir (konu havuzu):**
- Bugünün/yarının görevleri, bitenler/kalanlar
- Alışkanlık serileri, risk altındaki seri, yeni seri rekoru
- Takvim etkinlikleri, yaklaşan toplantı/randevu
- Yaklaşan ödeme, abonelik yenilemesi, bütçe durumu
- Not/günlük yazma daveti, biriken fikirler
- Kilometre taşları, rozetler, "ilk kez" anları
- Arkadaş aktivitesi (ortak görev/alışkanlık, davet)
- Dönemsel özet (gün/hafta/ay)
- Motivasyon/niyet cümlesi (modülden bağımsız)

**Kaçınılacaklar:**
- Günde çok sayıda pazarlama bildirimi (opt-out sebebi #1)
- Gece/sessiz saatte gönderim
- Clickbait / yanıltıcı başlık
- Aynı metnin tekrarı (havuz + rotasyon şart)
- Suçlayıcı/baskıcı dil ("Yine mi yapmadın?")
- Boş rapor (veri yoksa gönderme veya "başlamak için ekle" de)

---

## 6. Hangi rapor hangi veriden besleniyor? (modül → metrik)

| Modül | Günlük | Haftalık | Aylık |
|---|---|---|---|
| **Görevler** | bugün yapılacak/biten | hafta tamamlama %, en verimli gün | aylık trend, toplam |
| **Alışkanlıklar** | bugün işaretlenecek, seri | tutarlılık %, haftalık ısı haritası | aylık ısı haritası, en uzun seri |
| **Notlar** | yazma daveti | kaç giriş | ay boyu giriş, mood dağılımı |
| **Takvim** | bugünün etkinlikleri | hafta etkinlik sayısı, önizleme | aylık yoğunluk |
| **Finans** | yaklaşan ödeme | haftalık gider, bütçe | ay kapanışı, kategori, kıyas |
| **Sosyal** | arkadaş aktivitesi | ortak başarılar | — |

---

## 7. Özet — Ne sunuyoruz?

1. **Günlük:** sabah brief (güne hazırlan) + akşam recap (günü kapat) + gün içi anlık (hatırlatıcı/seri/bağlamsal). Her günün bir teması (Bölüm 1D).
2. **Haftalık rapor:** Pazar akşamı, 10 bölümlü "Haftan" (görev/alışkanlık/not/takvim/finans/seri/en iyi gün/gelecek hafta).
3. **Aylık rapor:** ayın 1'i, "Ayın" (Spotify Wrapped hissi, sayılar + ısı haritası + finans kapanışı + hedef belirleme + paylaşım).
4. **Yeni kullanıcı 30 günlük gün gün plan:** tanışma → tutarlılık → derinleşme → aylık kapanış.

**İlk olarak hangisini yapalım?** Önerim:
- **1. adım:** Günlük sabah brief + akşam recap (uçtan uca, 11 dil) — en yüksek günlük değer.
- **2. adım:** Haftalık rapor ekranı + Pazar push'u.
- **3. adım:** Aylık rapor + 30 günlük yeni kullanıcı serisi.

Hangisinden başlayalım, ya da içeriklerde eklemek/çıkarmak istediğin bölüm var mı?
