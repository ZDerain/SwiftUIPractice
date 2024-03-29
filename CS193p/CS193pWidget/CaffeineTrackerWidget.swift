//
//  CaffeineTrackerWidget.swift
//  CS193p
//
//  Created by WisidomCleanMaster on 2023/8/11.
//

///
/// Button样式可交互小组件

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - CaffeineLog
struct Drink  {
    let name: String
    let caffeine: Measurement<UnitMass>
}

struct CaffeineLog {
    static let CaffeineLogWidgetKind: String = "CaffeineLogWidget"
    static let Drinks = ["牛奶", "绿茶", "卡布奇诺", "脱因咖啡", "鸡尾酒"]
    
    let id: String
    let drink: Drink
    let date: Date
    
    init(drink: String, caffeine: Double, date: Date) {
        self.drink = Drink(name: drink, caffeine: Measurement(value: caffeine, unit: .milligrams))
        self.date = date
        self.id = UUID().uuidString
    }
    
    static func defaultLog() -> CaffeineLog {
        return CaffeineLog(drink: "milk", caffeine: 0.0, date: Date())
    }
}

// MARK: - LastDrinkView

struct LastDrinkView: View {
    let log: CaffeineLog

    var body: some View {
        VStack(alignment: .leading) {
            Text(log.drink.name)
                .bold()
            Text("\(log.date, format: Self.dateFormatStyle) · \(caffeineAmount)")
        }
        .font(.caption)
        .id(log.id)
        .transition(.asymmetric(
            insertion: .move(edge: .leading),
            removal: .scale.combined(with: .move(edge: .trailing))))
    }

    var caffeineAmount: String {
        log.drink.caffeine.formatted()
    }

    static var dateFormatStyle = Date.FormatStyle(
        date: .omitted, time: .shortened)
}

// MARK: - TotalCaffeineView

struct TotalCaffeineView: View {
    let totalCaffeine: Measurement<UnitMass>

    var body: some View {
        VStack(alignment: .leading) {
            Text("当前摄入咖啡因:")
                .font(.caption)
            
            Spacer()
            
            Text(totalCaffeine.formatted())
                .font(.title)
                .minimumScaleFactor(0.8)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.2), value: totalCaffeine)
        }
        .foregroundColor(.brown)
        .bold()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - LogDrinkView
struct LogDrinkView: View {
    var body: some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            let drink = Drink(name: "Espresso", caffeine: .init(value: 13.0, unit: .milligrams))
            
            // Button
            Button(intent: LogDrinkIntent(caffeine: drink.caffeine.value)) {
                Text("再来一杯")
                    .font(.system(size: 14))
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.init(top: 5, leading: 0, bottom: 5, trailing: 0))
                    .foregroundColor(.white)
                    .background(.red)
                    .cornerRadius(5)
            }
        }
    }
}

// MARK: - DrinksLogStore
class DrinksLogStore {
    private static let sharedDefaults: UserDefaults = UserDefaults(suiteName: "tp.tpcleanerpro.pro")!
    private static let TotalCaffeineValueKey = "TotalCaffeineValue"
    public static let shared = DrinksLogStore()
    
    var totalCaffeine: Double {
        Self.sharedDefaults.double(forKey: Self.TotalCaffeineValueKey)
    }
    
    var toggleValue: Bool {
        return Self.sharedDefaults.bool(forKey: "widget.toggle.value")
    }
    
    func log(_ caffeine: Double) async {
        Task {
            let value = self.totalCaffeine + caffeine
            Self.sharedDefaults.setValue(value, forKey: Self.TotalCaffeineValueKey)
        }
    }
    
    func toggle() async {
        Task {
            let isOn = Self.sharedDefaults.bool(forKey: "widget.toggle.value")
            Self.sharedDefaults.setValue(!isOn, forKey: "widget.toggle.value")
        }
    }
}

// MARK: - AppIntentsProvider
struct LogDrinkIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a drink"
    static var description = IntentDescription("Log a drink and its caffeine amount.")
    
    /// 通过button点击事件来传递drink
    @Parameter(title: "Drink caffeine")
    var caffeine: Double

    init() {}

   init(caffeine: Double) {
       self.caffeine = caffeine
   }
    
    func perform() async throws -> some IntentResult {
        /// 更新数据
        await DrinksLogStore.shared.toggle()
        await DrinksLogStore.shared.log(caffeine)
        return .result()
    }
}

// MARK: - CaffeineIntentProvider
struct CaffeineIntentProvider: TimelineProvider {
    
