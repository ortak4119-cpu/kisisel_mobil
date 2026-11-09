# Profil ↔ Ayarlar Düzenleme Raporu

**Tarih:** 2026-11-09 · **Durum:** ONAY BEKLİYOR (kod değişikliği yapılmadı)

## 1. Sorun özeti

Profil ve Ayarlar iki ayrı ekran ama içerikleri iç içe geçmiş:

| Sorun | Nerede |
|---|---|
| **Çıkış Yap iki yerde** | Profil altındaki kırmızı kart **+** Ayarlar › Hesap Ayarları |
| **Destek iki yerde** | Profil › Destek (Görüş/şikayet, Yardım, Hakkında, Tanıtım) **+** Ayarlar › Destek (Bize ulaşın, Değerlendir) |
| **"Yardım ve destek" satırı boş** | Profil'de bu satır sadece Ayarlar sayfasını açıyor — kendi içeriği yok |
| **Tema Profil'de, Dil Ayarlar'da** | Aynı "görünüm" konusu iki ekrana bölünmüş (Profil › Hesap › "Görünüm ve tema" / Ayarlar › Görünüm › Dil + Animasyon) |
| **Üyelik iki yerde** | Profil › Hesap › Üyelik **+** Ayarlar üstünde Premium kartı |
| **"Hesap" başlığı altında tema var** | Profil › HESAP bölümünde Hesap bilgileri, Üyelik ve… Tema. Tema hesapla ilgili değil |
| **Kişisel hedefler sabit** | "Günlük 10 görev" ve "%30 tasarruf" kodda sabit; kullanıcı düzenleyemiyor ("Hedefleri düzenle" anahtarı var ama buton yok) |

## 2. Ayrım ilkesi (önerilen)

- **PROFİL = "Ben"** → kimliğim, ilerlemem, sosyal çevrem, üyeliğim. Bakılan/övünülen şeyler.
- **AYARLAR = "Uygulama nasıl davransın"** → bildirim, görünüm, dil, gizlilik, hesap güvenliği, yasal, destek. Ayarlanan şeyler.

Kural: Bir satırda **anahtar/seçim** varsa Ayarlar'a; **sayı/ilerleme/kişi** varsa Profil'e.

## 3. Mevcut envanter ve karar

### 3a. Profil'de şu an olanlar

