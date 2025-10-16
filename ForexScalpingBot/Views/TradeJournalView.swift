//
//  TradeJournalView.swift
//  ForexScalpingBot
//
//  Created by Cline on 10/16/2025.
//

import SwiftUI
import Charts

struct TradeJournalView: View {
    @StateObject private var tradeJournalViewModel = TradeJournalViewModel()
    @State private var selectedTimeRange = "Today"
    @State private var showingAddTrade = false
    @State private var showingStatistics = false

    let timeRanges = ["Today", "1 Week", "1 Month", "3 Months", "All Time"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Statistics Cards
                    StatisticsCardsView(viewModel: tradeJournalViewModel)

                    // Equity Curve Chart
                    EquityCurveCard(viewModel: tradeJournalViewModel)

                    // Recent Trades List
                    RecentTradesCard(viewModel: tradeJournalViewModel)

                    // Performance Analysis
                    PerformanceAnalysisCard(viewModel: tradeJournalViewModel)
                }
                .padding()
            }
            .navigationTitle("Trade Journal")
            .navigationBarItems(
                leading: HStack {
                    Button(action: { showingStatistics.toggle() }) {
                        Image(systemName: "chart.bar.fill")
                    }

                    Menu {
                        ForEach(timeRanges, id: \.self) { range in
                            Button(action: {
                                selectedTimeRange = range
                                tradeJournalViewModel.updateTimeRange(range)
                            }) {
                                Text(range)
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedTimeRange)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                    }
                },
                trailing: Button(action: { showingAddTrade.toggle() }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingStatistics) {
                TradeStatisticsView(viewModel: tradeJournalViewModel)
            }
            .sheet(isPresented: $showingAddTrade) {
                AddTradeView(viewModel: tradeJournalViewModel)
            }
        }
    }
}

// Statistics Cards View
struct StatisticsCardsView: View {
    @ObservedObject var viewModel: TradeJournalViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatisticCard(
                    title: "Total P&L",
                    value: "$\(String(format: "%.2f", viewModel.totalPnL))",
                    change: viewModel.monthlyChangePnL,
                    color: viewModel.totalPnL >= 0 ? .green : .red
                )

                StatisticCard(
                    title: "Win Rate",
                    value: "\(String(format: "%.1f", viewModel.winRate * 100))%",
                    change: nil,
                    color: viewModel.winRate >= 0.5 ? .green : .red
                )
            }

            HStack(spacing: 16) {
                StatisticCard(
                    title: "Total Trades",
                    value: "\(viewModel.totalTrades)",
                    change: viewModel.tradesThisMonth,
                    color: .blue
                )

                StatisticCard(
                    title: "Avg Trade",
                    value: "$\(String(format: "%.2f", viewModel.averageTradePnL))",
                    change: nil,
                    color: viewModel.averageTradePnL >= 0 ? .green : .red
                )
            }

            HStack(spacing: 16) {
                StatisticCard(
                    title: "Max Drawdown",
                    value: "$\(String(format: "%.2f", viewModel.maxDrawdown))",
                    change: nil,
                    color: .red
                )

                StatisticCard(
                    title: "Sharpe Ratio",
                    value: "\(String(format: "%.2f", viewModel.sharpeRatio))",
                    change: nil,
                    color: viewModel.sharpeRatio >= 1.0 ? .green : .orange
                )
            }
        }
    }
}

struct StatisticCard: View {
    let title: String
    let value: String
    let change: Int?
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if let change = change, change != 0 {
                    Text("\(change >= 0 ? "+" : "")\(change)")
                        .font(.caption2)
                        .foregroundColor(change >= 0 ? .green : .red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((change >= 0 ? Color.green : Color.red).opacity(0.2))
                        .cornerRadius(4)
                }
            }

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

// Equity Curve Card
struct EquityCurveCard: View {
    @ObservedObject var viewModel: TradeJournalViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Equity Curve")
                .font(.title2)
                .fontWeight(.bold)

