# LifeSync — Yayın Öncesi Test Kontrol Listesi

> Amaç: Uygulamayı mağazaya (Play Store / App Store) göndermeden önce **donma,
> kasma, tutarsızlık, giriş/veri sorunları** ve genel kalite problemlerini
> yakalamak. Her maddeyi en az bir **gerçek cihazda** (sadece emülatörde değil)
> test et. İşaretle: `[ ]` yapılmadı · `[x]` sorunsuz · `[!]` sorun var (not düş).

**Test ortamı bilgileri (doldur):**

| Alan | Değer |
|---|---|
| Sürüm (build) | |
| Cihaz(lar) | |
| Android / iOS sürümü | |
| Dil / Tema | |
| Test tarihi | |
| Testi yapan | |

---

## 0. En kritik “yayından önce mutlaka” kontrolleri

- [ ] Uygulama **soğuk başlatmada** (tamamen kapalıyken) açılıyor, splash’ta takılmıyor.
- [ ] İnternet **yokken** açılış çökmüyor; anlamlı bir uyarı/offline davranışı var.
- [ ] Hesapla giriş → çıkış → tekrar giriş sorunsuz.
- [ ] Verilerin kaybı yok (not/görev/işlem ekle → uygulamayı kapat/aç → duruyor).
- [ ] Çökme yok: hiçbir temel akış “beyaz/boş ekran” ya da donma ile bitmiyor.
- [ ] Gerçek cihazda **akıcılık**: liste kaydırmaları, animasyonlar, sayfa geçişleri takılmıyor.

---

## 1. Giriş / Kayıt / Kimlik (en sık sorun çıkan yer)

### Kayıt ol
- [ ] Ad / e-posta / şifre ile kayıt başarılı.
- [ ] Geçersiz e-posta (ör. `abc`) → anlamlı hata.
- [ ] Kısa şifre (< 8) → anlamlı hata.
- [ ] Zaten kayıtlı e-posta → “kullanımda” hatası net.
- [ ] Koşullar/gizlilik linkleri açılıyor.
- [ ] Kayıt sonrası doğrudan ana ekrana gidiyor.

### Giriş yap
- [ ] Doğru bilgiyle giriş.
- [ ] Yanlış şifre → net hata, çökme yok.
- [ ] Şifremi unuttum → kod gönderme + sıfırlama tam akışı çalışıyor.
- [ ] **Google ile giriş/kayıt** (gerçek cihaz).
- [ ] **Apple ile giriş/kayıt** (gerçek iOS cihaz — Apple şartı).
- [ ] Google/Apple butonları alt alta (tek sıra değil), tıklanabilir.

### Oturum / token
- [ ] Uygulamayı günlerce açmayıp tekrar açınca oturum durumu doğru (ya giriş gerekiyor ya devam).
- [ ] “Tüm cihazlardan çıkış” sonrası eski cihaz gerçekten çıkmış.
- [ ] Biyometrik giriş (Ayarlar) açıkken parmak izi/yüz ile açılıyor.

### Girişlerde ortak kontrol
- [ ] Klavye alanları kapatmıyor; kaydet/ileri butonu klavyenin ardında kalmıyor.
- [ ] Şifre göster/gizle çalışıyor.
- [ ] Alanlar boşken “kaydet” → **uyarı veriyor** (sessiz kalmıyor).

---

## 2. Notlar (klasör/arşiv/kilit/editör — çok detaylı)

### Pano (mantar pano)
- [ ] BUGÜN listesinde **yalnızca kategorisiz, sabitlenmemiş** notlar var (klasör/arşiv/sabit tekrarı yok).
- [ ] Sabitlenenler ipte doğru görünüyor.
- [ ] Klasörler ipte mandallı; kart ⋯ menüsü (Düzenle · Kilitle · Sil) çalışıyor.
- [ ] Kilitli klasör kartında kilit ikonu var.

