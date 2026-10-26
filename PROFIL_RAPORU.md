# 👤 Profil Modülü — İnceleme Raporu

> LifeSync (com.aedev.kisisel) — Profil (Profil) + bağlı Ayarlar ekranı. Finans / Notlar / Görevler / Takvim raporlarıyla aynı desende: rakip analizi + mevcut envanter + tutarsızlıklar + eklenebilir/çıkarılabilir + fazlı yol haritası.
> Tarih: 2026-10-25. Kod tabanı: istemci `C:\PYTHON-PROJELER\kisisel_mobil\kisisel_mobil`. Backend sadece sunucuda (uçlar istemci çağrılarından geri-türetildi).

---

## 1. Yönetici özeti

Profil ekranı **görsel ve oyunlaştırma (gamification) açısından zengin** (seviye/XP/seri/rozetler, arkadaşlar, istatistikler) **ama çekirdek "hesap" işlevleri ya eksik ya da sahte**:

- 🔴 **Profil düzenleme HİÇ çalışmıyor.** "Düzenle" butonu ve profildeki tüm satırlar aslında sadece Ayarlar ekranını açıyor. `updateProfile` metodu + `PUT /profile` ucu **kodda var ama UI'dan hiçbir yer çağırmıyor** — ad/kullanıcı adı/bio düzenleyecek bir form hiçbir yerde yok.
- 🔴 **"Çıkış Yap" satırı çıkış yapmıyor** — o da sadece Ayarlar'ı açıyor (`_settingsRow` tüm satırları etikete bakmadan `SettingsRoute`'a gidiyor).
- 🔴 **E-posta hiç gösterilmiyor/düzenlenmiyor.** Gizlilik ayarları (`profile_visibility`, `show_level/achievements/habits`) backend'de hazır ama **editörü yok**.
- 🟡 **Tema ve dil backend'e senkronlanmıyor** (yalnızca cihazda). Bildirim modelinde 7 bayrak var, UI sadece 4'ünü gösteriyor. Biyometrik/uygulama kilidi bölümü **yorum satırına alınmış** (devre dışı).
- 🟡 Bir sürü **placeholder**: QR kodu → "çok yakında" snackbar'ı; "Yedekleme: Açık" sabit yazı; `↑%12` sabit trend; hedefler sabit (`taskGoal=10`, `%30`); takip et/bırak butonları boş fonksiyon (`() {}`).
- 🟢 **Güçlü yanlar:** oyunlaştırma (seviye/XP/seri/başarımlar), arkadaş sistemi (istek/arama/kabul), avatar yükleme, istatistik sekmesi, premium paywall, çoklu dil, yasal linkler, hesap silme (Ayarlar'da).

Bu, önceki modüllerdeki **"backend hazır ama UI bağlı değil / yerel kalmış / placeholder"** kalıbının profildeki tekrarı — üstelik burada etkisi daha görünür çünkü kullanıcı adını bile değiştiremiyor.

---

## 2. Rakip analizi — kullanıcılar profilde ne bekliyor?

| Özellik | Sektör beklentisi | Bizde durum |
|---|---|---|
| **Profil düzenleme (ad/kullanıcı adı/bio/foto)** | Her profil ekranının çekirdeği; kişiselleştirme merkezi | 🔴 Düzenleme UI'ı YOK (backend `PUT /profile` hazır ama çağrılmıyor) |
| **Avatar + kapak foto** | Standart | 🟡 Avatar ✓; kapak foto kodu hazır ama **UI'dan erişilemez** |
| **Uygulama-içi hesap silme** | **ZORUNLU** (Apple 2022+, Google 2023 sonu+): tüm hesap+veri silinmeli | 🟢 Var (Ayarlar'da) — ⚠️ Google ayrıca **web silme linki** istiyor (yok); şifre onayı yok |
| **Veri dışa aktarma (GDPR portability)** | Olgun uygulamalarda yaygın/beklenen | ❌ Yok |
| **Gizlilik kontrolleri (profil görünürlüğü, neyi göster)** | Sosyal özellikli uygulamalarda standart | 🔴 Backend hazır (`profile_visibility`, `show_*`), editör yok |
| **Oyunlaştırma (seviye/XP/seri/rozet)** | Alışkanlık uygulamalarında güçlü bağlılık aracı | 🟢 **Güçlü yanımız** — hepsi var ve gösteriliyor |
| **Tema (açık/koyu) + dil** | Standart; genelde hesaba senkronlu | 🟡 Çalışıyor ama **yalnızca cihazda** (senkron yok) |
| **Hesap güvenliği (şifre değiştir, biyometrik/PIN, 2FA)** | Standart | 🔴 Şifre değiştirme yok; biyometrik bölümü yorumda |
| **Bildirim tercihleri (ayrıntılı)** | Standart | 🟡 7 türden sadece 4'ü açık |
| **Takip et / takipçi (sosyal)** | Sosyal uygulamalarda | 🔴 Backend+servis hazır, UI **boş fonksiyon** (çalışmıyor) |
| **Yardım/SSS, hakkında, geri bildirim** | Standart | 🟡 Satırlar var ama hedef sayfa yok (Ayarlar'a gidiyor) |

**Çıkarım:** En büyük açıklar (profil düzenleme, gizlilik, takip) için **backend + servis + model ZATEN hazır** — sadece UI bağlanmamış. Yani çoğu iş "yeni özellik" değil, "var olanı bağlama/tamamlama". Oyunlaştırma güçlü yanımız; onu koruyup çekirdek hesap işlevlerini tamamlamalıyız. Hesap silme web linki ise bir **mağaza uyumluluk** maddesi.

**Kaynaklar:** [UXPin — Profile Page UI best practices](https://www.uxpin.com/studio/?p=50781) · [Eleken — profile page design](https://www.eleken.co/blog-posts/profile-page-design) · [SAP Fiori — Profile & Settings pattern](https://www.sap.com/design-system/fiori-design-android/v26-4/patterns/profile-and-settings/usage) · [Google Play — app account deletion requirement](https://support.google.com/googleplay/android-developer/answer/13327111) · [Ketch — in-app account deletion (Apple/Google)](https://www.ketch.com/blog/in-app-account-deletion) · [AlternativeTo — Habitica (RPG gamification)](https://www.alternativeto.net/software/habitica/about/)

---

## 3. Mevcut envanter — bizde ne var?

**Dosyalar:** `lib/presentation/profile/` (view 2229 satır — 3 sekme: İstatistik/Başarımlar/Arkadaşlar; viewmodel 531 satır; `user_profile_bottom_sheet.dart`). Ayarlar ayrı ekran (`lib/presentation/settings/`, 1623+569 satır). Servisler: `profile_service.dart`, `settings_service.dart`, `social_service.dart`, `gamification_service.dart`. Model `User`+`UserLevel` (`auth_models.dart`), `ProfileUpdateRequest`/`ProfileStats`/`Settings` (`settings_models.dart`).

**Profil ekranı gösteriyor:** avatar (+ kamera overlay ile yükleme), displayName, @username, doğrulama rozeti, "üyelik tarihi", seviye/XP/ilerleme çubuğu/seri, 3'lü istatistik (arkadaş/rozet/aktif gün). Sekmeler: İstatistik (bu ay kartları + kişisel hedefler + ayar satırları), Başarımlar (kilitli/açık/ilerleme), Arkadaşlar (arama/istek/liste).

**Backend uçları (geri-türetilmiş):** `GET/PUT /profile`, `POST /profile/avatar`, `POST /profile/cover`, `GET /profile/stats`, `DELETE /profile`; `GET/PUT /settings`; `/auth/logout`, `/auth/logout-all`; `/social/*` (arkadaş/takip/arama/profil); `/gamification/level`, `/gamification/achievements`.

**User modeli alanları:** id, username✓, email(gizli), displayName✓, bio(sadece başkasının profilinde), profilePictureUrl✓, coverImageUrl(gizli), preferredLanguage(gizli), isGuest, isVerified✓, subscriptionType/Status, profileVisibility, showLevel/showAchievements/showHabits, level✓, createdAt✓. (Telefon/doğum günü/cinsiyet/ülke YOK.)

---

## 4. Tutarsızlıklar & ölü kod (EN ÖNEMLİ bölüm)

### 🔴 Kritik (çalışmayan çekirdek işlev)
1. **Profil düzenleme erişilemez.** `ProfileViewModel.updateProfile` (username/displayName/bio) → `PUT /profile` **UI'dan hiç çağrılmıyor**; "Düzenle" butonu `SettingsRoute` açıyor; Ayarlar'da da ad/kullanıcı adı/bio formu yok. → Kullanıcı adını/bio'sunu değiştiremiyor.
2. **"Çıkış Yap" satırı çıkış yapmıyor.** Stats sekmesindeki tüm `_settingsRow` öğeleri (Hesap bilgisi, Bildirimler, Görünüm, Gizlilik, Yedekleme, Yardım, Hakkında **ve Çıkış**) etikete bakmadan `SettingsRoute`'a gidiyor.
3. **E-posta hiç gösterilmiyor/düzenlenmiyor.** `profileVisibility` + `showLevel/showAchievements/showHabits` backend'de var, **editörü yok** (gizlilik kontrolü yok).
4. **Takip (follow) özelliği sahte.** `UserProfileBottomSheet` `onFollow`/`onUnfollow` boş fonksiyon `() {}`, `isFollowing` sabit `false`; servis (`/social/follow`...) + takipçi/takip-edilen uçları hazır ama **UI bağlı değil**. Doğrulama rozeti de herkese sabit gösteriliyor.

### 🟡 Orta (yerel kalmış / yarım)
5. **Tema yalnızca cihazda** (`ThemeProvider`) — `Settings.darkMode/themeColor` modelde var ama hiç yazılmıyor. **Dil değişince** `User.preferredLanguage`/`Settings` **backend'e senkronlanmıyor** (sadece bütçe para birimi güncelleniyor).
6. **Bildirim: 7 türden 4'ü.** `subscriptionNotifications`, `noteNotifications`, `socialNotifications` modelde var ama UI'da yok.
7. **Biyometrik/uygulama kilidi bölümü yorum satırında** (`settings_view.dart` l.213–241). `requireBiometric`, `autoLockTimeout`, `firstDayOfWeek`, `dateFormat`, `timeFormat` modelde + güncelleme metodu var ama **hiçbir UI set etmiyor**.
8. **Kapak fotoğrafı erişilemez.** `updateCoverImage` → `POST /profile/cover` tam yazılmış ama `_showImageSourceDialog` hep `isCover:false` çağrılıyor ve kapak hiçbir yerde gösterilmiyor.
9. **Hesap silme şifre onayı yok** — `deleteAccount` hep `password: null` ile çağrılıyor.

### ⚪ Placeholder / temizlik
10. QR kodu butonu → sadece `profile.qrComingSoon` snackbar'ı.
11. Sabit kodlu değerler: `↑%12` trend (l.740), `taskGoal=10` (l.662), tasarruf hedefi `%30` (l.879), "Yedekleme: Açık" (l.901).
12. Orphan çeviri anahtarları: `profile.stats.*` çoğu kullanılmıyor; `settings.security.*` yorumdaki bölüm yüzünden sahipsiz; `profile.friends.follow/unfollow` (sahte özellik).
13. `UserLevel.longestDailyStreak` parse ediliyor ama gösterilmiyor. Followers/following modellenip servis ediliyor ama profilde yüzeye çıkmıyor.

---

## 5. Neler eklenebilir / çıkarılabilir

**Eklenebilir (çoğu "var olanı bağlamak", değer sırasına göre):**
- ✅ **Profil düzenleme formu** (ad/kullanıcı adı/bio + e-posta göster) — `updateProfile`/`PUT /profile` **zaten hazır**, sadece ekran+bağlantı. **En yüksek öncelik.**
- ✅ "Çıkış Yap" satırını gerçekten çıkış yaptır; placeholder satırları gerçek hedeflere bağla veya kaldır.
- ✅ Gizlilik kontrolleri (profil görünürlüğü + neyi göster) — backend hazır.
- ✅ Tema + dili backend'e senkronla; 7 bildirim türünü de aç.
- ✅ Biyometrik/uygulama kilidini aç (yorumdan çıkar + bağla).
- 🔸 Tercihler (haftanın ilk günü, tarih/saat biçimi) — model hazır.
- 🔸 Veri dışa aktarma (GDPR); hesap silme için web linki (Google zorunluluğu) + şifre onayı.
- 🔸 Takip özelliğini bağla **veya** kaldır; kapak fotoğrafı UI'ı **veya** kaldır.

**Çıkarılabilir:** QR "çok yakında" (ya uygula ya kaldır); sabit trend/hedef yazıları; sahte takip no-op'ları; orphan çeviri anahtarları; yorumdaki güvenlik bölümü (ya aktifleştir ya sil); erişilemeyen kapak yolu (ya bağla ya sil).

---

## 6. Önerilen fazlı yol haritası

**Faz 0 — Temizlik:** QR placeholder, sabit trend/hedef yazıları, sahte takip no-op'ları, orphan çeviri anahtarları, erişilemeyen kapak yolu ve yorumdaki güvenlik bloğu için karar (bağla/sil). Düşük risk.

**Faz 1 — Profil düzenleme (çekirdek):** Ad/kullanıcı adı/bio düzenleme formu (avatar zaten var) → `updateProfile`/`PUT /profile` bağla; e-postayı göster; "Çıkış Yap" satırını gerçekten çıkış yaptır; placeholder satırları doğru hedeflere yönlendir. **Backend hazır, çoğunlukla UI işi.**

**Faz 2 — Gizlilik & tercih senkronu:** Profil görünürlüğü + `show_level/achievements/habits` toggle'ları; tema + dili `/settings`+`User`'a senkronla; 7 bildirim türünü aç; biyometrik/uygulama kilidini aktifleştir.

**Faz 3 — Uyumluluk & sosyal cila:** Veri dışa aktarma (GDPR); hesap silme şifre onayı + web silme linki; takip özelliğini bağla veya kaldır; kapak fotoğrafı UI'ı veya kaldır; takipçi/takip-edilen'i yüzeye çıkar.

---

> **Not:** Önceki modüllerdeki gibi önce bir fazı onayınla uygulayıp doğrularım, push etmem ("güncellemeler bitince ben pushlarım" kuralın geçerli). Önerim: **Faz 1 (profil düzenleme)** — çünkü backend tamamen hazır, en görünür eksik bu ve kullanıcı etkisi en yüksek.
