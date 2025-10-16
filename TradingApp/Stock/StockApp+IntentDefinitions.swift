//
//  StockApp+IntentDefinitions.swift
//  Stock
//
//  App Intents for Siri Integration (iOS 26)
//

import AppIntents
import SwiftUI

// MARK: - Stock Trading Intents

@available(iOS 16.0, *)
struct TradeStockIntent: AppIntent {
    static let title: LocalizedStringResource = "Trade Stock"
    static let description = IntentDescription("Buy or sell shares of a stock")

    @Parameter(title: "Symbol", description: "Stock symbol (e.g., AAPL)")
    var symbol: String

    @Parameter(title: "Action", description: "Buy or sell")
    var action: TradingAction

    @Parameter(title: "Quantity", description: "Number of shares")
    var quantity: Int

    @Parameter(title: "Limit Price", description: "Price limit (optional)")
    var limitPrice: Double?

    static var parameterSummary: some ParameterSummary {
        Summary("Trade \(\.$quantity) shares of \(\.$symbol) \(\.$action)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Perform the trade through API
        let success = try await performTrade(symbol: symbol, action: action, quantity: quantity, limitPrice: limitPrice)

        if success {
            let message = "Successfully \(action.rawValue)ed \(quantity) shares of \(symbol.uppercased())"
            return .result(dialog: "\(message)")
        } else {
            return .result(dialog: "Failed to \(action.rawValue) \(quantity) shares of \(symbol.uppercased())")
        }
    }

    private func performTrade(symbol: String, action: TradingAction, quantity: Int, limitPrice: Double?) async throws -> Bool {
        // Connect to your trading API
        // This would call your existing trading functions
        print("Performing \(action.rawValue) of \(quantity) shares of \(symbol)")
        return true // Mock success
    }
}

// MARK: - View Portfolio Intent

@available(iOS 16.0, *)
struct ViewPortfolioIntent: AppIntent {
    static let title: LocalizedStringResource = "View Portfolio"
    static let description = IntentDescription("Check your portfolio performance")

    @Parameter(title: "Show Details", description: "Include detailed breakdown")
    var showDetails: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Show Portfolio Details") {
            \.$showDetails
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let portfolio = try await fetchPortfolioData()

        let totalValue = portfolio.reduce(0) { $0 + $1.value }
        let totalChange = portfolio.reduce(0) { $0 + $1.change }

        let message = IntentDialog(stringLiteral: "Portfolio value: $\(String(format: "%.2f", totalValue)) (\(String(format: "%.2f", totalChange)))")

        return .result(
            dialog: message,
            view: PortfolioSnippetView(portfolio: portfolio, showDetails: showDetails)
        )
    }

    private func fetchPortfolioData() async throws -> [PortfolioSnippetItem] {
        // Fetch portfolio data from your API
        return [
            PortfolioSnippetItem(symbol: "AAPL", shares: 10, value: 1500, change: 25),
            PortfolioSnippetItem(symbol: "GOOGL", shares: 5, value: 12000, change: -100)
        ]
    }
}

// MARK: - Search Stock Intent

@available(iOS 16.0, *)
struct SearchStockIntent: AppIntent {
    static let title: LocalizedStringResource = "Search Stock"
    static let description = IntentDescription("Search for stock information")

    @Parameter(title: "Query", description: "Stock symbol or company name")
    var query: String

    static var parameterSummary: some ParameterSummary {
        Summary("Search for \(\.$query)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let results = try await searchStocks(query: query)

        guard let topResult = results.first else {
            return .result(dialog: "No stocks found for \(query)")
        }

        let message = IntentDialog(stringLiteral: "\(topResult.symbol) (\(String(format: "%.2f", topResult.price))) - \(String(format: "%.0f", topResult.changePercent))%")

        return .result(
            dialog: message,
            view: StockSearchSnippetView(results: results)
        )
    }

    private func searchStocks(query: String) async throws -> [StockSearchResult] {
        // Search through your stock API
        return [
            StockSearchResult(symbol: query.uppercased(), name: "\(query) Corporation", price: 150.00, changePercent: 2.5)
        ]
    }
}

// MARK: - Enhanced Siri Package Declaration

@available(iOS 16.0, *)
public struct StockAppShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SearchStockIntent(),
            phrases: [
                "Search for \(\.$query) stock",
                "Find \(\.$query) on StockApp",
                "What is \(\.$query) trading at"
            ],
            shortTitle: "Search Stock",
            systemImageName: "magnifyingglass"
        )

        AppShortcut(
            intent: TradeStockIntent(),
            phrases: [
                "Buy \(\.$quantity) shares of \(\.$symbol)",
                "Sell \(\.$quantity) shares of \(\.$symbol)",
                "Trade \(\.$symbol) stock"
            ],
            shortTitle: "Trade Stock",
            systemImageName: "chart.line.uptrend.xyaxis"
        )

        AppShortcut(
            intent: ViewPortfolioIntent(),
            phrases: [
                "Check my portfolio",
                "How is my portfolio doing",
                "Show portfolio performance"
            ],
            shortTitle: "View Portfolio",
            systemImageName: "briefcase"
        )
    }
}

// MARK: - Support Types

enum TradingAction: String, AppEnum {
    case buy
    case sell

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Trading Action")

    static let caseDisplayRepresentations: [TradingAction: DisplayRepresentation] = [
        .buy: "Buy",
        .sell: "Sell"
    ]
}

struct PortfolioSnippetItem: Hashable {
    let symbol: String
    let shares: Int
    let value: Double
    let change: Double
}

struct StockSearchResult: Hashable {
    let symbol: String
    let name: String
    let price: Double
    let changePercent: Double
}

// MARK: - Snippet Views

@available(iOS 16.0, *)
struct PortfolioSnippetView: View {
    let portfolio: [PortfolioSnippetItem]
    let showDetails: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Portfolio Overview")
                .font(.headline)

            ForEach(portfolio.prefix(showDetails ? 5 : 2), id: \.symbol) { item in
                HStack {
                    Text(item.symbol).bold()
                    Spacer()
                    Text("$\(item.value, specifier: "%.0f")")
                    Text("(\(item.change >= 0 ? "+" : "")\(item.change, specifier: "%.0f"))")
                        .foregroundColor(item.change >= 0 ? .green : .red)
                }
                .font(.caption)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@available(iOS 16.0, *)
struct StockSearchSnippetView: View {
    let results: [StockSearchResult]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search Results")
                .font(.headline)

            ForEach(results.prefix(3), id: \.symbol) { result in
                HStack {
                    Text(result.symbol).bold()
                    Text(result.name)
                        .lineLimit(1)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("$\(result.price, specifier: "%.2f")")
                        Text("\(result.changePercent >= 0 ? "+" : "")\(result.changePercent, specifier: "%.1f")%")
                            .foregroundColor(result.changePercent >= 0 ? .green : .red)
                            .font(.caption)
                    }
                }
                .font(.caption)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Intent Handler Extensions

// Content view extension is commented out to avoid cross-file reference issues in VSCode
// Uncomment and move to appropriate file when integrating with the main ContentView

/*
@available(iOS 16.0, *)
extension ContentView {
    func handleAppIntent(_ intent: any AppIntent) {
        // Handle intents from Siri/Shortucts
        Task {
            do {
                let result = try await intent.perform()

                if let result = result as? ViewPortfolioIntent.Result,
                   let portfolioView = result.view as? PortfolioSnippetView {
                    // Show portfolio view
                    print("Portfolio request handled")
                }
            } catch {
                print("Intent handling failed: \(error)")
            }
        }
    }
}
*/
