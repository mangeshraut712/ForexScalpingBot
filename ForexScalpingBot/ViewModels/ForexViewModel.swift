//
//  ForexViewModel.swift
//  ForexScalpingBot
//
//  Created by Cline on 10/16/2025.
//

import Foundation
import Combine

class ForexViewModel: ObservableObject {
    @Published var forexPairs: [ForexPair] = []
    @Published var selectedPair: ForexPair?
    @Published var currentQuotes: [String: ForexQuote] = [:]
    @Published var candles: [ForexCandle] = []
    @Published var economicCalendar: [EconomicEvent] = []
    @Published var news: [ForexNews] = []
    @Published var isLoading = false
    @Published var error: ForexError?

    private var cancellables = Set<AnyCancellable>()
    private var priceUpdateTimer: Timer?

    init() {
        // Initialize with major forex pairs
        setupDefaultPairs()
        setupPriceUpdates()
    }

    private func setupDefaultPairs() {
        forexPairs = [
            ForexPair(symbol: "EURUSD", name: "Euro vs US Dollar"),
            ForexPair(symbol: "GBPUSD", name: "British Pound vs US Dollar"),
            ForexPair(symbol: "USDJPY", name: "US Dollar vs Japanese Yen"),
            ForexPair(symbol: "USDCHF", name: "US Dollar vs Swiss Franc"),
            ForexPair(symbol: "AUDUSD", name: "Australian Dollar vs US Dollar"),
            ForexPair(symbol: "USDCAD", name: "US Dollar vs Canadian Dollar"),
            ForexPair(symbol: "NZDUSD", name: "New Zealand Dollar vs US Dollar")
        ]
    }

    private func setupPriceUpdates() {
        // Simulate real-time price updates every 2 seconds
        priceUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updatePrices()
        }
    }

    private func updatePrices() {
        Task {
            for pair in forexPairs {
                // Mock price updates - in real app, use WebSocket or API
                let priceChange = Double.random(in: -0.001...0.001)
                var currentPrice = currentQuotes[pair.symbol]?.bid ?? 1.0
                currentPrice += priceChange

                let spread = Double.random(in: 0.0001...0.0003)
                let askPrice = currentPrice + spread

                let change = priceChange
                let changePercent = (change / currentPrice) * 100

                currentQuotes[pair.symbol] = ForexQuote(
                    symbol: pair.symbol,
                    bid: currentPrice,
                    ask: askPrice,
                    change: change,
                    changePercent: changePercent,
                    timestamp: Date()
                )
            }
        }
    }

    func selectPair(_ pair: ForexPair) {
        selectedPair = pair
        loadCandles(for: pair.symbol)
    }

    private func loadCandles(for symbol: String) {
        // Mock historical candle data - in real app, fetch from API
        candles = (0..<100).map { index in
            let basePrice = currentQuotes[symbol]?.bid ?? 1.0
            let timestamp = Date().addingTimeInterval(TimeInterval(-index * 3600)) // Hourly candles

            let open = basePrice + Double.random(in: -0.01...0.01)
            let high = open + abs(Double.random(in: 0...0.005))
            let low = open - abs(Double.random(in: 0...0.005))
            let close = low + Double.random(in: 0...high-low)
            let volume = Int.random(in: 1000...10000)

            return ForexCandle(
                timestamp: timestamp,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: volume
            )
        }.reversed()
    }

    func loadEconomicCalendar() async {
        isLoading = true
        do {
            // Mock economic events - in real app, fetch from ForexFactory or similar
            economicCalendar = [
                EconomicEvent(
                    title: "Non-Farm Payrolls",
                    country: "US",
                    importance: .high,
                    timestamp: Date().addingTimeInterval(86400 * 3), // 3 days from now
                    actual: nil,
                    forecast: "250K",
                    previous: "236K"
                ),
                EconomicEvent(
                    title: "ECB Interest Rate Decision",
                    country: "EU",
                    importance: .high,
                    timestamp: Date().addingTimeInterval(86400 * 5), // 5 days from now
                    actual: nil,
                    forecast: "3.75%",
                    previous: "4.25%"
                )
            ]
        } catch {
            self.error = .networkError
        }
        isLoading = false
    }

    func loadNews(for symbol: String) async {
        isLoading = true
        do {
            // Mock news data - in real app, fetch from financial news APIs
            news = [
                ForexNews(
                    title: "EUR/USD Tests Key Resistance Levels",
                    summary: "The euro maintained its gains against the dollar...",
                    source: "Forex.com",
                    timestamp: Date().addingTimeInterval(-3600),
                    sentiment: .neutral,
                    relatedPairs: ["EURUSD"]
                ),
                ForexNews(
                    title: "Fed Minutes Reveal Hawkish Stance",
                    summary: "Federal Reserve officials suggested...",
                    source: "Bloomberg",
                    timestamp: Date().addingTimeInterval(-7200),
                    sentiment: .negative,
                    relatedPairs: ["USDJPY", "GBPUSD"]
                )
            ]
        } catch {
            self.error = .networkError
        }
        isLoading = false
    }

    func searchPairs(query: String) -> [ForexPair] {
        guard !query.isEmpty else { return forexPairs }

        return forexPairs.filter { pair in
            pair.symbol.lowercased().contains(query.lowercased()) ||
            pair.name.lowercased().contains(query.lowercased())
        }
    }

    deinit {
        priceUpdateTimer?.invalidate()
    }

    enum ForexError: LocalizedError {
        case networkError
        case parsingError
        case apiLimitExceeded

        var errorDescription: String? {
            switch self {
            case .networkError:
                return "Network connection failed"
            case .parsingError:
                return "Data parsing error"
            case .apiLimitExceeded:
                return "API rate limit exceeded"
            }
        }
    }
}

// Forex Models
struct ForexPair: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
}

struct ForexQuote: Identifiable {
    let id = UUID()
    let symbol: String
    let bid: Double
    let ask: Double
    let change: Double
    let changePercent: Double
    let timestamp: Date
}

struct ForexCandle {
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int
}

struct EconomicEvent: Identifiable {
    let id = UUID()
    let title: String
    let country: String
    let importance: Importance
    let timestamp: Date
    var actual: String?
    var forecast: String
    var previous: String

    enum Importance: String {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
    }
}

struct ForexNews: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let source: String
    let timestamp: Date
    let sentiment: Sentiment
    let relatedPairs: [String]

    enum Sentiment {
        case positive
        case negative
        case neutral
    }
}
