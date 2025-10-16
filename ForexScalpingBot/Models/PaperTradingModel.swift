//
//  PaperTradingModel.swift
//  ForexScalpingBot
//
//  Created by Cline on 10/16/2025.
//

import Foundation

// Paper Trading Account Model
struct PaperTradingAccount {
    var accountNumber: String
    var balance: Double
    var availableMargin: Double
    var usedMargin: Double
    var equity: Double
    var leverage: Int
    var currency: String = "USD"

    // Risk management settings
    var maxDrawdownPercent: Double = 10.0
    var maxDailyLossPercent: Double = 5.0
    var maxOpenTrades: Int = 5

    // Performance tracking
    var totalDeposits: Double = 100000.0
    var totalWithdrawals: Double = 0.0
    var totalTrades: Int = 0
    var winningTrades: Int = 0
    var losingTrades: Int = 0
    var grossProfit: Double = 0.0
    var grossLoss: Double = 0.0
    var largestWin: Double = 0.0
    var largestLoss: Double = 0.0

    var netProfit: Double {
        grossProfit - grossLoss
    }

    var winRate: Double {
        totalTrades > 0 ? Double(winningTrades) / Double(totalTrades) : 0.0
    }

    var profitFactor: Double {
        grossLoss > 0 ? grossProfit / grossLoss : 0.0
    }

    var currentDrawdown: Double {
        let peak = totalDeposits + netProfit
        return peak > equity ? peak - equity : 0.0
    }

    var currentDrawdownPercent: Double {
        let peak = totalDeposits + netProfit
        return peak > 0 ? currentDrawdown / peak * 100.0 : 0.0
    }

    var marginLevel: Double {
        usedMargin > 0 ? equity / usedMargin * 100.0 : 0.0
    }

    var freeMargin: Double {
        max(equity - usedMargin, 0)
    }

    func canOpenTrade(withLots lots: Double, pair: String, leverage: Int = 100) -> (canOpen: Bool, reason: String?) {
        // Check if account has enough margin
        let requiredMargin = calculateRequiredMargin(lots: lots, pair: pair, leverage: leverage)
        if availableMargin < requiredMargin {
            return (false, "Insufficient margin. Required: $\(requiredMargin) Available: $\(availableMargin)")
        }

        // Check if max trades limit is reached
        if maxOpenTrades <= 0 {  // Unlimited trades
            return (true, nil)
        }

        // This would need to be checked against actual open trades in real implementation
        // For now, we'll assume it's allowed
        return (true, nil)
    }

    func calculateRequiredMargin(lots: Double, pair: String, leverage: Int) -> Double {
        // Standard margin calculation: Notional Value / Leverage
        let contractSize = 100000.0 // Standard forex lot size
        let notionalValue = lots * contractSize

        return notionalValue / Double(leverage)
    }
}

// Paper Trading Position Model
struct PaperTradingPosition {
    let id = UUID()
    let pair: String
    let direction: TradeDirection
    let lots: Double
    let entryPrice: Double
    var exitPrice: Double?
    let stopLoss: Double?
    let takeProfit: Double?
    var swapCharge: Double = 0.0
    let commission: Double = 0.0
    let timestamp: Date

    var status: PositionStatus = .open

    // Current P&L calculations
    var currentPnL: Double {
        guard let currentPrice = getCurrentPrice(for: pair) else { return 0.0 }

        if direction == .buy {
            return (currentPrice - entryPrice) * lots * 100000.0
        } else {
            return (entryPrice - currentPrice) * lots * 100000.0
        }
    }

    var floatingPnL: Double {
        currentPnL
    }

    var usedMargin: Double {
        // Simplified margin calculation
        let contractSize = 100000.0
        let notionalValue = lots * contractSize
        let leverage = 100.0 // Default leverage

        return notionalValue / leverage
    }

    // Helper function to get current price (would be from real API)
    private func getCurrentPrice(for pair: String) -> Double? {
        // Mock current price - in real implementation, this would come from live data
        return Double.random(in: 1.08...1.12)
    }

    mutating func close(at price: Double, at time: Date = Date()) {
        exitPrice = price
        status = .closed

        // Calculate final P&L
        let finalPnL: Double
        if direction == .buy {
            finalPnL = (price - entryPrice) * lots * 100000.0
        } else {
            finalPnL = (entryPrice - price) * lots * 100000.0
        }

        // Could update account with final P&L here
    }

