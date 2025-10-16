//
//  ScalpingBotModel.swift
//  ForexScalpingBot
//
//  Created by Cline on 10/16/2025.
//

import Foundation

// Scalping Bot Model
struct ScalpingBot {
    var isEnabled: Bool = false
    var selectedPair: String = "EURUSD"
    var riskPerTrade: Double = 1.0 // % of account
    var maxTradesPerDay: Int = 10
    var profitTarget: Double = 5.0 // Pips
    var stopLoss: Double = 3.0 // Pips
    var emaFastPeriod: Int = 5
    var emaSlowPeriod: Int = 13
    var rsiPeriod: Int = 14
    var rsiOverbought: Double = 70.0
    var rsiOversold: Double = 30.0

    // EMA Crossover Strategies
    enum Strategy {
        case emaCrossover, rsiDivergence, breakout, reversal
    }

    var activeStrategy: Strategy = .emaCrossover

    // Bot Status
    var totalTrades: Int = 0
    var winningTrades: Int = 0
    var totalPnL: Double = 0.0
    var todaysTrades: Int = 0
    var consecutiveWins: Int = 0
    var consecutiveLosses: Int = 0
}

// Trade Model
struct ForexTrade {
    let id = UUID()
    let pair: String
    let direction: TradeDirection
    let entryPrice: Double
    var exitPrice: Double?
    var stopLoss: Double?
    var takeProfit: Double?
    let lotSize: Double
    let timestamp: Date
    var exitTimestamp: Date?
    var pnl: Double?
    var status: TradeStatus
    var strategy: String
    var notes: String?

    enum TradeDirection {
        case buy, sell
    }

    enum TradeStatus {
        case open, closed, cancelled
    }

    var isClosed: Bool {
        status == .closed
    }

    var tradeDuration: TimeInterval? {
        guard let exitTimestamp = exitTimestamp else { return nil }
        return exitTimestamp.timeIntervalSince(timestamp)
    }

    var pnlPercentage: Double? {
        guard let pnl = pnl, let exitPrice = exitPrice else { return nil }
        return (pnl / (entryPrice * lotSize)) * 100
    }
}

// EMA Calculation Utilities
class EMACalculator {
    private var prices: [Double] = []
    private var fastEMA: [Double] = []
    private var slowEMA: [Double] = []

    func addPrice(_ price: Double) {
        prices.append(price)
    }

    func calculateEMA(for period: Int) -> Double? {
        guard prices.count >= period else { return nil }

        let multiplier = 2.0 / Double(period + 1)

        // Use Wilder's smoothing for the first EMA value
        var ema = prices.prefix(period).reduce(0.0, +) / Double(period)

        // Calculate EMA for remaining values
        for price in prices.suffix(from: period) {
            ema = (price * multiplier) + (ema * (1 - multiplier))
        }

        return ema
    }

    func calculateEMAArray(period: Int) -> [Double] {
        guard prices.count >= period else { return [] }

        var emaValues: [Double] = []
        var multiplier = 2.0 / Double(period + 1)
        var ema = prices[0]

        emaValues.append(ema)

        for i in 1..<prices.count {
            ema = (prices[i] * multiplier) + (ema * (1 - multiplier))
            emaValues.append(ema)
        }

        return emaValues
    }

    func getEMACrossoverSignal() -> TraderAction? {
        guard prices.count >= max(13, prices.count) else { return nil }

        let fastEMA = calculateEMAArray(period: 5)
        let slowEMA = calculateEMAArray(period: 13)

        guard fastEMA.count >= 2, slowEMA.count >= 2 else { return nil }

        let lastFast = fastEMA.last!
        let prevFast = fastEMA[fastEMA.count - 2]
        let lastSlow = slowEMA.last!
        let prevSlow = slowEMA[slowEMA.count - 2]

        // Bullish crossover
        if prevFast <= prevSlow && lastFast > lastSlow {
            return .buy
        }
        // Bearish crossover
        else if prevFast >= prevSlow && lastFast < lastSlow {
            return .sell
        }

        return nil
    }

    enum TraderAction {
        case buy, sell, hold
    }
}

// RSI Calculation
class RSICalculator {
    private var gains: [Double] = []
    private var losses: [Double] = []

    func addPrice(_ price: Double) {
        if gains.count > 0 {
            let change = price - gains.last!
            if change > 0 {
                gains.append(change)
                losses.append(0)
            } else {
                gains.append(0)
                losses.append(abs(change))
            }
        } else {
            gains.append(0)
            losses.append(0)
        }
    }

    func calculateRSI(period: Int = 14) -> Double? {
        guard gains.count >= period, losses.count >= period else { return nil }

        let avgGain = gains.suffix(period).reduce(0, +) / Double(period)
        let avgLoss = losses.suffix(period).reduce(0, +) / Double(period)

        if avgLoss == 0 {
            return 100.0
        }

        let rs = avgGain / avgLoss
        return 100.0 - (100.0 / (1.0 + rs))
    }

    func getRSISignal(rsiOverbought: Double = 70.0, rsiOversold: Double = 30.0) -> EMACalculator.TraderAction? {
        guard let rsi = calculateRSI() else { return nil }

        if rsi <= rsiOversold {
            return .buy
        } else if rsi >= rsiOverbought {
            return .sell
        }

        return .hold
    }
}
