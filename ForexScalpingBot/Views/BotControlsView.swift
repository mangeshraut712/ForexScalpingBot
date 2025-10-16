//
//  BotControlsView.swift
//  ForexScalpingBot
//
//  Created by Cline on 10/16/2025.
//

import SwiftUI

struct BotControlsView: View {
    @StateObject private var forexViewModel = ForexViewModel()
    @StateObject private var botViewModel: ScalpingBotViewModel

    @State private var showingSettings = false
    @State private var showingTradeHistory = false

    init() {
        let forexVM = ForexViewModel()
        _botViewModel = StateObject(wrappedValue: ScalpingBotViewModel(forexViewModel: forexVM))
        _forexViewModel = StateObject(wrappedValue: forexVM)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Bot Status Card
                    BotStatusCard(botViewModel: botViewModel)

                    // Current Signal Card
                    if let signal = botViewModel.lastSignal {
                        SignalCard(signal: signal)
                    }

                    // Pending Trades
                    if !botViewModel.pendingTrades.isEmpty {
                        PendingTradesCard(trades: botViewModel.pendingTrades, botViewModel: botViewModel)
                    }

                    // Bot Settings
                    BotSettingsCard(botViewModel: botViewModel)

                    // Performance Metrics
                    PerformanceMetricsCard(botViewModel: botViewModel)

                    // Risk Management
                    RiskManagementCard(botViewModel: botViewModel)
                }
                .padding()
            }
            .navigationTitle("Scalping Bot")
            .navigationBarItems(
                trailing: HStack {
                    Button(action: { showingTradeHistory.toggle() }) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .imageScale(.large)
                    }
                    Button(action: { showingSettings.toggle() }) {
                        Image(systemName: "gear")
                            .imageScale(.large)
                    }
                }
            )
            .sheet(isPresented: $showingSettings) {
                BotSettingsView(botViewModel: botViewModel)
            }
            .sheet(isPresented: $showingTradeHistory) {
                TradeHistoryView(trades: botViewModel.tradeHistory)
            }
        }
    }
}

