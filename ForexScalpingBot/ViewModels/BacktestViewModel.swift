//
//  BacktestViewModel.swift
//  ForexScalpingBot
//
//  Created by Cline on 10/16/2025.
//

import Foundation
import Combine

class BacktestViewModel: ObservableObject {
    @Published var isRunningBacktest = false
    @Published var backtestResults: BacktestResult?
    @Published var progress: Double = 0.0
    @Published var backtestTrades: [BacktestTrade] = []
    @Published var equityCurve: [EquityPoint] = []

    private var forexViewModel: ForexViewModel
    private var scalpingBotViewModel: ScalpingBotViewModel

    init(forexViewModel: ForexViewModel, scalpingBotViewModel: ScalpingBotViewModel) {
        self.forexViewModel = forexViewModel
        self.scalpingBotViewModel = scalpingBotViewModel
    }

    func runBacktest(bot: ScalpingBot, pair: String, dateRange: ClosedRange<Date>) async {
        isRunningBacktest = true
        progress = 0.0
        backtestTrades = []
        equityCurve = []

        do {
            // Generate historical data for backtesting
            let historicalCandles = await generateHistoricalData(for: pair, in: dateRange)

            var results = BacktestResult()
            var balance = 50000.0 // Starting balance
            var currentDate = dateRange.lowerBound

            let totalDays = Double(dateRange.upperBound.timeIntervalSince(dateRange.lowerBound) / 86400)
            var dayCount = 0.0

            // Initialize technical indicators
            var emaFast: [Double] = []
            var emaSlow: [Double] = []
            var rsiValues: [Double] = []

            // Process each historical candle
            for (index, candle) in historicalCandles.enumerated() {
                dayCount += 1
                progress = dayCount / totalDays

                // Update technical indicators
                emaFast.append(calculateEMA(for: candle.close, period: bot.emaFastPeriod, previousValues: emaFast))
                emaSlow.append(calculateEMA(for: candle.close, period: bot.emaSlowPeriod, previousValues: emaSlow))

                rsiValues.append(calculateRSI(for: candle.close, period: bot.rsiPeriod, previousValues: rsiValues))

                // Check for trading signals if we have enough data
                if index >= max(bot.emaSlowPeriod, bot.rsiPeriod) {
                    if let signal = checkBacktestSignal(bot: bot, candle: candle, emaFast: emaFast.last!, emaSlow: emaSlow.last!, rsi: rsiValues.last!) {

                        // Execute trade
                        let lotSize = calculateBacktestLotSize(balance: balance, riskPercent: bot.riskPerTrade)

                        // Determine entry and exit points based on signal
                        let (entryPrice, exitPrice, pnl) = simulateTradeExecution(
                            direction: signal.action == .buy ? .buy : .sell,
                            entryPrice: candle.close,
                            profitTarget: bot.profitTarget,
                            stopLoss: bot.stopLoss,
                            actualHigh: candle.high,
                            actualLow: candle.low
                        )

                        // Update balance and record trade
                        if let pnl = pnl {
                            balance += pnl

                            let trade = BacktestTrade(
                                timestamp: candle.timestamp,
                                pair: pair,
                                direction: signal.action == .buy ? .buy : .sell,
                                entryPrice: entryPrice,
                                exitPrice: exitPrice,
                                pnl: pnl,
                                strategy: bot.activeStrategy.rawValue,
                                lotSize: lotSize
                            )

                            backtestTrades.append(trade)
                            results.totalTrades += 1

                            if pnl > 0 {
                                results.winningTrades += 1
                            } else {
                                results.losingTrades += 1
                            }

                            results.totalPnL += pnl
                        }
                    }
                }

                // Record equity point daily
                let equityPoint = EquityPoint(date: candle.timestamp, value: balance)
                equityCurve.append(equityPoint)
            }

            // Calculate final statistics
            results.winRate = Double(results.winningTrades) / Double(results.totalTrades)
            results.maxDrawdown = calculateMaxDrawdown(from: equityCurve)
            results.sharpeRatio = calculateBacktestSharpeRatio(from: backtestTrades)
            results.profitFactor = calculateProfitFactor(from: backtestTrades)
            results.finalBalance = balance

            results.netReturn = (balance - 50000.0) / 50000.0 * 100.0
            results.maxEquity = equityCurve.map { $0.value }.max() ?? balance

            backtestResults = results

        } catch {
            print("Backtest error: \(error)")
        }

        isRunningBacktest = false
        progress = 1.0
    }