### Editör
- [ ] Yazarken içerik yukarı kayıyor, imleç araç çubuğunun ardında kalmıyor.
- [ ] Checkbox eklerken görünür kalıyor.
- [ ] Kalın/italik: `**..**` ve `*..*` canlı render, işaretçiler **görünmüyor**.
- [ ] `+` menüsü **hizalı** açılıyor, sayfa kaymıyor, dışarı dokununca kapanıyor.
- [ ] Kamera/Fotoğraf/Dosya/Çizim/Tarama/Hatırlatıcı/Paylaş çalışıyor.
- [ ] Sesli dikte metni ekliyor.
- [ ] “Bitti” → kaydedip kapanıyor.

### Kilit
- [ ] Kilitli nota **dokununca** PIN → açılır, **çıkınca kilitli kalır**.
- [ ] ⋯ menü → “Notun kilidini aç” → **kalıcı** açılır.
- [ ] Yanlış PIN → uyarı, açılmaz.

### Klasör
- [ ] Klasör oluştur → panoda görünür.
- [ ] Klasöre dokun → dosya görünümü (kâğıt yaprakları) açılır.
- [ ] Klasörü kilitle → açışta PIN sorar.

### Arşiv
- [ ] Arşiv kutusuna gir → çerçeveli mantar pano, notlar raptiyeli.
- [ ] ⋯ → “Arşivden Çıkar” çalışıyor.

### Performans/uç durumlar
- [ ] 50+ not varken pano/liste **akıcı** (kasma yok).
- [ ] Çok uzun başlık/içerik taşmıyor (ellipsis).
- [ ] Emoji / çok dilli karakter / `*` `_` içeren metin bozulmuyor.
- [ ] Not yok durumunda boş-durum ekranı düzgün.

---

## 3. Görevler

- [ ] Görev ekle (başlık boşken **uyarı**).
- [ ] Tamamla/geri al (sol işaret), düzenle (başlık/kalem).
- [ ] Açıklama satırı yalnızca gerçekten görünen durumları gösteriyor (· görev / × bitti / ! gecikti).
- [ ] “Gecikenleri bugüne taşı” çalışıyor.
- [ ] “Tüm Görevler” sayfası (gecikmiş/bugün/yaklaşan/tarihsiz/tamamlanan) doğru gruplar.
- [ ] Doğal dil (“yarın 15:00 toplantı”) ayrıştırma doğru.
- [ ] Alt görev, tekrar, hatırlatıcı, kategori çalışıyor.
- [ ] Çok görev varken liste akıcı.

---

## 4. Alışkanlıklar

- [ ] Alışkanlık ekle (ad boşken **uyarı**); kaydedince **sayfa kapanıyor** ve listede görünüyor.
- [ ] Yaşam alanı (İlişkiler/Öğrenme/Zihin/Sağlık) doğru grupluyor; donut doğru.
- [ ] Tamamla/artır (checkbox); seri (streak) güncelleniyor.
- [ ] Tekrar “Özel” seçilince gün çemberleri çıkıyor; Her gün/Haftalık’ta gizli.
- [ ] Hedef + Sıklık + Hatırlatıcı + Başlangıç ayarlanıyor.
- [ ] ⋯ menü: Geçmiş (ısı haritası), Düzenle, **Arkadaşınla paylaş** (kod üretir), Atla, Sil.
- [ ] Paylaşımlı: kod ile katıl, lider tablosu.

---

## 5. Takvim

- [ ] Ay / Hafta / Gün / Ajanda görünümleri geçişleri sorunsuz.
- [ ] “Bugün” butonu bugüne döner.
- [ ] Etkinlik ekle (başlık boşken **uyarı**), düzenle, sil.
- [ ] Gün noktaları doğru renkte; **açıklama (İş/Kişisel/Sağlık/Diğer) tüm kategorileri** kapsıyor.
- [ ] Tür (Toplantı/Hatırlatıcı/…) + Kategori (renk) birlikte doğru.
- [ ] Tekrar + hatırlatıcı (dakika/zaman) çalışıyor.
- [ ] Ay değiştirme (ileri/geri) akıcı.

