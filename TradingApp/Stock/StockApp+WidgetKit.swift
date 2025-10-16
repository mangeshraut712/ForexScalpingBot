#if canImport(WidgetKit) && os(iOS)
//
//  StockApp+WidgetKit.swift
//  Stock
//
//  Live Activities and Widgets for iOS 26
//

import WidgetKit
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - Live Activity for Stock Trading
#if canImport(ActivityKit)
@available(iOS 16.1, *)
struct StockLiveActivity: Widget {
    let kind: String = "StockLiveActivity"

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StockActivityAttributes.self) { context in
            // Live Activity UI
            VStack(alignment: .leading) {
                HStack {
                    Text(context.attributes.symbol)
                        .font(.headline)
                    Spacer()
                    Text("$\(context.attributes.currentPrice, specifier: "%.2f")")
                        .font(.title2)
                        .bold()
                }

                HStack {
                    Image(systemName: context.attributes.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .foregroundColor(context.attributes.isPositive ? .green : .red)
                    Text("$\(context.attributes.change, specifier: "%.2f") (\(context.attributes.changePercent, specifier: "%.1f")%)")
                        .foregroundColor(context.attributes.isPositive ? .green : .red)
                }

                Text(context.state.lastUpdateTime.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
        } dynamicIsland: { context in
            // Dynamic Island Compact View
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading, priority: .highest) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.blue)
                }

                DynamicIslandExpandedRegion(.trailing, priority: .high) {
                    Text("$\(context.attributes.currentPrice, specifier: "%.2f")")
                        .font(.headline)
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack {
                        Text(context.attributes.symbol)
                        Text("\(context.attributes.changePercent >= 0 ? "+" : "")\(context.attributes.changePercent, specifier: "%.1f")%")
                            .foregroundColor(context.attributes.isPositive ? .green : .red)
                    }
                }
            } compactLeading: {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text("$\(context.attributes.currentPrice, specifier: "%.2f")")
                    .font(.callout)
            } minimal: {
                Image(systemName: context.attributes.isPositive ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(context.attributes.isPositive ? .green : .red)
            }
        }
    }
}

// MARK: - Live Activity Attributes
@available(iOS 16.1, *)
struct StockActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public let lastUpdateTime: Date
    }

    public let symbol: String
    public let currentPrice: Double
    public let change: Double
    public let changePercent: Double
    public let isPositive: Bool
}
#endif