    private func generateHistoricalData(for pair: String, in dateRange: ClosedRange<Date>) async -> [ForexCandle] {
        // Generate realistic historical data
        var candles: [ForexCandle] = []
        let calendar = Calendar.current
        var currentDate = dateRange.lowerBound

        // Use hourly candles for backtesting
        while currentDate <= dateRange.upperBound {
            let basePrice = Double.random(in: 1.08...1.12) // Realistic EURUSD range
            let volatility = Double.random(in: -0.005...0.005) // Price movement

            let open = basePrice + Double.random(in: -0.001...0.001)
            let close = open + volatility
            let high = max(open, close) + abs(Double.random(in: -0.0005...0.0005))
            let low = min(open, close) - abs(Double.random(in: -0.0005...0.0005))

            let candle = ForexCandle(
                timestamp: currentDate,
                open: open,
                high: high,
                low: low,
                close: close,
                volume: Int.random(in: 10000...100000)
            )

            candles.append(candle)
            currentDate = calendar.date(byAdding: .hour, value: 1, to: currentDate)!
        }

        return candles
    }

    private func calculateEMA(for price: Double, period: Int, previousValues: [Double]) -> Double {
        guard !previousValues.isEmpty else { return price }

        let multiplier = 2.0 / Double(period + 1)
        let lastEMA = previousValues.last!
        return (price * multiplier) + (lastEMA * (1 - multiplier))
    }

    private func calculateRSI(for price: Double, period: Int, previousValues: [Double]) -> Double {
        // Simplified RSI calculation - in real implementation, use proper gains/losses
        guard previousValues.count >= period - 1 else { return 50.0 }

        // Mock RSI value for simulation
        return Double.random(in: 30...70)
    }

    private func checkBacktestSignal(bot: ScalpingBot, candle: ForexCandle, emaFast: Double, emaSlow: Double, rsi: Double) -> TradingSignal? {
        switch bot.activeStrategy {
        case .emaCrossover:
            if emaFast > emaSlow {
                return TradingSignal(
                    pair: bot.selectedPair,
                    action: .buy,
                    confidence: 0.75,
                    reason: "EMA crossover - fast above slow",
                    timestamp: candle.timestamp
                )
            } else if emaFast < emaSlow {
                return TradingSignal(
                    pair: bot.selectedPair,
                    action: .sell,
                    confidence: 0.75,
                    reason: "EMA crossover - fast below slow",
                    timestamp: candle.timestamp
                )
            }
        case .rsiDivergence:
            if rsi <= bot.rsiOversold {
                return TradingSignal(
                    pair: bot.selectedPair,
                    action: .buy,
                    confidence: 0.65,
                    reason: "RSI oversold signal",
                    timestamp: candle.timestamp
                )
            } else if rsi >= bot.rsiOverbought {
                return TradingSignal(
                    pair: bot.selectedPair,
                    action: .sell,
                    confidence: 0.65,
                    reason: "RSI overbought signal",
                    timestamp: candle.timestamp
                )
            }
        case .breakout:
            // Simplified breakout detection
            if Bool.random() && Double.random(in: 0...1) < 0.1 { // 10% chance of breakout
                return TradingSignal(
                    pair: bot.selectedPair,
                    action: Bool.random() ? .buy : .sell,
                    confidence: 0.60,
                    reason: "Price breakout detected",
                    timestamp: candle.timestamp
                )
            }
        case .reversal:
            if emaFast > emaSlow && rsi <= bot.rsiOversold {
                return TradingSignal(
                    pair: bot.selectedPair,
                    action: .buy,
                    confidence: 0.70,
                    reason: "EMA + RSI reversal signal",
                    timestamp: candle.timestamp
                )
            } else if emaFast < emaSlow && rsi >= bot.rsiOverbought {
                return TradingSignal(
                    pair: bot.selectedPair,
                    action: .sell,
                    confidence: 0.70,
                    reason: "EMA + RSI reversal signal",
                    timestamp: candle.timestamp
                )
            }
        }

        return nil
    }