---

## 6. Finans

- [ ] Gelir / Gider ekle (tutar boş/0 → **uyarı**).
- [ ] Abonelik ekle (ad/tutar/ödeme günü boşsa **uyarı**).
- [ ] **Para birimi değiştir → çökme/boş ekran YOK** (tutarlar güncelleniyor).
- [ ] Hesap carousel (Ana/Abonelik/Taksit/Tasarruf) kaydırması akıcı.
- [ ] Genel/Harcama/Plan sekmeleri doğru veriler.
- [ ] “Kilitle” → PIN yoksa **kilit kurulumu** açar (bütçe ayarları değil).
- [ ] Bütçe / kategori bütçesi / borç / taksit ekleme-düzenleme.
- [ ] Gider dağılımı / grafik doğru oranlar.

---

## 7. Profil & Ayarlar

- [ ] Profili düzenle (ad/foto/kapak) kaydediyor.
- [ ] Hesap bilgileri (e-posta, üyelik tarihi, tür) doğru; şifre değiştir çalışıyor.
- [ ] İstatistikler doğru etiketli (ör. “Oluşturulan not · X · Y **kilitli**”).
- [ ] Tema değiştir (Profil) → anında uygulanıyor; Ayarlar ile çelişmiyor.
- [ ] Dil değiştir → tüm ekranlar seçilen dile geçiyor.
- [ ] Bildirim anahtarları (Tümü + alt türler) çalışıyor.
- [ ] Verileri dışa aktar (JSON) üretiyor.
- [ ] **Hesabı sil** → onay + gerçekten siliyor (dikkatli test et!).
- [ ] Çıkış yap → giriş ekranına döner.

---

## 8. Ana ekran widget’ları (Not / Finans / Takvim)

- [ ] 3 widget da ana ekrana eklenebiliyor.
- [ ] Arka plan **glass/saydam**, metin okunur (açık ve koyu duvar kâğıdında dene).
- [ ] İçerik güncel (not/işlem/etkinlik eklenince widget yenileniyor).
- [ ] Not widget önizlemesinde ham `**` / `*` / işaretler **görünmüyor**.
- [ ] Widget’a dokununca ilgili ekran açılıyor.
- [ ] Widget’ı yeniden boyutlandırma bozulmuyor.

---

## 9. Bildirimler & Hatırlatıcılar

- [ ] İzin isteme akışı (ilk açılış) düzgün.
- [ ] Görev/alışkanlık/etkinlik hatırlatıcısı **gerçek cihazda** doğru zamanda geliyor.
- [ ] Bildirime dokununca doğru ekran açılıyor.
- [ ] Zaman dilimi / GMT+3 kaymaları yok (hatırlatıcı yanlış saatte gelmiyor).
- [ ] Uygulama kapalıyken de bildirim geliyor.

### Bildirim dili (seçili dilde gelmeli) — **mimari denetlendi, çalışıyor**

> Akış: Dil değiştir → istemci `preferred_language`’ı sunucuya yollar →
> sunucu kullanıcıda saklar → `FirebaseNotificationService` her bildirimi
> `__('notifications.x', [], localeFor(user))` ile o dile çevirir. Sunucuda
> 11 dilin `lang/<dil>/notifications.php` dosyaları mevcut (eşit anahtar).
> **Yine de gerçek cihazda uçtan uca doğrula:**

- [ ] Dili **Türkçe** yapıp görev/alışkanlık hatırlatıcısı → bildirim **Türkçe**.
- [ ] Dili **İngilizce** yapıp tekrar → bildirim **İngilizce**.
- [ ] En az 2-3 dili daha (de/ar/ja vb.) dene → başlık o dilde; gövde kullanıcı metni (ör. görev adı) olduğu gibi.
- [ ] Dil değiştirince **yeni dil sunucuya yansıyor** (çıkış/giriş gerektirmeden bir sonraki bildirim yeni dilde).
- [ ] Abonelik/bütçe/seviye/başarı bildirimleri de seçili dilde.
- [ ] Çok cihaz: başka cihazda dil farklıysa her cihaz kendi diline göre değil, **kullanıcı tercihine** göre gelir (beklenen davranış teyit).
- [ ] RTL dilde (Arapça) bildirim metni düzgün görünüyor.