    enum PositionStatus {
        case open, closed, cancelled
    }

    var profitInPips: Double {
        guard let exitPrice = exitPrice else { return 0.0 }

        if direction == .buy {
            return (exitPrice - entryPrice) / 0.0001
        } else {
            return (entryPrice - exitPrice) / 0.0001
        }
    }

    var isClosed: Bool {
        status == .closed
    }
}

// Paper Trading Order Model
struct PaperTradingOrder {
    let id = UUID()
    let pair: String
    let direction: TradeDirection
    let orderType: OrderType
    let lots: Double
    let price: Double // For limit/stop orders
    let stopLoss: Double?
    let takeProfit: Double?
    let timestamp: Date

    var status: OrderStatus = .pending

    enum OrderType {
        case market, limit, stop
    }

    enum OrderStatus {
        case pending, filled, cancelled, expired
    }

    var isPending: Bool {
        status == .pending
    }

    var isFilled: Bool {
        status == .filled
    }
}

// Trade Alert System for Paper Trading
struct PaperTradingAlert {
    let id = UUID()
    let type: AlertType
    let message: String
    let timestamp: Date
    var isRead: Bool = false

    enum AlertType {
        case tradeOpened, tradeClosed, stopLossHit, takeProfitHit, marginCall, drawdownWarning
    }
}

// Paper Trading Statistics
struct PaperTradingStats {
    var period: String // "Today", "Week", "Month", etc.
    var totalTrades: Int
    var winningTrades: Int
    var losingTrades: Int
    var winRate: Double
    var profitFactor: Double
    var averageWin: Double
    var averageLoss: Double
    var largestWin: Double
    var largestLoss: Double
    var maxDrawdown: Double
    var expectancy: Double
    var sharpeRatio: Double
    var calmarRatio: Double
    var recoveryFactor: Double

    var netProfit: Double
    var totalVolume: Double
    var averageHoldingTime: TimeInterval
    var bestDay: Double
    var worstDay: Double
    var currentStreak: Int
    var longestWinStreak: Int
    var longestLossStreak: Int

    static var empty: PaperTradingStats {
        PaperTradingStats(
            period: "Today",
            totalTrades: 0,
            winningTrades: 0,
            losingTrades: 0,
            winRate: 0.0,
            profitFactor: 0.0,
            averageWin: 0.0,
            averageLoss: 0.0,
            largestWin: 0.0,
            largestLoss: 0.0,
            maxDrawdown: 0.0,
            expectancy: 0.0,
            sharpeRatio: 0.0,
            calmarRatio: 0.0,
            recoveryFactor: 0.0,
            netProfit: 0.0,
            totalVolume: 0.0,
            averageHoldingTime: 0.0,
            bestDay: 0.0,
            worstDay: 0.0,
            currentStreak: 0,
            longestWinStreak: 0,
            longestLossStreak: 0
        )
    }
}

// Risk Management Rules for Paper Trading
struct PaperTradingRiskRules {
    var maxPositionSizePercent: Double = 2.0 // Max position size as % of equity
    var maxDailyLossPercent: Double = 3.0 // Max daily loss as % of equity
    var maxDrawdownPercent: Double = 10.0 // Max drawdown as % of equity
    var maxOpenPositions: Int = 5
    var requiredMarginCallLevel: Double = 100.0 // Margin call at 100%
    var stopOutLevel: Double = 50.0 // Stop out at 50%
    var maxLeverage: Int = 100
    var restrictTradingHours: Bool = false
    var tradingSessions: [TradingSession] = []

    struct TradingSession {
        let name: String
        let startTime: Date
        let endTime: Date
    }

    func checkTradeAllowed(positionSize: Double, equity: Double) -> (allowed: Bool, reason: String?) {
        let maxPositionSize = equity * (maxPositionSizePercent / 100.0)

        if positionSize > maxPositionSize {
            return (false, "Position size ($$\(positionSize)) exceeds maximum allowed ($$\(maxPositionSize))")
        }

        return (true, nil)
    }

    func checkMarginLevel(equity: Double, usedMargin: Double) -> MarginStatus {
        let marginLevel = usedMargin > 0 ? equity / usedMargin * 100.0 : 0.0

        if marginLevel <= stopOutLevel {
            return .stopOut
        } else if marginLevel <= requiredMarginCallLevel {
            return .marginCall
        }

        return .safe
    }

    enum MarginStatus {
        case safe, marginCall, stopOut
    }
}
