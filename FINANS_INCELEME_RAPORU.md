# LifeSync — Finans Modülü İnceleme & Rakip Karşılaştırma Raporu

> Tarih: 2026-10-24 · Kapsam: `lib/presentation/finance/*`, `lib/models/budget/*`, `lib/service/{expense,budget,subscription}/*`

---

## 1. Yönetici Özeti

Finans modülü **günlük basit gider notu** için çalışır, ancak **güvenilir bir finans yönetimi için henüz yeterli değil.** Üç ana sorun var:

1. **Veri mimarisi kırık** — gelir, tasarruf ve harcama detayları yalnızca cihazda (SharedPreferences); telefon değişince / uygulama silinince kaybolur, cihazlar arası senkronlanmaz.
2. **İki paralel sistem çelişiyor** — eski ve yeni gider formu + iki ayrı kategori taksonomisi aynı anda kodda; listede yanlış etiket/emoji görünür.
3. **2026 "olmazsa olmaz" özelliklerinin çoğu eksik veya kırık** — çoklu para birimi yok (her şey ₺ sabit), abonelik hatırlatması kapalı, tekrarlayan gider yarım, CSV dışa aktarma yok.

---

## 2. Kod Denetimi — Tutarsızlıklar

### 🔴 Kritik — Veri bütünlüğü

| # | Bulgu | Etki |
|---|-------|------|
| 1 | **Gelir + tasarruf + harcama meta cihazda, harcama/bütçe/abonelik sunucuda** (`finance_income_v1`, `finance_savings_v1`, `expense_meta_v1` → SharedPreferences) | Telefon değişince/silinince gelir, tasarruf hedefi, fiş/etiket/not/ödeme yöntemi **kaybolur**. Çoklu cihazda "Kullanılabilir bakiye" tutarsız. |
| 2 | **Aylık toplam & grafikler yalnızca son 20 harcamadan** hesaplanıyor (`loadExpenses(perPage: 20)`); kategori halkası, 7 günlük çubuk, `monthExpensesTotal` hepsi yerel listeden | Ayda 20+ harcaması olan kullanıcıda bütçe kartı (sunucu, doğru) ile grafikler (eksik) **aynı ekranda çelişir**. |

### 🔴 Kritik — İşlevsellik

| # | Bulgu | Etki |
|---|-------|------|
| 3 | **İki kategori sistemi tutmuyor** — Form: `market, bills, transport, health, other`; Liste/istatistik gösterimi (`getCategoryLabel/Emoji`): `food, transportation, entertainment, shopping, bills, health, education, other` | `market`≠`food`, `transport`≠`transportation` → listede çevrilmemiş ham "market" + genel 💰 emoji. |
| 4 | **Para birimi tamamen sabit** — her kayıt `currency:'TRY'`, tüm UI `₺` (`tl()`/`tl0()`), binlik/ondalık Türk biçimi hardcoded | 11 dilli/global uygulamada ABD/Avrupa kullanıcısı da ₺ görür. Çoklu para birimi işlevsiz. |
| 5 | **Abonelik hatırlatması hiç çalışmıyor** — `reminderEnabled:false` create+update'te sabit | Abonelik takipçisinin asıl amacı (ödemeden önce uyar) devre dışı. |
| 6 | **Tekrarlayan gider yarım** — `isRecurring:true` gönderiliyor ama `recurringPattern:null` sabit | Desen (haftalık/aylık) atılıyor, gider gerçekten tekrarlanmıyor. |

### 🟠 Orta

| # | Bulgu |
|---|-------|
| 7 | **Gider düzenleme veri kaybettiriyor** — `updateExpense` tarihi `DateTime.now()`'a sıfırlıyor, eski kategoriyi gönderiyor, meta'yı güncellemiyor. |
| 8 | **Gelir hiçbir rapora girmiyor** — aylık/yıllık istatistik sunucudan yalnızca gider; net/gelir-gider raporu imkânsız. |
| 9 | **Kategori bazlı bütçe yok** — tek `monthlyBudget`; zarf bütçesi yapılamıyor. |
| 10 | **Silinen giderin meta'sı temizlenmiyor** — yetim fiş/etiket SharedPreferences'ta birikir. |
| 11 | **Sabit GMT+3** — `expense_date` ayrıştırmada +3 saat (İstanbul) sabit; farklı saat diliminde gün kayabilir. |