    public typealias Entry = CaffeineLogEntry
    
    
    func placeholder(in context: Context) -> CaffeineLogEntry {
        return CaffeineLogEntry(date: Date(), configuration: LogDrinkIntent(),  totalCaffeine: .init(value: 163, unit: .milligrams), log: CaffeineLog.defaultLog())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CaffeineLogEntry) -> Void) {
        let entry = CaffeineLogEntry(date: Date(), configuration: LogDrinkIntent(), totalCaffeine: .init(value: 163, unit: .milligrams), log: CaffeineLog.defaultLog())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CaffeineLogEntry>) -> Void) {
        let oneMinute: TimeInterval = 3
        var currentDate = Date()
        var entries: [CaffeineLogEntry] = []
        
        var totalCoffeine = DrinksLogStore.shared.totalCaffeine
        for i in 0..<CaffeineLog.Drinks.count {
            currentDate += oneMinute
            let drink = CaffeineLog.Drinks[i]
            let date = Date() + Double(60 * 60 * i)
            let caffeineLog = CaffeineLog(drink: drink, caffeine: 5.0 * Double(i) + 10, date: date)
            totalCoffeine +=  5.0 * Double(i) + 10;
            let entry = CaffeineLogEntry(date: currentDate, configuration: LogDrinkIntent(), totalCaffeine: .init(value: totalCoffeine, unit: .milligrams), log: caffeineLog)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}


// MARK: - CaffeineTrackerWidget

struct CaffeineLogEntry: TimelineEntry {
    let date: Date
    let configuration: LogDrinkIntent
    let totalCaffeine: Measurement<UnitMass>
    var log: CaffeineLog?
    
    static var log1: CaffeineLogEntry {
        let date = Date().addingTimeInterval(60 * 60 * 1)
        return CaffeineLogEntry(date: date, configuration: LogDrinkIntent(), totalCaffeine: .init(value: 63, unit: .milligrams), log: CaffeineLog(drink: CaffeineLog.Drinks[0], caffeine: 63, date: date))
    }
    
    static var log2: CaffeineLogEntry {
        let date = Date().addingTimeInterval(60 * 60 * 2)
        return CaffeineLogEntry(date: date, configuration: LogDrinkIntent(), totalCaffeine: .init(value: 163, unit: .milligrams), log: CaffeineLog(drink: CaffeineLog.Drinks[1], caffeine: 100, date: date))
    }
    
    static var log3: CaffeineLogEntry {
        let date = Date().addingTimeInterval(60 * 60 * 3)
        return CaffeineLogEntry(date: date, configuration: LogDrinkIntent(), totalCaffeine: .init(value: 163, unit: .milligrams), log: CaffeineLog(drink: CaffeineLog.Drinks[2], caffeine: 200, date: date))
    }
    
    static var log4: CaffeineLogEntry {
        let date = Date().addingTimeInterval(60 * 60 * 4)
        return CaffeineLogEntry(date: date, configuration: LogDrinkIntent(), totalCaffeine: .init(value: 163, unit: .milligrams), log: CaffeineLog(drink: CaffeineLog.Drinks[3], caffeine: 8, date: date))
    }
    
    static var log5: CaffeineLogEntry {
        let date = Date().addingTimeInterval(60 * 60 * 5)
        return CaffeineLogEntry(date: date, configuration: LogDrinkIntent(), totalCaffeine: .init(value: 163, unit: .milligrams), log: CaffeineLog(drink: CaffeineLog.Drinks[4], caffeine: 13, date: date))
    }
}


extension View {
     func caffeineWidgetBackground() -> some View {
         let color = Color(red: 255, green: 247, blue: 227)
         if #available(iOSApplicationExtension 17.0, *) {
             return containerBackground(for: .widget) {
                 color
             }
         } else {
             return background {
                 color
             }
         }
    }
}

struct CaffeineLogWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: CaffeineLogEntry

    var body: some View {
        VStack(alignment: .leading, content: {
            TotalCaffeineView(totalCaffeine: entry.totalCaffeine)
            Spacer()
            if let log = entry.log {
                LastDrinkView(log: log)
            }
            
            Spacer()
            
            HStack{
                LogDrinkView()
            }
        })
        .caffeineWidgetBackground()
    }
}

struct CaffeineTrackerWidget: Widget {
    
    func makeWidgetConfiguration() -> some WidgetConfiguration {
        return StaticConfiguration(kind: CaffeineLog.CaffeineLogWidgetKind,
                                   provider: CaffeineIntentProvider()) { entry in
            CaffeineLogWidgetEntryView(entry: entry)
        }
                                   .supportedFamilies(supportedFamilies)

    }
    
    private var supportedFamilies: [WidgetFamily] {
        [.accessoryCircular,
         .accessoryRectangular,
         .accessoryInline,
         .systemSmall,
         .systemMedium,
         .systemLarge]
    }
    
    public var body: some WidgetConfiguration {
        if #available(iOS 17.0, macOS 14.0, *) {
            return makeWidgetConfiguration()
                .configurationDisplayName("Caffeine Tracker")
                .description("See your total caffeine in one day.")
                .disfavoredLocations([.standBy], for: [.systemSmall])
        } else {
           return makeWidgetConfiguration()
                .configurationDisplayName("Caffeine Tracker")
                .description("See your total caffeine in one day.")
        }
    }
}

#Preview(as: .systemSmall, widget: {
    return CaffeineTrackerWidget()
}, timeline: {
    return [CaffeineLogEntry.log1,
            CaffeineLogEntry.log2,
            CaffeineLogEntry.log3,
            CaffeineLogEntry.log4,
            CaffeineLogEntry.log5]
})