// MARK: - Equity Widget
@available(iOS 17.0, *)
struct EquityWidget: Widget {
    let kind: String = "EquityWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EquityTimelineProvider()) { entry in
            EquityWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Equity Overview")
        .description("View your portfolio equity at a glance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Equity Widget Provider
@available(iOS 17.0, *)
struct EquityTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> EquitySimpleEntry {
        EquitySimpleEntry(date: Date(), equity: 100000, change: 2500, changePercent: 2.5)
    }

    func getSnapshot(in context: Context, completion: @escaping (EquitySimpleEntry) -> ()) {
        let entry = EquitySimpleEntry(date: Date(), equity: 105250, change: 5250, changePercent: 5.25)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EquitySimpleEntry>) -> ()) {
        var entries: [EquitySimpleEntry] = []

        let currentDate = Date()
        for hourOffset in 0 ..< 24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let baseEquity = Double.random(in: 100000...110000)
            let change = Double.random(in: -1000...1000)
            let changePercent = (change / baseEquity) * 100
            let entry = EquitySimpleEntry(date: entryDate,
                                        equity: baseEquity + change,
                                        change: change,
                                        changePercent: changePercent)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Equity Widget Entry
struct EquitySimpleEntry: TimelineEntry {
    let date: Date
    let equity: Double
    let change: Double
    let changePercent: Double
}

// MARK: - Equity Widget View
@available(iOS 17.0, *)
struct EquityWidgetEntryView: View {
    var entry: EquitySimpleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Equity")
                    .font(.headline)
                Spacer()
                Text("$\(entry.equity, specifier: "%.0f")")
                    .font(.title)
                    .bold()
            }

            HStack {
                Image(systemName: entry.change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(entry.change >= 0 ? .green : .red)
                Text("$\(entry.change >= 0 ? "+" : "")\(entry.change, specifier: "%.0f")")
                    .foregroundColor(entry.change >= 0 ? .green : .red)
                Text("(\(entry.changePercent >= 0 ? "+" : "")\(entry.changePercent, specifier: "%.1f")%)")
                    .foregroundColor(entry.change >= 0 ? .green : .red)
                    .font(.callout)
            }

            Text(entry.date.formatted(.relative(presentation: .numeric)))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - WatchList Widget
@available(iOS 17.0, *)
struct WatchListWidget: Widget {
    let kind: String = "WatchListWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchListTimelineProvider()) { entry in
            WatchListWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Watchlist")
        .description("Monitor your favorite stocks")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - WatchList Widget Provider
@available(iOS 17.0, *)
struct WatchListTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchListEntry {
        WatchListEntry(date: Date(), stocks: [
            StockWidgetModel(symbol: "AAPL", price: 150.23, change: 2.45, changePercent: 1.66),
            StockWidgetModel(symbol: "GOOGL", price: 2800.67, change: -15.23, changePercent: -0.54),
            StockWidgetModel(symbol: "TSLA", price: 245.89, change: 8.92, changePercent: 3.76)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchListEntry) -> ()) {
        let entry = WatchListEntry(date: Date(), stocks: [
            StockWidgetModel(symbol: "AAPL", price: 150.23, change: 2.45, changePercent: 1.66),
            StockWidgetModel(symbol: "GOOGL", price: 2800.67, change: -15.23, changePercent: -0.54),
            StockWidgetModel(symbol: "TSLA", price: 245.89, change: 8.92, changePercent: 3.76)
        ])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchListEntry>) -> ()) {
        var entries: [WatchListEntry] = []

        let currentDate = Date()
        for hourOffset in 0 ..< 12 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!

            let stocks = [
                StockWidgetModel(symbol: "AAPL",
                               price: 150.23 + Double.random(in: -5...5),
                               change: Double.random(in: -3...3),
                               changePercent: Double.random(in: -2...2)),
                StockWidgetModel(symbol: "GOOGL",
                               price: 2800.67 + Double.random(in: -50...50),
                               change: Double.random(in: -20...20),
                               changePercent: Double.random(in: -1...1)),
                StockWidgetModel(symbol: "TSLA",
                               price: 245.89 + Double.random(in: -10...10),
                               change: Double.random(in: -5...5),
                               changePercent: Double.random(in: -2...2))
            ]

            let entry = WatchListEntry(date: entryDate, stocks: stocks)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Stock Widget Model
struct StockWidgetModel {
    let symbol: String
    let price: Double
    let change: Double
    let changePercent: Double
}

// MARK: - WatchList Entry
struct WatchListEntry: TimelineEntry {
    let date: Date
    let stocks: [StockWidgetModel]
}

// MARK: - WatchList Widget View
@available(iOS 17.0, *)
struct WatchListWidgetEntryView: View {
    var entry: WatchListEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Watchlist")
                .font(.headline)
                .foregroundColor(.primary)

            ForEach(entry.stocks, id: \.symbol) { stock in
                HStack {
                    Text(stock.symbol)
                        .font(.subheadline)
                        .bold()
                        .frame(width: 60, alignment: .leading)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("$\(stock.price, specifier: "%.2f")")
                            .font(.subheadline)
                            .bold()

                        HStack(spacing: 4) {
                            Image(systemName: stock.changePercent >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 10))
                            Text("\(stock.changePercent >= 0 ? "+" : "")\(stock.changePercent, specifier: "%.1f")%")
                                .font(.caption)
                        }
                        .foregroundColor(stock.changePercent >= 0 ? .green : .red)
                    }
                }
            }

            Text(entry.date.formatted(.relative(presentation: .numeric)))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Widget Bundle Extension
@available(iOS 17.0, *)
struct StockWidgetsBundle: WidgetBundle {
    var body: some Widget {
        EquityWidget()
        WatchListWidget()
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            StockLiveActivity()
        }
        #endif
    }
}

// MARK: - Helper Extensions
extension Date {
    func formatted(_ style: Date.RelativeFormatStyle) -> String {
        self.formatted(style)
    }
}
#endif