### 🟡 Küçük
- **12.** Tasarruf hedefi varsayılanı `25000` hardcoded; birikim gerçek gelir-giderle bağsız.
- **13.** Eski (`createExpense`/`updateExpense`) + yeni (`saveFinanceForm`) form birlikte → ölü/çift kod.
- **14.** CSV/PDF dışa aktarma yok.

---

## 3. Rakip Karşılaştırması (2025-2026)

**Not:** Mint kapandı (Mart 2024, Credit Karma'ya katıldı, bütçe özellikleri taşınmadı) — canlı rakip değil, pazar dersi. Yerine Monarch, YNAB, Rocket Money geçti.

### 3.1 Özellik matrisi (ilgili rakipler)

Y=var/çekirdek · P=kısmi/premium · —=yok

| Özellik | YNAB | Monarch | PocketGuard | Rocket Money | Spendee | Money Mgr | Goodbudget | **LifeSync** |
|---|---|---|---|---|---|---|---|---|
| Gelir+gider+kategori | Y | Y | Y | Y | Y | Y | Y | ⚠️ (gelir yerel) |
| Bütçe yöntemi | Sıfır-tabanlı | Flex/kategori | Safe-to-spend | Kategori | Kategori/cüzdan | Kategori | Zarf | ⚠️ tek aylık sınır |
| Manuel giriş birinci sınıf | Y | P | P | — | Y | **Y** | **Y** | **Y** |
| Banka senkronu | Y | Y | Y | Y | P | — | — | — (bilinçli) |
| Abonelik takibi | P | Y | Y | **Y (iptal eder)** | — | — | — | ⚠️ var ama hatırlatma kapalı |
| Tekrarlayan işlem | Y | Y | Y | Y | Y | Y | P | ❌ yarım |
| Çoklu para birimi | P(zayıf) | P | — | — | **Y** | P | — | ❌ ₺ sabit |
| Rapor/grafik/trend | Y | **Y(en iyi)** | P | Y | Y | Y | P | ⚠️ gelirsiz, eksik |
| Net değer takibi | Y | Y | P | Y | — | Y | — | — |
| Borç ödeme planı | Y | P | **Y(kar topağı/çığ)** | Y | — | P | — | — |
| Tasarruf hedefi | Y | Y | Y | Y | P | P | P | ⚠️ yerel, bağsız |
| Paylaşımlı/aile bütçesi | Y(6) | **Y(bayrak)** | — | — | Y(prem) | — | **Y(çekirdek)** | — |
| CSV/PDF dışa aktar | Y | Y | P | P | Y | P | Y | ❌ |
| Hatırlatma/bildirim | Y | Y | Y | Y | Y | Y | Y | ⚠️ kapalı |
| Güvenlik kilidi | Y | Y | Y | Y | Y | **Y(satış arg.)** | Y | ? (not kilidi var) |
| Para kazanma | Abonelik | Abonelik | Freemium | Freemium | Freemium | Reklam+IAP | Freemium | RevenueCat ✓ |

### 3.2 En yakın benzerler
- **Money Manager (Realbyte)** ve **Goodbudget** — ikisi de **banka senkronu YOK, manuel-öncelikli, abonelikle para kazanır.** LifeSync'in felsefi ikizleri; manuel girişin bir sınırlama değil, kasıtlı tercih olarak konumlanabileceğinin kanıtı.
- **Rocket Money** — abonelik takibinin lideri (ama gerçek iptal için banka senkronu+insan ajan gerekir; LifeSync'in ulaşabileceği dilim: **yenileme hatırlatması + yıllık maliyet farkındalığı**).

---

## 4. "Yeterli mi?" — Table-Stakes Kontrolü

2026'da ciddi bir finans modülünün olmazsa olmazları ve LifeSync'in durumu:

| Olmazsa olmaz | LifeSync | Not |
|---|---|---|
| Gelir+gider+kategori | ⚠️ | Gelir sunucuda değil → kırık kalıcılık |
| Açık bütçe yöntemi (kategori+aylık, görsel ilerleme) | ⚠️ | Yalnız tek aylık sınır |
| Tekrarlayan işlemler | ❌ | Desen atılıyor |
| Rapor/analiz (kategori + trend) | ⚠️ | Gelirsiz; yerel grafik eksik sayıyor |
| Çoklu para birimi (lira için kritik) | ❌ | ₺ sabit |
| Güvenlik kilidi (biyometrik/şifre) | ⚠️ | Not kilidi var, finans bölümü kilidi doğrulanmalı |
| Hatırlatma/bildirim | ❌ | Abonelik hatırlatması kapalı |
| CSV dışa aktarma | ❌ | Yok (Mint dersi: veri taşınabilirliği güven verir) |

**Sonuç:** Çoğu olmazsa olmazda eksik veya kırık. Önce mevcut tutarsızlıkları düzeltmeden yeni özellik eklemek teknik borcu büyütür.

---

## 5. Önceliklendirilmiş Yol Haritası

### Faz 0 — Önce kırıkları düzelt (tutarsızlıklar; yeni özellik yok)
1. **Geliri backend'e taşı** (veya hesaba bağlı senkronlu sakla) → veri kaybını ve cihazlar-arası tutarsızlığı bitir. *(Backend'de income modeli gerekir.)*
2. **Tek kategori sistemi** — eski `getCategoryLabel/Emoji/Color`'ı yeni `kFinCats` ile birleştir; `market/transport` çevirileri düzelsin.
3. **Aylık toplam & grafikleri backend'den al** (20-öğe bug'ını bitir) veya tüm ayın harcamasını çek.
4. **Abonelik hatırlatmasını aç** (`reminderEnabled` kullanıcıya bağla + bildirim zamanla).
5. **Tekrarlayan deseni gönder** (`recurringPattern`) ve backend'de gerçekten tekrarlat.
6. **`updateExpense` tarih sıfırlama + meta kaybı** düzelt; silmede meta temizle.

