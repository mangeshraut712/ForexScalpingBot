//
//  ScalpingBotViewModel.swift
//  ForexScalpingBot
//
//  Created by Cline on 10/16/2025.
//

import Foundation
import Combine

class ScalpingBotViewModel: ObservableObject {
    @Published var bot: ScalpingBot
    @Published var isProcessingTrades = false
    @Published var lastSignal: TradingSignal?
    @Published var tradeHistory: [ForexTrade] = []
    @Published var pendingTrades: [ForexTrade] = []
    @Published var error: String?

    private var forexViewModel: ForexViewModel
    private var emaCalculator = EMACalculator()
    private var rsiCalculator = RSICalculator()
    private var cancellables = Set<AnyCancellable>()
    private var tradeTimer: Timer?

    init(forexViewModel: ForexViewModel) {
        self.forexViewModel = forexViewModel
        self.bot = ScalpingBot()

        setupSubscriptions()
        startSignalMonitoring()
    }

    private func setupSubscriptions() {
        // Monitor price changes for trading signals
        forexViewModel.$currentQuotes
            .sink { [weak self] quotes in
                self?.processPriceUpdates(quotes: quotes)
            }
            .store(in: &cancellables)
    }

    private func startSignalMonitoring() {
        tradeTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkForTradingSignals()
        }
    }

    private func processPriceUpdates(quotes: [String: ForexQuote]) {
        guard bot.isEnabled else { return }

        for (symbol, quote) in quotes {
            emaCalculator.addPrice(quote.bid)
            rsiCalculator.addPrice(quote.bid)

            // Update bot for each pair it's configured to trade
            if symbol == bot.selectedPair {
                checkForTradingSignals()
            }
        }
    }

    func toggleBot() {
        bot.isEnabled.toggle()

        if bot.isEnabled {
            startSignalMonitoring()
            checkForTradingSignals()
        } else {
            tradeTimer?.invalidate()
            cancelAllPendingTrades()
        }
    }

    func checkForTradingSignals() {
        guard bot.isEnabled, bot.todaysTrades < bot.maxTradesPerDay else { return }
        guard let currentQuote = forexViewModel.currentQuotes[bot.selectedPair] else { return }

        var signal: TradingSignal?

        switch bot.activeStrategy {
        case .emaCrossover:
            signal = checkEMACrossoverSignal()
        case .rsiDivergence:
            signal = checkRSIDivergenceSignal()
        case .breakout:
            signal = checkBreakoutSignal()
        case .reversal:
            signal = checkReversalSignal()
        }

        if let signal = signal {
            lastSignal = signal
            executeTrade(signal: signal, quote: currentQuote)
        }
    }

    private func checkEMACrossoverSignal() -> TradingSignal? {
        guard let action = emaCalculator.getEMACrossoverSignal() else { return nil }

        return TradingSignal(
            pair: bot.selectedPair,
            action: action == .buy ? .buy : .sell,
            confidence: 0.75,
            reason: "EMA crossover signal",
            timestamp: Date()
        )
    }

    private func checkRSIDivergenceSignal() -> TradingSignal? {
        guard let rsiAction = rsiCalculator.getRSISignal(rsiOverbought: bot.rsiOverbought, rsiOversold: bot.rsiOversold) else { return nil }

        guard rsiAction != .hold else { return nil }

        return TradingSignal(
            pair: bot.selectedPair,
            action: rsiAction == .buy ? .buy : .sell,
            confidence: 0.65,
            reason: "RSI oversold/overbought signal",
            timestamp: Date()
        )
    }

    private func checkBreakoutSignal() -> TradingSignal? {
        // Simplified breakout detection - in real implementation, use proper breakout patterns
        guard let currentQuote = forexViewModel.currentQuotes[bot.selectedPair] else { return nil }

        // Placeholder logic for breakout detection
        let recentPrices = forexViewModel.candles.suffix(20).map { $0.high }
        let recentLow = forexViewModel.candles.suffix(20).map { $0.low }.min() ?? 0
        let recentHigh = recentPrices.max() ?? 0

        if currentQuote.bid > recentHigh {
            return TradingSignal(
                pair: bot.selectedPair,
                action: .buy,
                confidence: 0.60,
                reason: "Price breakout above resistance",
                timestamp: Date()
            )
        } else if currentQuote.bid < recentLow {
            return TradingSignal(
                pair: bot.selectedPair,
                action: .sell,
                confidence: 0.60,
                reason: "Price breakout below support",
                timestamp: Date()
            )
        }

        return nil
    }

    private func checkReversalSignal() -> TradingSignal? {
        // Simplified reversal detection - combine multiple indicators
        let emaSignal = emaCalculator.getEMACrossoverSignal()
        let rsiSignal = rsiCalculator.getRSISignal()

        guard let emaAction = emaSignal, let rsiAction = rsiSignal else { return nil }

        // Only take reversal signals when EMA and RSI agree
        if emaAction == rsiAction {
            return TradingSignal(
                pair: bot.selectedPair,
                action: emaAction == .buy ? .buy : .sell,
                confidence: 0.70,
                reason: "EMA + RSI reversal confirmation",
                timestamp: Date()
            )
        }

        return nil
    }

    private func executeTrade(signal: TradingSignal, quote: ForexQuote) {
        guard bot.todaysTrades < bot.maxTradesPerDay else {
            error = "Maximum daily trades reached"
            return
        }

        let lotSize = calculateLotSize(quote: quote)
        let stopLoss = signal.action == .buy ?
            quote.bid - bot.stopLoss * 0.0001 : // Convert pips to price
            quote.bid + bot.stopLoss * 0.0001

        let takeProfit = signal.action == .buy ?
            quote.bid + bot.profitTarget * 0.0001 :
            quote.bid - bot.profitTarget * 0.0001

        let trade = ForexTrade(
            pair: signal.pair,
            direction: signal.action == .buy ? .buy : .sell,
            entryPrice: quote.bid,
            stopLoss: stopLoss,
            takeProfit: takeProfit,
            lotSize: lotSize,
            timestamp: signal.timestamp,
            status: .open,
            strategy: bot.activeStrategy.displayName
        )

        pendingTrades.append(trade)
        bot.todaysTrades += 1
        bot.totalTrades += 1

        isProcessingTrades = true

        // Simulate trade execution
        Task {
            try await Task.sleep(nanoseconds: 2_000_000_000) // Simulate execution delay
            await MainActor.run {
                self.processTradeOutcome(trade: trade, signal: signal)
                self.isProcessingTrades = false
            }
        }
    }

    private func calculateLotSize(quote: ForexQuote) -> Double {
        // Risk-based position sizing
        // Account value is approximately $50,000 (mock)
        let accountValue = 50000.0
        let riskAmount = accountValue * (bot.riskPerTrade / 100.0)
        let stopLossAmount = bot.stopLoss * 0.0001 // Convert pips to price units

        // Standard lot size calculation (simplified)
        return riskAmount / (stopLossAmount * 100000) // Micro-lot adjustment
    }

    private func processTradeOutcome(trade: ForexTrade, signal: TradingSignal) {
        // Simulate random outcome for demo purposes
        let outcome = Bool.random()

        if outcome {
            // Winning trade
            bot.winningTrades += 1
            bot.consecutiveWins += 1
            bot.consecutiveLosses = 0

            let pnl = (bot.profitTarget * 0.0001 * trade.lotSize * 100000)
            bot.totalPnL += pnl

            let closedTrade = ForexTrade(
                pair: trade.pair,
                direction: trade.direction,
                entryPrice: trade.entryPrice,
                exitPrice: trade.takeProfit,
                stopLoss: trade.stopLoss,
                takeProfit: trade.takeProfit,
                lotSize: trade.lotSize,
                timestamp: trade.timestamp,
                exitTimestamp: Date(),
                pnl: pnl,
                status: .closed,
                strategy: trade.strategy
            )

            tradeHistory.append(closedTrade)
        } else {
            // Losing trade
            bot.consecutiveWins = 0
            bot.consecutiveLosses += 1

            let pnl = -(bot.stopLoss * 0.0001 * trade.lotSize * 100000)
            bot.totalPnL += pnl

            let closedTrade = ForexTrade(
                pair: trade.pair,
                direction: trade.direction,
                entryPrice: trade.entryPrice,
                exitPrice: trade.stopLoss,
                stopLoss: trade.stopLoss,
                takeProfit: trade.takeProfit,
                lotSize: trade.lotSize,
                timestamp: trade.timestamp,
                exitTimestamp: Date(),
                pnl: pnl,
                status: .closed,
                strategy: trade.strategy
            )

            tradeHistory.append(closedTrade)
        }

        // Remove from pending trades
        pendingTrades.removeAll { $0.id == trade.id }
    }

    func cancelAllPendingTrades() {
        pendingTrades.removeAll()
    }

    func resetDailyStats() {
        bot.todaysTrades = 0
        bot.consecutiveWins = 0
        bot.consecutiveLosses = 0
    }

    func updateBotSettings(_ newBot: ScalpingBot) {
        self.bot = newBot
        error = nil
        if bot.isEnabled {
            checkForTradingSignals()
        }
    }

    func getWinRate() -> Double {
        guard bot.totalTrades > 0 else { return 0.0 }
        return Double(bot.winningTrades) / Double(bot.totalTrades)
    }

    func getTodaysPnL() -> Double {
        return tradeHistory
            .filter {
                let calendar = Calendar.current
                return calendar.isDateInToday($0.timestamp)
            }
            .compactMap { $0.pnl }
            .reduce(0, +)
    }

    deinit {
        tradeTimer?.invalidate()
        cancellables.removeAll()
    }
}

// Trading Signal Model
struct TradingSignal {
    let pair: String
    let action: TradeAction
    let confidence: Double
    let reason: String
    let timestamp: Date

    enum TradeAction: String {
        case buy
        case sell

        var displayName: String {
            rawValue.capitalized
        }
    }

    var description: String {
        "\(action.displayName.uppercased()) \(pair) - \(String(format: "%.1f", confidence * 100))% confidence"
    }
}