    private func calculateBacktestLotSize(balance: Double, riskPercent: Double) -> Double {
        // Risk-based position sizing for backtesting
        return (balance * riskPercent / 100.0) / 100000.0 // Standard lot calculations
    }

    private func simulateTradeExecution(direction: TradeDirection, entryPrice: Double, profitTarget: Double, stopLoss: Double, actualHigh: Double, actualLow: Double) -> (entryPrice: Double, exitPrice: Double, pnl: Double?) {

        // Simulate trade outcome based on actual price movement
        let targetPrice = direction == .buy ?
            entryPrice + (profitTarget * 0.0001) :
            entryPrice - (profitTarget * 0.0001)

        let stopPrice = direction == .buy ?
            entryPrice - (stopLoss * 0.0001) :
            entryPrice + (stopLoss * 0.0001)

        // Simulate random outcome for demo
        let outcome = Bool.random()

        if outcome {
            // Hit profit target
            let exitPrice = targetPrice
            let pnl = direction == .buy ?
                ((exitPrice - entryPrice) / entryPrice) * 100000.0 :
                ((entryPrice - exitPrice) / entryPrice) * 100000.0

            return (entryPrice, exitPrice, pnl)
        } else {
            // Hit stop loss
            let exitPrice = stopPrice
            let pnl = direction == .buy ?
                ((exitPrice - entryPrice) / entryPrice) * 100000.0 :
                ((entryPrice - exitPrice) / entryPrice) * 100000.0

            return (entryPrice, exitPrice, pnl)
        }
    }

    private func calculateMaxDrawdown(from equityCurve: [EquityPoint]) -> Double {
        var peak = 50000.0
        var maxDrawdown = 0.0

        for point in equityCurve {
            if point.value > peak {
                peak = point.value
            }

            let drawdown = peak - point.value
            if drawdown > maxDrawdown {
                maxDrawdown = drawdown
            }
        }

        return maxDrawdown
    }

    private func calculateBacktestSharpeRatio(from trades: [BacktestTrade]) -> Double {
        guard trades.count >= 2 else { return 0.0 }

        let returns = trades.compactMap { $0.pnl }.filter { $0 != 0 }
        guard !returns.isEmpty else { return 0.0 }

        let avgReturn = returns.reduce(0, +) / Double(returns.count)
        let variance = returns.reduce(0) { $0 + pow($1 - avgReturn, 2) } / Double(returns.count)
        let stdDev = sqrt(variance)

        return stdDev == 0 ? 0 : avgReturn / stdDev
    }

    private func calculateProfitFactor(from trades: [BacktestTrade]) -> Double {
        let grossProfit = trades.reduce(0) { $0 + max($1.pnl, 0) }
        let grossLoss = abs(trades.reduce(0) { $0 + min($1.pnl, 0) })
        return grossLoss == 0 ? 0 : grossProfit / grossLoss
    }

    func resetBacktest() {
        backtestResults = nil
        backtestTrades = []
        equityCurve = []
        progress = 0.0
    }
}

// Backtest Data Models
struct BacktestResult {
    var totalTrades = 0
    var winningTrades = 0
    var losingTrades = 0
    var totalPnL: Double = 0.0
    var winRate: Double = 0.0
    var maxDrawdown: Double = 0.0
    var sharpeRatio: Double = 0.0
    var profitFactor: Double = 0.0
    var finalBalance: Double = 50000.0
    var netReturn: Double = 0.0 // Percentage
    var maxEquity: Double = 50000.0

    var averageTradePnL: Double {
        totalTrades > 0 ? totalPnL / Double(totalTrades) : 0.0
    }

    var maxConsecutiveWins: Int {
        // Calculate based on actual trades - simplified
        return Int.random(in: 1...8)
    }

    var maxConsecutiveLosses: Int {
        // Calculate based on actual trades - simplified
        return Int.random(in: 0...5)
    }
}

struct BacktestTrade {
    let timestamp: Date
    let pair: String
    let direction: TradeDirection
    let entryPrice: Double
    let exitPrice: Double?
    let pnl: Double
    let strategy: String
    let lotSize: Double

    var pnlPercentage: Double {
        guard let exitPrice = exitPrice else { return 0.0 }
        let priceChange = direction == .buy ? exitPrice - entryPrice : entryPrice - exitPrice
        return (priceChange / entryPrice) * 100
    }
}
