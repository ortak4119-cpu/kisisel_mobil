# iOS Ana Ekran Widget'ı Kurulumu (WidgetKit)

Android widget'ı hazır ve çalışıyor. iOS widget'ı, Xcode'da bir **Widget Extension target**
eklemeyi gerektirir (bu adım Xcode veya Codemagic'te yapılmalı; koddan güvenli yapılamaz).

Flutter tarafı hazır: `HomeWidget.setAppGroupId('group.com.aedev.kisisel')` ve finans
verisi (`balance`, `spent`, `income`, `balance_label`) `HomeWidget.saveWidgetData` ile yazılıyor.

## Adımlar (Xcode)

1. **Widget Extension ekle:** File → New → Target → **Widget Extension** → adı `FinanceWidget`,
   "Include Configuration Intent" işaretsiz.
2. **App Group ekle:** Hem `Runner` hem `FinanceWidget` target'ına Signing & Capabilities →
   **App Groups** → `group.com.aedev.kisisel` ekle. (App Store Connect / Apple Developer'da da
   bu app group oluşturulmalı.)
3. `FinanceWidget` target'ının Swift dosyasını aşağıdaki kodla değiştir:

```swift
import WidgetKit
import SwiftUI

struct FinanceEntry: TimelineEntry {
    let date: Date
    let balance: String
    let spent: String
    let income: String
    let label: String
}

struct Provider: TimelineProvider {
    let groupId = "group.com.aedev.kisisel"

    func read() -> FinanceEntry {
        let d = UserDefaults(suiteName: groupId)
        return FinanceEntry(
            date: Date(),
            balance: d?.string(forKey: "balance") ?? "—",
            spent: d?.string(forKey: "spent") ?? "—",
            income: d?.string(forKey: "income") ?? "—",
            label: d?.string(forKey: "balance_label") ?? "Balance"
        )
    }

    func placeholder(in context: Context) -> FinanceEntry {
        FinanceEntry(date: Date(), balance: "—", spent: "—", income: "—", label: "Balance")
    }
    func getSnapshot(in context: Context, completion: @escaping (FinanceEntry) -> Void) {
        completion(read())
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<FinanceEntry>) -> Void) {
        let entry = read()
        completion(Timeline(entries: [entry], policy: .atEnd))
    }
}

struct FinanceWidgetEntryView: View {
    var entry: Provider.Entry
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.965, green: 0.761, blue: 0.243),
                                    Color(red: 0.965, green: 0.659, blue: 0.129)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.label).font(.caption).foregroundColor(.white.opacity(0.85))
                Text(entry.balance).font(.title).bold().foregroundColor(.white)
                HStack {
                    VStack(alignment: .leading) {
                        Text("Gider").font(.caption2).foregroundColor(.white.opacity(0.85))
                        Text(entry.spent).font(.subheadline).bold().foregroundColor(.white)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Gelir").font(.caption2).foregroundColor(.white.opacity(0.85))
                        Text(entry.income).font(.subheadline).bold().foregroundColor(.white)
                    }
                }.padding(.top, 8)
            }.padding()
        }
    }
}

@main
struct FinanceWidget: Widget {
    let kind = "FinanceWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FinanceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("LifeSync")
        .description("Finans özeti")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

4. `HomeWidget.updateWidget(iOSName: 'FinanceWidget')` zaten Flutter'da çağrılıyor; widget
   adı `FinanceWidget` ile eşleşmeli.

Not: `com.aedev.kisisel` bundle id'si ve `group.com.aedev.kisisel` app group'u provisioning
profiline eklenmeli (Codemagic'te signing ayarları güncellenmeli).
