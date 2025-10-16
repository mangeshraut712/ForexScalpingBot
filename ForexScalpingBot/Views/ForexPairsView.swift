//
//  ForexPairsView.swift
//  ForexScalpingBot
//
//  Created by Cline on 10/16/2025.
//

import SwiftUI

struct ForexPairsView: View {
    @StateObject private var forexViewModel = ForexViewModel()
    @State private var searchText = ""
    @State private var selectedTimeframe = "1H"
    @State private var showingChartView = false
    @State private var selectedPair: ForexPair?

    let timeframes = ["1M", "5M", "15M", "1H", "4H", "1D", "1W"]

    var filteredPairs: [ForexPair] {
        if searchText.isEmpty {
            return forexViewModel.forexPairs
        } else {
            return forexViewModel.searchPairs(query: searchText)
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search currency pairs...", text: $searchText)
                        .autocapitalization(.allCharacters)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

                // Timeframe Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(timeframes, id: \.self) { timeframe in
                            Button(action: { selectedTimeframe = timeframe }) {
                                Text(timeframe)
                                    .font(.subheadline)
                                    .fontWeight(selectedTimeframe == timeframe ? .semibold : .regular)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedTimeframe == timeframe ? Color.blue : Color(.systemGray6))
                                    .foregroundColor(selectedTimeframe == timeframe ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Pairs List
                List(filteredPairs) { pair in
                    if let quote = forexViewModel.currentQuotes[pair.symbol] {
                        NavigationLink(destination: ForexDetailView(pair: pair, quote: quote, candles: forexViewModel.candles)) {
                            ForexPairRow(pair: pair, quote: quote)
                        }
                    } else {
                        // Placeholder for pairs without quotes
                        HStack {
                            Text(pair.symbol)
                                .font(.headline)
                            Spacer()
                            Text("Loading...")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Currency Pairs")
            .navigationBarItems(
                trailing: Button(action: {
                    // Refresh prices
                    forexViewModel.objectWillChange.send()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            )
        }
    }
}

struct ForexPairRow: View {
    let pair: ForexPair
    let quote: ForexQuote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(pair.symbol)
                        .font(.headline)
                    Text(pair.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    HStack(spacing: 4) {
                        Text("BID")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(quote.bid, specifier: "%.5f")")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }

                    HStack(spacing: 4) {
                        Text("ASK")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(quote.ask, specifier: "%.5f")")
                            .font(.subheadline)
                    }
                }
            }

            HStack {
                Image(systemName: quote.change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(quote.change >= 0 ? .green : .red)

                Text("\(quote.change >= 0 ? "+" : "")\(quote.change, specifier: "%.5f")")
                    .foregroundColor(quote.change >= 0 ? .green : .red)
                    .fontWeight(.medium)

                Text("(\(quote.changePercent >= 0 ? "+" : "")\(quote.changePercent, specifier: "%.2f")%)")
                    .foregroundColor(quote.change >= 0 ? .green : .red)
                    .font(.subheadline)

                Spacer()

                // Spread indicator
                let spread = quote.ask - quote.bid
                Text("Spread: \(spread, specifier: "%.1f") pips")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// Detailed Forex View
struct ForexDetailView: View {
    let pair: ForexPair
    let quote: ForexQuote
    let candles: [ForexCandle]

    @State private var selectedTimeframe = "1H"
    @State private var showingIndicators = false
    @State private var viewMode: ViewMode = .chart

    enum ViewMode {
        case chart, depth, news
    }

    let timeframes = ["1M", "5M", "15M", "1H", "4H", "1D", "1W"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Price Header
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(pair.symbol)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            Text(pair.name)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("\(quote.bid, specifier: "%.5f")")
                                .font(.title)
                                .fontWeight(.bold)
                            HStack {
                                Image(systemName: quote.change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                Text("\(quote.change >= 0 ? "+" : "")\(quote.changePercent, specifier: "%.2f")%")
                                    .foregroundColor(quote.change >= 0 ? .green : .red)
                            }
                        }
                    }

                    // Bid/Ask Spread
                    HStack {
                        VStack(alignment: .leading) {
                            Text("BID")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(quote.bid, specifier: "%.5f")")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        VStack(alignment: .center) {
                            Text("SPREAD")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            let spread = quote.ask - quote.bid
                            Text("\(spread * 10000, specifier: "%.1f") pips")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("ASK")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(quote.ask, specifier: "%.5f")")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // Timeframe and Mode Selector
                VStack(spacing: 16) {
                    // Timeframes
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(timeframes, id: \.self) { timeframe in
                                Button(action: { selectedTimeframe = timeframe }) {
                                    Text(timeframe)
                                        .font(.subheadline)
                                        .fontWeight(selectedTimeframe == timeframe ? .semibold : .regular)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedTimeframe == timeframe ? Color.blue : Color(.systemGray6))
                                        .foregroundColor(selectedTimeframe == timeframe ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }

                    // View Mode Picker
                    Picker("View", selection: $viewMode) {
                        Text("Chart").tag(ViewMode.chart)
                        Text("Depth").tag(ViewMode.depth)
                        Text("News").tag(ViewMode.news)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)

                // Content based on view mode
                switch viewMode {
                case .chart:
                    ForexChartView(pair: pair, candles: candles, timeframe: selectedTimeframe)
                case .depth:
                    MarketDepthView(pair: pair)
                case .news:
                    ForexNewsView(pair: pair)
                }
            }
        }
        .navigationTitle(pair.symbol)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Forex Chart View
struct ForexChartView: View {
    let pair: ForexPair
    let candles: [ForexCandle]
    let timeframe: String

    @State private var showingIndicators = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(pair.symbol) - \(timeframe)")
                    .font(.headline)
                Spacer()
                Button(action: { showingIndicators.toggle() }) {
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundColor(.blue)
                }
            }

            // Interactive Chart with Indicators
            ZStack {
                Chart {
                    ForEach(candles.suffix(min(100, candles.count)), id: \.timestamp) { candle in
                        LineMark(
                            x: .value("Time", candle.timestamp),
                            y: .value("Price", candle.close)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        // Volume bars (simplified)
                        BarMark(
                            x: .value("Time", candle.timestamp),
                            y: .value("Volume", Double(candle.volume) / 1000.0)
                        )
                        .foregroundStyle(.gray.opacity(0.3))
                        .offset(y: -100)
                    }

                    if showingIndicators {
                        // EMA 20
                        LineMark(
                            x: .value("Time", Date()),
                            y: .value("EMA20", calculateEMA(candles: candles, period: 20))
                        )
                        .foregroundStyle(.green)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))

                        // EMA 50
                        LineMark(
                            x: .value("Time", Date()),
                            y: .value("EMA50", calculateEMA(candles: candles, period: 50))
                        )
                        .foregroundStyle(.red)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    }
                }
                .frame(height: 300)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 4)) { _ in
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            Text("\(value.as(Double.self) ?? 0, specifier: "%.5f")")
                        }
                    }
                }
            }

            if showingIndicators {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Technical Indicators")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack(spacing: 16) {
                        IndicatorLegend(color: .green, label: "EMA 20")
                        IndicatorLegend(color: .red, label: "EMA 50")
                        IndicatorLegend(color: .purple, label: "RSI")
                        IndicatorLegend(color: .orange, label: "MACD")
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
    }

    private func calculateEMA(candles: [ForexCandle], period: Int) -> Double {
        // Simplified EMA calculation - in real app, use proper algorithm
        let recentCandles = candles.suffix(min(period * 2, candles.count))
        let sum = recentCandles.reduce(0.0) { $0 + $1.close }
        return sum / Double(recentCandles.count)
    }
}

struct IndicatorLegend: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
        }
    }
}

// Market Depth View
struct MarketDepthView: View {
    let pair: ForexPair

    // Mock market depth data
    let bids = [
        (price: 1.0850, volume: 1000000),
        (price: 1.0849, volume: 750000),
        (price: 1.0848, volume: 500000),
        (price: 1.0847, volume: 300000),
        (price: 1.0846, volume: 200000)
    ]

    let asks = [
        (price: 1.0851, volume: 800000),
        (price: 1.0852, volume: 600000),
        (price: 1.0853, volume: 400000),
        (price: 1.0854, volume: 250000),
        (price: 1.0855, volume: 150000)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Market Depth")
                .font(.headline)

            VStack(spacing: 0) {
                HStack {
                    Text("BID")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("PRICE")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("ASK")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray6))

                ForEach(0..<max(bids.count, asks.count), id: \.self) { index in
                    HStack {
                        if index < bids.count {
                            VStack(alignment: .leading) {
                                Text("\(bids[index].price, specifier: "%.4f")")
                                    .font(.monospacedDigit(.body)())
                                Text("\(bids[index].volume / 1000000, specifier: "%.1f")M")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Spacer()
                        }

                        Spacer()

                        if index < asks.count {
                            VStack(alignment: .trailing) {
                                Text("\(asks[index].price, specifier: "%.4f")")
                                    .font(.monospacedDigit(.body)())
                                Text("\(asks[index].volume / 1000000, specifier: "%.1f")M")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        } else {
                            Spacer()
                        }
                    }
                    .padding(.vertical, 4)
                    .background(index % 2 == 0 ? Color.clear : Color(.systemGray6).opacity(0.5))
                }
            }
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .padding()
    }
}

// Forex News View
struct ForexNewsView: View {
    let pair: ForexPair

    // Mock news data
    let newsItems = [
        ("EUR/USD Technical Analysis", "Bullish momentum building...", "23 min ago", .neutral),
        ("ECB Minutes Released", "Hawkish tone surprises markets", "2h ago", .negative),
        ("Euro Zone PMI Data", "Manufacturing sector shows strength", "4h ago", .positive)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Related News")
                .font(.headline)

            ForEach(newsItems, id: \.0) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(item.0)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(item.2)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(item.1)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    sentimentIndicator(item.3)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 2)
            }
        }
        .padding()
    }

    private func sentimentIndicator(_ sentiment: ForexNews.Sentiment) -> some View {
        HStack {
            Image(systemName: sentimentIcon(sentiment))
                .foregroundColor(sentimentColor(sentiment))
            Text(sentiment.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(sentimentColor(sentiment))
        }
    }

    private func sentimentIcon(_ sentiment: ForexNews.Sentiment) -> String {
        switch sentiment {
        case .positive: return "arrow.up.circle.fill"
        case .negative: return "arrow.down.circle.fill"
        case .neutral: return "circle.fill"
        }
    }

    private func sentimentColor(_ sentiment: ForexNews.Sentiment) -> Color {
        switch sentiment {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .gray
        }
    }
}

struct ForexPairsView_Previews: PreviewProvider {
    static var previews: some View {
        ForexPairsView()
    }
}