### Faz 1 — Table-stakes'i tamamla
7. **Çoklu para birimi** — temel para birimi ayarı + diğer kur girişi; `tl()` yerine locale-aware `NumberFormat.currency`.
8. **CSV dışa aktarma** — ucuz, yüksek güven değeri.
9. **Kategori bazlı bütçe** — zarf/kategori limitleri + görsel ilerleme.
10. **Bütçe aşımı & ödeme hatırlatma bildirimleri.**
11. **Finans bölümü kilidi** — mevcut not-kilidi altyapısını genişlet.

### Faz 2 — Fark yaratanlar (banka senkronu gerektirmeyen, yüksek değer)
12. **Borç ödeme planlayıcı** (kar topağı/çığ) — saf matematik, manuel veriyle tam uygulanabilir (PocketGuard'ın en sevilen özelliği).
13. **Tasarruf hedefleri** — uygulamanın goal/habit modülüyle entegre.
14. **"Safe-to-spend" tek sayı** — manuel veriden hesaplanabilir güçlü UX kancası.
15. **Taksit takibi** — Türkiye'ye özel, global uygulamaların boşluğu.
16. **Hızlı ekleme widget'ı + fiş tarama** — manuel girişte sürtünmeyi azaltır (terk oranı için kritik).
17. **Recurring/abonelikleri paylaşılan takvimde göster** — all-in-one avantajını kullan.

### ❌ Atlanabilir (maliyet yüksek, all-in-one için affedilir)
- Banka senkronu (pahalı, kırılgan, Türk bankaları kapsamı zayıf — manuel giriş zaten bu pazara uygun)
- Yatırım/portföy takibi · Fatura pazarlığı/oto-iptal · Gerçek çok-kullanıcılı bütçe · Kredi skoru · Sankey düzeyinde ileri raporlama

---

## 6. Stratejik Çerçeve

LifeSync'in avantajı YNAB'ı bütçelemede yenmek değil — **finansın notlar/görevler/takvim/günlük ile yan yana yaşaması.** Banka senkronu gerektirmeyen ve bu entegrasyonu kullanan kazanımlara odaklan: paylaşılan takvimde abonelik/tekrar hatırlatmaları, kişisel hedeflerle tasarruf hedefleri, borç planlayıcı, sürtünmesiz hızlı ekleme, Türk pazarı için sağlam çoklu para birimi + taksit. **Manuel girişi bir eksiklik değil, kasıtlı sadelik olarak konumla** (Goodbudget/Money Manager modeli).