---

## 10. İlk açılış (onboarding) & Dil seçimi

- [ ] İlk kurulumda dil seçimi → onboarding → giriş akışı sorunsuz.
- [ ] Onboarding’de **tanıtılan her özellik gerçekten uygulamada var** (hayali özellik yok).
- [ ] Onboarding atlanabiliyor / tamamlanınca bir daha çıkmıyor.

---

## 11. Donma / Kasma / Bellek (performans)

- [ ] Uzun listelerde (not/görev/işlem) kaydırma 60fps hissinde, takılma yok.
- [ ] Sayfa/sekme geçişleri ve bottom-sheet açılışları akıcı.
- [ ] Ağır işlemler (dışa aktarma, çok veri yükleme) **UI’yi dondurmuyor** (spinner var).
- [ ] Hızlıca birçok sekme arasında geçiş → çökme/“disposed” hatası yok.
- [ ] Uygulamayı uzun süre açık bırak (10+ dk) → yavaşlama/bellek şişmesi yok.
- [ ] Arka plandan öne alma (multitask) → ekran korunuyor, yeniden yüklenmiyor/donmuyor.
- [ ] Düşük/orta donanımlı bir cihazda da akıcı.

---

## 12. Çevrimdışı / Ağ / Hata durumları

- [ ] İnternet yokken ekranlar boş/çökme yerine anlamlı mesaj gösteriyor.
- [ ] İstek sırasında internet kesilince → hata mesajı, tekrar deneme mümkün.
- [ ] Yavaş ağ (throttle) altında spinner takılı kalmıyor.
- [ ] Sunucu 500/401 dönerse uygulama çökmüyor.
- [ ] Çevrimiçi olunca veriler senkronlanıyor.

---

## 13. İzinler (permissions)

- [ ] Kamera / galeri (not fotoğrafı, profil foto) izni + reddedilince davranış.
- [ ] Mikrofon (sesli dikte / sesli not) izni.
- [ ] Bildirim izni.
- [ ] Depolama / dosya seçici.
- [ ] İzin reddedildiğinde uygulama çökmüyor, kullanıcı yönlendiriliyor.

---

## 14. Yerelleştirme & Metin (11 dil)

> **Denetlendi:** 11 dil dosyasının (ar, de, en, es, fr, hi, ja, pt, ru, tr, zh)
> hepsinde **tam 1289 anahtar** var; eksik anahtar / boş değer **yok**. Sunucu
> tarafı `lang/<dil>/notifications.php` dosyaları da 11 dilde eşit anahtarlı.

- [ ] Dilleri tek tek değiştir: eksik çeviri / anahtar (ör. `errors.xxx`) ham görünmüyor.
- [ ] Uzun çeviriler (Almanca/Fransızca) butonlara/kartlara sığıyor, taşmıyor.
- [ ] **RTL (Arapça)**: yön doğru, hizalama bozulmuyor.
- [ ] Tarih/saat/sayı/para birimi biçimi seçili dile uygun.
- [ ] Çince/Japonca/Hintçe karakterler düzgün render.
- [ ] Çeviri **kalitesi** gözden geçirildi (otomatik/makine çevirisi hataları, bağlama uymayan kelimeler).

**Anahtar bütünlüğünü her sürümde yeniden doğrulamak için** (proje kökünde çalıştır):