// Bot Status Card
struct BotStatusCard: View {
    @ObservedObject var botViewModel: ScalpingBotViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Bot Status")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { botViewModel.bot.isEnabled },
                    set: { _ in botViewModel.toggleBot() }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .labelsHidden()
            }

            HStack(spacing: 20) {
                VStack {
                    Text(botViewModel.bot.isEnabled ? "ACTIVE" : "INACTIVE")
                        .font(.headline)
                        .foregroundColor(botViewModel.bot.isEnabled ? .green : .red)

                    if botViewModel.isProcessingTrades {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    }
                }

                VStack(alignment: .leading) {
                    Text("Today's Trades")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(botViewModel.bot.todaysTrades)/\(botViewModel.bot.maxTradesPerDay)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                VStack(alignment: .leading) {
                    Text("Win Rate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", botViewModel.getWinRate() * 100))%")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(botViewModel.getWinRate() >= 0.5 ? .green : .red)
                }
            }

            if let error = botViewModel.error {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

// Signal Card
struct SignalCard: View {
    let signal: TradingSignal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: signal.action == .buy ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundColor(signal.action == .buy ? .green : .red)
                    .font(.title3)

                Text("Latest Signal")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text(signal.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text(signal.pair)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Text(signal.action.rawValue.uppercased())
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(signal.action == .buy ? .green : .red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(signal.action == .buy ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Confidence:")
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", signal.confidence * 100))%")
                        .foregroundColor(confidenceColor(confidence: signal.confidence))
                        .fontWeight(.medium)
                }

                Text("Reason: \(signal.reason)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Confidence bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundColor(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)

                    Rectangle()
                        .foregroundColor(confidenceColor(confidence: signal.confidence))
                        .frame(width: geometry.size.width * CGFloat(signal.confidence), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }

    private func confidenceColor(confidence: Double) -> Color {
        switch confidence {
        case 0.8...: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
}

// Pending Trades Card
struct PendingTradesCard: View {
    let trades: [ForexTrade]
    @ObservedObject var botViewModel: ScalpingBotViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pending Trades")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button(action: { botViewModel.cancelAllPendingTrades() }) {
                    Text("Cancel All")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }

            ForEach(trades.prefix(3)) { trade in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(trade.pair)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(trade.direction.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(trade.direction == .buy ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .foregroundColor(trade.direction == .buy ? .green : .red)
                            .cornerRadius(4)

                        Spacer()

                        Text("Lot: \(String(format: "%.2f", trade.lotSize))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Entry: \(String(format: "%.5f", trade.entryPrice))")
                                .font(.caption)
                            Text("SL: \(String(format: "%.5f", trade.stopLoss ?? 0))")
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("TP: \(String(format: "%.5f", trade.takeProfit ?? 0))")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("Risk: \(String(format: "%.2f", (trade.stopLoss ?? 0 - trade.entryPrice) * trade.lotSize * 100000))")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            if trades.count > 3 {
                Text("+\(trades.count - 3) more pending")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

// Bot Settings Card
struct BotSettingsCard: View {
    @ObservedObject var botViewModel: ScalpingBotViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bot Configuration")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Strategy")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(botViewModel.bot.activeStrategy.displayName)
                            .font(.headline)
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("Pair")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(botViewModel.bot.selectedPair)")
                            .font(.headline)
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("Risk/Trade")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", botViewModel.bot.riskPerTrade))%")
                            .font(.headline)
                    }
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Profit Target")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", botViewModel.bot.profitTarget)) pips")
                            .font(.subheadline)
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("Stop Loss")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", botViewModel.bot.stopLoss)) pips")
                            .font(.subheadline)
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("Max/Day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(botViewModel.bot.maxTradesPerDay)")
                            .font(.subheadline)
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

// Performance Metrics Card
struct PerformanceMetricsCard: View {
    @ObservedObject var botViewModel: ScalpingBotViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Metrics")
                .font(.title2)
                .fontWeight(.bold)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                MetricCell(
                    title: "Total P&L",
                    value: "$\(String(format: "%.2f", botViewModel.bot.totalPnL))",
                    color: botViewModel.bot.totalPnL >= 0 ? .green : .red
                )

                MetricCell(
                    title: "Win Rate",
                    value: "\(String(format: "%.1f", botViewModel.getWinRate() * 100))%",
                    color: botViewModel.getWinRate() >= 0.5 ? .green : .red
                )

                MetricCell(
                    title: "Total Trades",
                    value: "\(botViewModel.bot.totalTrades)",
                    color: .blue
                )

                MetricCell(
                    title: "Avg Trade Duration",
                    value: "2.3m",
                    color: .purple
                )

                MetricCell(
                    title: "Consecutive Wins",
                    value: "\(botViewModel.bot.consecutiveWins)",
                    color: botViewModel.bot.consecutiveWins >= 3 ? .green : .gray
                )

                MetricCell(
                    title: "Today's P&L",
                    value: "$\(String(format: "%.2f", botViewModel.getTodaysPnL()))",
                    color: botViewModel.getTodaysPnL() >= 0 ? .green : .red
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

struct MetricCell: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

// Risk Management Card
struct RiskManagementCard: View {
    @ObservedObject var botViewModel: ScalpingBotViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk Management")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                // Daily Risk Limits
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)

                    VStack(alignment: .leading) {
                        Text("Daily Risk Limits")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Max 1% risk per trade, \(botViewModel.bot.maxTradesPerDay) trades/day")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: {}) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }

                // Exposure Warning
                if !botViewModel.pendingTrades.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(.red)

                        VStack(alignment: .leading) {
                            Text("Active Exposure")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("\(botViewModel.pendingTrades.count) open position(s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }

                // Consecutive Losses Warning
                if botViewModel.bot.consecutiveLosses >= 3 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)

                        VStack(alignment: .leading) {
                            Text("Consecutive Losses: \(botViewModel.bot.consecutiveLosses)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            Text("Consider pausing the bot")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

// Bot Settings View
struct BotSettingsView: View {
    @ObservedObject var botViewModel: ScalpingBotViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedPair = "EURUSD"
    @State private var riskPerTrade = 1.0
    @State private var maxTradesPerDay = 10
    @State private var profitTarget = 5.0
    @State private var stopLoss = 3.0
    @State private var selectedStrategy = "EMACrossover"
    @State private var emaFast = 5
    @State private var emaSlow = 13

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trading Parameters")) {
                    Picker("Currency Pair", selection: $selectedPair) {
                        Text("EUR/USD").tag("EURUSD")
                        Text("GBP/USD").tag("GBPUSD")
                        Text("USD/JPY").tag("USDJPY")
                        Text("USD/CHF").tag("USDCHF")
                        Text("AUD/USD").tag("AUDUSD")
                    }

                    Picker("Strategy", selection: $selectedStrategy) {
                        Text("EMA Crossover").tag("EMACrossover")
                        Text("RSI Divergence").tag("RSIDivergence")
                        Text("Breakout").tag("Breakout")
                        Text("Reversal").tag("Reversal")
                    }

                    VStack {
                        HStack {
                            Text("Risk per Trade")
                            Spacer()
                            Text("\(String(format: "%.1f", riskPerTrade))%")
                        }
                        Slider(value: $riskPerTrade, in: 0.5...5.0, step: 0.5)
                    }

                    Stepper("Max Trades per Day: \(maxTradesPerDay)", value: $maxTradesPerDay, in: 1...50)

                    VStack {
                        HStack {
                            Text("Profit Target")
                            Spacer()
                            Text("\(String(format: "%.1f", profitTarget)) pips")
                        }
                        Slider(value: $profitTarget, in: 1...20, step: 0.5)
                    }

                    VStack {
                        HStack {
                            Text("Stop Loss")
                            Spacer()
                            Text("\(String(format: "%.1f", stopLoss)) pips")
                        }
                        Slider(value: $stopLoss, in: 1...10, step: 0.5)
                    }
                }

                Section(header: Text("Technical Indicators")) {
                    Stepper("EMA Fast: \(emaFast)", value: $emaFast, in: 3...20)
                    Stepper("EMA Slow: \(emaSlow)", value: $emaSlow, in: 10...50)
                }

                Section {
                    Button(action: saveSettings) {
                        Text("Save Settings")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.blue)
                    }
                    .disabled(!hasChanges)
                }
            }
            .navigationTitle("Bot Settings")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            // Load current settings
            selectedPair = botViewModel.bot.selectedPair
            riskPerTrade = botViewModel.bot.riskPerTrade
            maxTradesPerDay = botViewModel.bot.maxTradesPerDay
            profitTarget = botViewModel.bot.profitTarget
            stopLoss = botViewModel.bot.stopLoss
            emaFast = botViewModel.bot.emaFastPeriod
            emaSlow = botViewModel.bot.emaSlowPeriod
            selectedStrategy = botViewModel.bot.activeStrategy.rawValue
        }
    }

    private var hasChanges: Bool {
        selectedPair != botViewModel.bot.selectedPair ||
        riskPerTrade != botViewModel.bot.riskPerTrade ||
        maxTradesPerDay != botViewModel.bot.maxTradesPerDay ||
        profitTarget != botViewModel.bot.profitTarget ||
        stopLoss != botViewModel.bot.stopLoss ||
        emaFast != botViewModel.bot.emaFastPeriod ||
        emaSlow != botViewModel.bot.emaSlowPeriod ||
        selectedStrategy != botViewModel.bot.activeStrategy.rawValue
    }

    private func saveSettings() {
        var updatedBot = botViewModel.bot
        updatedBot.selectedPair = selectedPair
        updatedBot.riskPerTrade = riskPerTrade
        updatedBot.maxTradesPerDay = maxTradesPerDay
        updatedBot.profitTarget = profitTarget
        updatedBot.stopLoss = stopLoss
        updatedBot.emaFastPeriod = emaFast
        updatedBot.emaSlowPeriod = emaSlow

        switch selectedStrategy {
        case "EMACrossover":
            updatedBot.activeStrategy = .emaCrossover
        case "RSIDivergence":
            updatedBot.activeStrategy = .rsiDivergence
        case "Breakout":
            updatedBot.activeStrategy = .breakout
        case "Reversal":
            updatedBot.activeStrategy = .reversal
        default:
            break
        }

        botViewModel.updateBotSettings(updatedBot)
        presentationMode.wrappedValue.dismiss()
    }
}

// Trade History View
struct TradeHistoryView: View {
    let trades: [ForexTrade]
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List(trades.sorted(by: { $0.timestamp > $1.timestamp })) { trade in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(trade.pair)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(trade.direction.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(trade.direction == .buy ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .foregroundColor(trade.direction == .buy ? .green : .red)
                            .cornerRadius(4)

                        Spacer()

                        if let pnl = trade.pnl {
                            Text("\(pnl >= 0 ? "+" : "")$\(String(format: "%.2f", pnl))")
                                .foregroundColor(pnl >= 0 ? .green : .red)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }

                    HStack {
                        Text("Entry: \(String(format: "%.5f", trade.entryPrice))")
                            .font(.caption)
                        Spacer()
                        Text("Strategy: \(trade.strategy)")
                            .font(.caption)
                    }

                    HStack {
                        Text("Time: \(trade.timestamp.formatted())")
                            .font(.caption)
                        Spacer()
                        if let exitTimestamp = trade.exitTimestamp {
                            Text("Duration: \(formatDuration(from: trade.timestamp, to: exitTimestamp))")
                                .font(.caption)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Trade History")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }

    private func formatDuration(from start: Date, to end: Date) -> String {
        let interval = end.timeIntervalSince(start)
        let minutes = Int(interval / 60)
        let seconds = Int(interval) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

struct BotControlsView_Previews: PreviewProvider {
    static var previews: some View {
        BotControlsView()
    }
}