            if viewModel.equityPoints.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No trades yet - equity curve will appear after your first trades")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 200)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5)
            } else {
                Chart {
                    ForEach(viewModel.equityPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Equity", point.value)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Equity", point.value)
                        )
                        .foregroundStyle(.blue.opacity(0.1))
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                        AxisValueLabel(format: .dateTime.day().month())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("$\(String(format: "%.0f", doubleValue))")
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5)
            }
        }
    }
}

// Recent Trades Card
struct RecentTradesCard: View {
    @ObservedObject var viewModel: TradeJournalViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Trades")
                .font(.title2)
                .fontWeight(.bold)

            if viewModel.recentTrades.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No trades recorded yet")
                        .foregroundColor(.secondary)
                }
                .frame(height: 200)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentTrades.prefix(5)) { trade in
                        TradeRow(trade: trade)
                        if trade.id != viewModel.recentTrades.prefix(5).last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5)

                if viewModel.recentTrades.count > 5 {
                    Button(action: {}) {
                        Text("View All Trades")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
}

struct TradeRow: View {
    let trade: TradeJournalEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(trade.pair)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text(trade.direction.rawValue.uppercased())
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(trade.direction == .buy ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .foregroundColor(trade.direction == .buy ? .green : .red)
                        .cornerRadius(4)
                }

                HStack {
                    Text("Entry: $\(String(format: "%.4f", trade.entryPrice))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")

                    Text("Exit: $\(String(format: "%.4f", trade.exitPrice ?? 0))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(String(format: "%.2f", trade.pnl ?? 0))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor((trade.pnl ?? 0) >= 0 ? .green : .red)

                Text(trade.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// Performance Analysis Card
struct PerformanceAnalysisCard: View {
    @ObservedObject var viewModel: TradeJournalViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Analysis")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                // Best and Worst Trades
                HStack(spacing: 16) {
                    PerformanceMetric(
                        title: "Best Trade",
                        value: "$\(String(format: "%.2f", viewModel.bestTrade))",
                        subtitle: viewModel.bestTradePair,
                        color: .green
                    )

                    PerformanceMetric(
                        title: "Worst Trade",
                        value: "$\(String(format: "%.2f", viewModel.worstTrade))",
                        subtitle: viewModel.worstTradePair,
                        color: .red
                    )
                }

                // Monthly Performance
                VStack(alignment: .leading, spacing: 12) {
                    Text("Monthly Performance")
                        .font(.headline)

                    if viewModel.monthlyPerformances.isEmpty {
                        Text("No monthly data available")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(viewModel.monthlyPerformances, id: \.month) { performance in
                                MonthPerformanceView(performance: performance)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5)
        }
    }
}

struct PerformanceMetric: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

struct MonthPerformanceView: View {
    let performance: MonthlyPerformance

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(performance.monthString)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("$\(String(format: "%.2f", performance.pnl))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(performance.pnl >= 0 ? .green : .red)

            Text("\(performance.tradeCount) trades")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// Trade Journal View Model
class TradeJournalViewModel: ObservableObject {
    @Published var trades: [TradeJournalEntry] = []
    @Published var recentTrades: [TradeJournalEntry] = []
    @Published var equityPoints: [EquityPoint] = []
    @Published var selectedTimeRange = "Today"

    // Computed properties
    var totalPnL: Double {
        trades.reduce(0) { $0 + ($1.pnl ?? 0) }
    }

    var winRate: Double {
        let winningTrades = trades.filter { ($0.pnl ?? 0) > 0 }.count
        return trades.isEmpty ? 0 : Double(winningTrades) / Double(trades.count)
    }

    var totalTrades: Int {
        trades.count
    }

    var averageTradePnL: Double {
        trades.isEmpty ? 0 : totalPnL / Double(trades.count)
    }

    var maxDrawdown: Double {
        calculateMaxDrawdown()
    }

    var sharpeRatio: Double {
        calculateSharpeRatio()
    }

    var bestTrade: Double {
        trades.map { $0.pnl ?? 0 }.max() ?? 0
    }

    var worstTrade: Double {
        trades.map { $0.pnl ?? 0 }.min() ?? 0
    }

    var bestTradePair: String {
        trades.max(by: { ($0.pnl ?? 0) < ($1.pnl ?? 0) })?.pair ?? "N/A"
    }

    var worstTradePair: String {
        trades.min(by: { ($0.pnl ?? 0) < ($1.pnl ?? 0) })?.pair ?? "N/A"
    }

    var monthlyChangePnL: Int {
        // Calculate change from previous month
        0 // Placeholder
    }

    var tradesThisMonth: Int {
        tradesThisMonthCount()
    }

    var monthlyPerformances: [MonthlyPerformance] {
        calculateMonthlyPerformances()
    }

    init() {
        loadMockData()
        updateRecentTrades()
        updateEquityCurve()
    }

    func updateTimeRange(_ range: String) {
        selectedTimeRange = range
        updateRecentTrades()
        updateEquityCurve()
    }

    func addTrade(_ trade: TradeJournalEntry) {
        trades.append(trade)
        updateRecentTrades()
        updateEquityCurve()

        // Persist to storage
        saveTrades()
    }

    private func updateRecentTrades() {
        var filteredTrades = trades

        switch selectedTimeRange {
        case "Today":
            filteredTrades = trades.filter { Calendar.current.isDateInToday($0.timestamp) }
        case "1 Week":
            filteredTrades = trades.filter {
                let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                return $0.timestamp > weekAgo
            }
        case "1 Month":
            filteredTrades = trades.filter {
                let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
                return $0.timestamp > monthAgo
            }
        case "3 Months":
            filteredTrades = trades.filter {
                let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: Date())!
                return $0.timestamp > threeMonthsAgo
            }
        default:
            break // All time - no filtering
        }

        recentTrades = filteredTrades.sorted(by: { $0.timestamp > $1.timestamp })
    }

    private func updateEquityCurve() {
        // Calculate equity curve based on filtered trades
        guard !trades.isEmpty else {
            equityPoints = []
            return
        }

        var runningBalance = 50000.0 // Starting balance
        var points: [EquityPoint] = []
        var sortedTrades = trades.sorted(by: { $0.timestamp < $1.timestamp })

        let calendar = Calendar.current

        // Group trades by date for equity curve
        let groupedTrades = Dictionary(grouping: sortedTrades) { trade in
            calendar.startOfDay(for: trade.timestamp)
        }

        for date in groupedTrades.keys.sorted() {
            let dayTrades = groupedTrades[date]!
            for trade in dayTrades {
                runningBalance += trade.pnl ?? 0
            }

            points.append(EquityPoint(date: date, value: runningBalance))
        }

        equityPoints = points
    }

    private func calculateMaxDrawdown() -> Double {
        var peak = 50000.0 // Starting balance
        var maxDrawdown = 0.0

        for equityPoint in equityPoints {
            if equityPoint.value > peak {
                peak = equityPoint.value
            }

            let drawdown = peak - equityPoint.value
            if drawdown > maxDrawdown {
                maxDrawdown = drawdown
            }
        }

        return maxDrawdown
    }

    private func calculateSharpeRatio() -> Double {
        guard trades.count >= 2 else { return 0.0 }

        let returns = trades.compactMap { $0.pnl }.filter { $0 != 0 }
        guard !returns.isEmpty else { return 0.0 }

        let avgReturn = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.reduce(0) { $0 + pow($1 - avgReturn, 2) } / Double(returns.count)
        let stdDev = sqrt(variance)

        // Assuming risk-free rate of 2% annually, daily equivalent
        let riskFreeRate = 0.02 / 365.0

        return stdDev == 0 ? 0 : (avgReturn - riskFreeRate) / stdDev
    }

    private func tradesThisMonthCount() -> Int {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        return trades.filter { $0.timestamp > monthAgo }.count
    }

    private func calculateMonthlyPerformances() -> [MonthlyPerformance] {
        let calendar = Calendar.current

        let monthlyTrades = Dictionary(grouping: trades) { trade in
            calendar.dateComponents([.year, .month], from: trade.timestamp)
        }

        return monthlyTrades.map { components, trades in
            let pnl = trades.reduce(0) { $0 + ($1.pnl ?? 0) }

            let monthString: String
            if let date = calendar.date(from: components) {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM yy"
                monthString = formatter.string(from: date)
            } else {
                monthString = "Unknown"
            }

            return MonthlyPerformance(
                month: components,
                monthString: monthString,
                pnl: pnl,
                tradeCount: trades.count
            )
        }
        .sorted(by: { $0.month > $1.month })
    }

    private func loadMockData() {
        // Add some mock trades for demo purposes
        let now = Date()
        let calendar = Calendar.current

        trades = []

        // Generate some recent trades
        for i in 1...20 {
            let randomDays = Int.random(in: 0...30)
            let timestamp = calendar.date(byAdding: .day, value: -randomDays, to: now)!

            let direction: TradeDirection = Bool.random() ? .buy : .sell
            let pnl = Double.random(in: -100...200)

            let trade = TradeJournalEntry(
                pair: ["EURUSD", "GBPUSD", "USDJPY", "USDCHF", "AUDUSD"].randomElement()!,
                direction: direction,
                entryPrice: Double.random(in: 1.05...1.15),
                exitPrice: Double.random(in: 1.05...1.15),
                pnl: pnl,
                timestamp: timestamp,
                strategy: ["EMA Crossover", "RSI Divergence", "Breakout", "Reversal"].randomElement()!
            )

            trades.append(trade)
        }

        trades.sort(by: { $0.timestamp > $1.timestamp })
    }

    private func saveTrades() {
        // In a real app, save to Core Data or similar
        // For now, just persist to UserDefaults
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(trades)
            UserDefaults.standard.set(data, forKey: "savedTrades")
        } catch {
            print("Failed to save trades: \(error)")
        }
    }

    private func loadTrades() {
        // In a real app, load from Core Data or similar
        do {
            if let data = UserDefaults.standard.data(forKey: "savedTrades") {
                let decoder = JSONDecoder()
                trades = try decoder.decode([TradeJournalEntry].self, from: data)
            }
        } catch {
            print("Failed to load trades: \(error)")
        }
    }
}

// Data Models
struct TradeJournalEntry: Identifiable, Codable, Equatable {
    let id = UUID()
    let pair: String
    let direction: TradeDirection
    let entryPrice: Double
    var exitPrice: Double?
    var pnl: Double?
    let timestamp: Date
    var strategy: String
    var notes: String?
}

enum TradeDirection: String, Codable {
    case buy, sell
}

struct EquityPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct MonthlyPerformance {
    let month: DateComponents
    let monthString: String
    let pnl: Double
    let tradeCount: Int
}

// Additional Views
struct TradeStatisticsView: View {
    @ObservedObject var viewModel: TradeJournalViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Advanced Statistics
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Advanced Statistics")
                            .font(.title2)
                            .fontWeight(.bold)

                        VStack(spacing: 16) {
                            StatRow(title: "Expectancy", value: "$\(String(format: "%.2f", viewModel.averageTradePnL))")
                            StatRow(title: "Profit Factor", value: "\(String(format: "%.2f", calculateProfitFactor()))")
                            StatRow(title: "Recovery Factor", value: "\(String(format: "%.2f", calculateRecoveryFactor()))")
                            StatRow(title: "Consecutive Wins", value: "\(calculateConsecutiveStats().wins)")
                            StatRow(title: "Consecutive Losses", value: "\(calculateConsecutiveStats().losses)")
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)

                    // Trading Psychology
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Trading Psychology")
                            .font(.title2)
                            .fontWeight(.bold)

                        VStack(spacing: 12) {
                            PsychologyIndicator(title: "Wins vs Losses", value: viewModel.winRate >= 0.5 ? "Healthy" : "Needs Improvement")
                            PsychologyIndicator(title: "Risk Management", value: "Good")
                            PsychologyIndicator(title: "Consistency", value: "Developing")
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                }
                .padding()
            }
            .navigationTitle("Statistics")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private func calculateProfitFactor() -> Double {
        let grossProfit = viewModel.trades.reduce(0) { $0 + max($1.pnl ?? 0, 0) }
        let grossLoss = abs(viewModel.trades.reduce(0) { $0 + min($1.pnl ?? 0, 0) })
        return grossLoss == 0 ? 0 : grossProfit / grossLoss
    }

    private func calculateRecoveryFactor() -> Double {
        return viewModel.totalPnL / max(viewModel.maxDrawdown, 1)
    }

    private func calculateConsecutiveStats() -> (wins: Int, losses: Int) {
        var maxWins = 0
        var maxLosses = 0
        var currentWins = 0
        var currentLosses = 0

        for trade in viewModel.trades {
            if (trade.pnl ?? 0) > 0 {
                currentWins += 1
                currentLosses = 0
                maxWins = max(maxWins, currentWins)
            } else {
                currentLosses += 1
                currentWins = 0
                maxLosses = max(maxLosses, currentLosses)
            }
        }

        return (maxWins, maxLosses)
    }
}

struct StatRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

struct PsychologyIndicator: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(psychologyColor(for: value))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(psychologyColor(for: value).opacity(0.2))
                .cornerRadius(8)
        }
    }

    private func psychologyColor(for value: String) -> Color {
        switch value {
        case "Healthy", "Good": return .green
        case "Needs Improvement", "Developing": return .orange
        default: return .gray
        }
    }
}

struct AddTradeView: View {
    @ObservedObject var viewModel: TradeJournalViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedPair = "EURUSD"
    @State private var direction: TradeDirection = .buy
    @State private var entryPrice = ""
    @State private var exitPrice = ""
    @State private var pnl = ""
    @State private var selectedStrategy = "EMA Crossover"
    @State private var notes = ""

    let pairs = ["EURUSD", "GBPUSD", "USDJPY", "USDCHF", "AUDUSD", "USDCAD", "NZDUSD"]
    let strategies = ["EMA Crossover", "RSI Divergence", "Breakout", "Reversal", "Manual"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trade Details")) {
                    Picker("Currency Pair", selection: $selectedPair) {
                        ForEach(pairs, id: \.self) {
                            Text($0)
                        }
                    }

                    Picker("Direction", selection: $direction) {
                        Text("Buy").tag(TradeDirection.buy)
                        Text("Sell").tag(TradeDirection.sell)
                    }
                    .pickerStyle(.segmented)

                    TextField("Entry Price", text: $entryPrice)
                        .keyboardType(.decimalPad)

                    TextField("Exit Price", text: $exitPrice)
                        .keyboardType(.decimalPad)

                    TextField("P&L", text: $pnl)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Strategy & Notes")) {
                    Picker("Strategy", selection: $selectedStrategy) {
                        ForEach(strategies, id: \.self) {
                            Text($0)
                        }
                    }

                    TextField("Notes (optional)", text: $notes)
                }

                Section {
                    Button(action: saveTrade) {
                        Text("Save Trade")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.blue)
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Add Trade")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }

    private var isFormValid: Bool {
        Double(entryPrice) != nil &&
        Double(exitPrice) != nil &&
        Double(pnl) != nil &&
        !selectedPair.isEmpty
    }

    private func saveTrade() {
        let trade = TradeJournalEntry(
            pair: selectedPair,
            direction: direction,
            entryPrice: Double(entryPrice)!,
            exitPrice: Double(exitPrice)!,
            pnl: Double(pnl)!,
            timestamp: Date(),
            strategy: selectedStrategy,
            notes: notes.isEmpty ? nil : notes
        )

        viewModel.addTrade(trade)
        presentationMode.wrappedValue.dismiss()
    }
}

struct TradeJournalView_Previews: PreviewProvider {
    static var previews: some View {
        TradeJournalView()
    }
}