```bash
python - <<'PY'
import json, glob, os
def fl(d,p=''):
    o={}
    for k,v in d.items():
        key=f"{p}.{k}" if p else k
        o.update(fl(v,key) if isinstance(v,dict) else {key:v})
    return o
files=sorted(glob.glob('assets/translations/*.json'))
ks={f:set(fl(json.load(open(f,encoding='utf-8')))) for f in files}
allk=set().union(*ks.values())
for f in files:
    miss=allk-ks[f]
    empt=[k for k,v in fl(json.load(open(f,encoding='utf-8'))).items() if isinstance(v,str) and not v.strip()]
    print(os.path.basename(f), 'eksik:', len(miss), 'boş:', len(empt))
PY
```

---

## 15. Tema & Görsel tutarlılık

- [ ] Açık/Koyu/Sistem temasında tüm ekranlar okunaklı (düşük kontrast yok).
- [ ] Renk paleti modüller arası tutarlı.
- [ ] İkonlar/boş durumlar/animasyonlar bozulmuyor.
- [ ] Farklı ekran boyutları: küçük telefon, büyük telefon, (varsa) tablet.
- [ ] Çentik/alt çubuk güvenli alanlarına taşma yok.

---

## 16. Premium / Satın alma (varsa aktif)

- [ ] Premiumsuz tüm temel özellikler kullanılabiliyor (limit kaldırıldıysa teyit).
- [ ] Satın alma akışı (test hesabı) → çökme yok.
- [ ] Satın almayı geri yükle çalışıyor.
- [ ] Faturalama yoksa (emülatör) uygulama çökmüyor, uyarı veriyor.

---

## 17. Veri bütünlüğü & senkron

- [ ] A cihazında ekle → B cihazında/yeniden girişte görünüyor.
- [ ] Aynı anda düzenleme / hızlı tekrar dokunma çift kayıt oluşturmuyor.
- [ ] Sil → onay → gerçekten silindi, geri gelmedi.
- [ ] Arşiv/kilit/sabitle durumları yeniden açılışta korunuyor.
- [ ] Para birimi / tema / dil tercihleri kalıcı.

---

## 18. Mağaza / yayın hazırlığı (teknik)

- [ ] Uygulama ikonu, adı, splash doğru.
- [ ] Sürüm kodu/numarası artırıldı.
- [ ] `release` (debug değil) derlemede test edildi.
- [ ] ProGuard/R8 sonrası çökme yok (release’de API çağrıları çalışıyor).
- [ ] Gizlilik politikası / kullanım şartları linkleri **gerçek cihazda** açılıyor.
- [ ] Çökme raporlama (varsa Crashlytics vb.) çalışıyor.
- [ ] Gereksiz log/konsol çıktısı release’de kapalı.
- [ ] İzin açıklamaları (iOS Info.plist / Android manifest) eksiksiz ve anlamlı.

---

## Bu sürümde özel olarak **regresyon** test edilmesi gerekenler
_(Bu oturumda düzeltilen noktalar — tekrar bozulmadığını doğrula)_

- [ ] Alışkanlık: ad boşken uyarı + kaydedince sayfa kapanma + kategori hatası yok.
- [ ] Finans: zorunlu alan uyarıları görünür; **para birimi değişince çökme yok**.
- [ ] Finans: “Kilitle” → kilit kurulumu açılıyor (bütçe değil).
- [ ] Notlar: BUGÜN yalnızca kategorisiz notlar; kilit dokun=geçici / menü=kalıcı.
- [ ] Notlar: kalın/italik işaretçileri gizli; `+` menü hizalı.
- [ ] Klasör menüsü her yerde aynı (Düzenle/Kilitle/Sil).
- [ ] Takvim açıklamasında “Diğer” kategorisi var.
- [ ] Görev açıklamasında “taşındı” yok.
- [ ] Profil “Oluşturulan not” etiketi “kilitli”; tema tek yerde.
- [ ] Widget’lar glass/saydam ve metin okunur.

---

### Sorun bulunca not formatı

```
[Modül] Kısa başlık
Cihaz / sürüm:
Adımlar: 1) ... 2) ...
Beklenen:
Gerçekleşen:
Ekran görüntüsü / log:
Öncelik: Kritik / Yüksek / Orta / Düşük
```