| # | Öğe | Şu an | Karar | Gerekçe |
|---|---|---|---|---|
| 1 | Başlık kartı (avatar, ad, @kullanıcı, üyelik tarihi, "Profili Düzenle") | Profil | **Profil'de kalır** | Kimlik |
| 2 | ⚙️ Ayarlar kısayolu (sağ üst) | Profil | **Kalır** | Tek giriş noktası |
| 3 | "Profilin %25 tamamlandı · Tamamla" kartı | Profil | **Kalır** | Profil doluluğu |
| 4 | SEVİYE: Seviye/XP çubuğu | Profil | **Kalır** | İlerleme |
| 5 | SEVİYE: Başarılar ve rozetler | Profil | **Kalır** | İlerleme |
| 6 | SEVİYE: Arkadaşlar (+istek rozeti) | Profil | **Kalır** | Sosyal |
| 7 | SEVİYE: Aktif gün | Profil | **Kalır** | İlerleme |
| 8 | BU AYKİ İLERLEME (4 istatistik) | Profil | **Kalır** | İstatistik |
| 9 | KİŞİSEL HEDEFLER (2 hedef) | Profil | **Kalır + düzenlenebilir yapılır** | Sabit 10 / %30 yerine kullanıcı hedef girer ("Hedefleri düzenle") |
| 10 | HESAP › Hesap bilgileri (e-posta, doğrulama) | Profil | **→ Ayarlar › Hesap** | Güvenlik/hesap işlemi; "Profili Düzenle" zaten kimliği kapsıyor |
| 11 | HESAP › Üyelik (plan) | Profil | **Profil'de kalır, tek yer olur** | "Benim planım" bilgisi; Ayarlar'daki Premium kartı kaldırılır |
| 12 | HESAP › Görünüm ve tema | Profil | **→ Ayarlar › Görünüm** | Dil ve animasyonla aynı yere; tema hesapla ilgili değil |
| 13 | DESTEK › Görüş / şikayet bildir | Profil | **→ Ayarlar › Destek** | Destek tek yerde |
| 14 | DESTEK › Yardım ve destek (Ayarlar'a yönlendiriyor) | Profil | **Kaldırılır** | Boş satır; Ayarlar zaten ⚙️ ile açılıyor |
| 15 | DESTEK › Uygulama hakkında | Profil | **→ Ayarlar › Hakkında** | Uygulama bilgisi |
| 16 | DESTEK › Tanıtımı tekrar izle | Profil | **→ Ayarlar › Hakkında** | Uygulama bilgisi |
| 17 | Çıkış Yap kartı (en alt) | Profil | **Kaldırılır** | Ayarlar › Hesap'ta zaten var; Profil kimlik ekranı olarak temiz kalır |
| 18 | "Son senkron · 19:41" | Profil | **Kalır (küçük)** | Zararsız bilgi |

### 3b. Ayarlar'da şu an olanlar

| # | Öğe | Şu an | Karar | Gerekçe |
|---|---|---|---|---|
| 19 | Premium kartı (üstte, premium olmayana) | Ayarlar | **Kaldırılır** | Üyelik Profil'de (#11); ayarlar sayfası pazarlama kartıyla başlamasın |
| 20 | BİLDİRİMLER (ana anahtar, ses, 7 tür toggle, motivasyon) | Ayarlar | **Kalır** | Ayar |
| 21 | GÖRÜNÜM › Dil | Ayarlar | **Kalır** | Ayar |
| 22 | GÖRÜNÜM › Animasyonları kapat | Ayarlar | **Kalır** | Ayar |
| 23 | GİZLİLİK › Profil görünürlüğü + 3 "göster" anahtarı | Ayarlar | **Kalır** | Anahtar = ayar (profilin başkalarına görünümünü yönetir ama bir tercihtir) |
| 24 | HESAP › Çıkış Yap | Ayarlar | **Kalır (tek yer)** | |
| 25 | HESAP › Tüm cihazlardan çıkış | Ayarlar | **Kalır** | |
| 26 | HESAP › Verilerimi dışa aktar | Ayarlar | **Kalır** | |
| 27 | HESAP › Hesabı sil | Ayarlar | **Kalır (en altta)** | Tehlikeli işlem sonda |
| 28 | YASAL › Gizlilik Politikası, Hizmet Şartları | Ayarlar | **→ Hakkında bölümüne birleşir** | Ayrı başlık gereksiz |
| 29 | DESTEK › Bize ulaşın, Uygulamayı değerlendir | Ayarlar | **Kalır** | |
| 30 | Sürüm bilgisi kutusu | Ayarlar | **→ Hakkında bölümüne** | |

## 4. Önerilen son yapı

### PROFİL
```
[Başlık kartı] avatar · ad · @kullanıcı · üyelik tarihi · Profili Düzenle        ⚙️
[Profil tamamlanma kartı]
SEVİYE & SOSYAL      Seviye/XP · Başarılar ve rozetler · Arkadaşlar · Aktif gün
BU AYKİ İLERLEME     Tamamlanan görev · Alışkanlık oranı · Günlük not · Oluşturulan not
KİŞİSEL HEDEFLER     Günlük görev hedefi · Aylık tasarruf hedefi · [Hedefleri düzenle]
ÜYELİK               Plan (Ücretsiz/Premium) · Yükselt / Yönet
Son senkron · 19:41
```
Kaldırılan: Hesap bilgileri, Görünüm ve tema, Destek bölümü (4 satır), Çıkış kartı.

### AYARLAR
```
BİLDİRİMLER   (mevcut — ana anahtar, bildirim sesi, tür anahtarları, günlük motivasyon)
GÖRÜNÜM       Tema (geri gelir) · Dil · Animasyonları kapat
GİZLİLİK      Profil görünürlüğü · Seviyeyi/Başarımları/Alışkanlıkları göster
HESAP         Hesap bilgileri (yeni) · Verilerimi dışa aktar · Tüm cihazlardan çıkış · Çıkış yap · Hesabı sil
DESTEK        Görüş / şikayet bildir (yeni) · Bize ulaşın · Uygulamayı değerlendir
HAKKINDA      Uygulama hakkında · Tanıtımı tekrar izle · Gizlilik Politikası · Hizmet Şartları · Sürüm 4.1.1
```
Kaldırılan: Premium kartı. Birleşen: Yasal → Hakkında.

## 5. Sonuç

- Profil **5 bölümden 4 bölüme** iner (Hesap/Destek karışıklığı gider), tamamen "ben + ilerlemem".
- Ayarlar **7 bölümden 6 bölüme** iner, her şey tek yerde: tema+dil birlikte, destek tek, çıkış tek.
- Hiçbir özellik kaybolmaz; sadece 1 boş satır (Yardım ve destek) ve 1 tekrar (Premium kartı) silinir.

## 6. Sana sormam gereken 3 karar

1. **Tema:** Ayarlar › Görünüm'e geri alalım mı? (Bugün sen Profil'e taşıttın; bu rapor Dil ile aynı yerde olmasını öneriyor.) **Önerim: Ayarlar.**
2. **Çıkış Yap:** Sadece Ayarlar'da kalsın mı, yoksa Profil altındaki kırmızı kart da dursun mu? **Önerim: sadece Ayarlar.**
3. **Üyelik/Premium:** Tek yer Profil › Üyelik mi olsun (Ayarlar'daki Premium kartı kalkar)? **Önerim: evet.**

Onaylarsan (veya kararları değiştirirsen) uygulamaya alıp 11 dilde başlık/anahtarları da düzenlerim. Backend değişikliği gerekmiyor; "Hedefleri düzenle" için hedef değerleri cihazda saklanır (istenirse sonra backend'e de yazılır).
