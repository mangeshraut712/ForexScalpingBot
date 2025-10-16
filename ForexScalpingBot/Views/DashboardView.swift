//
//  DashboardView.swift
//  ForexScalpingBot
//
//  Created by Cline on 10/16/2025.
//

import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var forexViewModel = ForexViewModel()
    @State private var showingEconomicCalendar = false
    @State private var showingNews = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Portfolio Summary
                    PortfolioSummaryCard()

                    // Real-time Forex Cards
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                        ForEach(forexViewModel.forexPairs.prefix(6)) { pair in
                            if let quote = forexViewModel.currentQuotes[pair.symbol] {
                                ForexPriceCard(quote: quote)
                            } else {
                                ForexPriceCardPlaceholder(pair: pair)
                            }
                        }
                    }

                    // Charts Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Price Charts")
                            .font(.title2)
                            .fontWeight(.bold)

                        if let selectedPair = forexViewModel.selectedPair,
                           !forexViewModel.candles.isEmpty {
                            ChartCard(pair: selectedPair, candles: forexViewModel.candles)
                                .aspectRatio(16/9, contentMode: .fit)
                        } else {
                            EmptyChartCard()
                        }
                    }

                    // Economic Calendar Quick View
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Economic Calendar")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Button(action: { showingEconomicCalendar.toggle() }) {
                                Text("View All")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }

                        ForEach(forexViewModel.economicCalendar.prefix(3)) { event in
                            EconomicEventCard(event: event)
                        }
                    }

                    // AI Signals Alert
                    AISignalsCard()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarItems(
                trailing: Button(action: { showingNews.toggle() }) {
                    Image(systemName: "newspaper")
                }
            )
            .sheet(isPresented: $showingEconomicCalendar) {
                EconomicCalendarView()
            }
            .sheet(isPresented: $showingNews) {
                NewsView()
            }
        }
    }
}

// Portfolio Summary Card
struct PortfolioSummaryCard: View {
    @State private var accountBalance = 50000.0
    @State private var totalPnL = 1250.50
    @State private var pnlPercent = 2.45

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Portfolio Balance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("$\(accountBalance, specifier: "%.2f")")
                        .font(.title)
                        .fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Today's P&L")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    HStack {
                        Image(systemName: totalPnL >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(totalPnL >= 0 ? "+" : "")$\(totalPnL, specifier: "%.2f") (\(pnlPercent, specifier: "%.2f")%)")
                            .foregroundColor(totalPnL >= 0 ? .green : .red)
                            .font(.headline)
                    }
                }
            }

            // Mini Equity Curve
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
                .frame(height: 60)
                .overlay(
                    Text("Equity Curve Graph Placeholder")
                        .foregroundColor(.secondary)
                        .font(.caption)
                )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

// Forex Price Card
struct ForexPriceCard: View {
    let quote: ForexQuote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(quote.symbol)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("\(quote.bid, specifier: "%.5f")")
                .font(.headline)
                .fontWeight(.bold)

            HStack {
                Image(systemName: quote.change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .imageScale(.small)
                Text("\(quote.change >= 0 ? "+" : "")\(quote.changePercent, specifier: "%.2f")%")
                    .font(.caption)
                    .foregroundColor(quote.change >= 0 ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

struct ForexPriceCardPlaceholder: View {
    let pair: ForexPair

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(pair.symbol)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("--")
                .font(.headline)
                .fontWeight(.bold)

            HStack {
                Image(systemName: "circle")
                    .imageScale(.small)
                    .foregroundColor(.secondary)
                Text("--")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

// Chart Card
struct ChartCard: View {
    let pair: ForexPair
    let candles: [ForexCandle]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(pair.symbol) - 1H")
                .font(.headline)

            Chart {
                ForEach(candles.suffix(50), id: \.timestamp) { candle in
                    LineMark(
                        x: .value("Time", candle.timestamp),
                        y: .value("Price", candle.close)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

struct EmptyChartCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Select a currency pair to view chart")
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

// Economic Event Card
struct EconomicEventCard: View {
    let event: EconomicEvent

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.country)
                        .font(.caption)
                        .padding(4)
                        .background(colorForImportance(event.importance))
                        .foregroundColor(.white)
                        .cornerRadius(4)

                    Text(event.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Text("Forecast: \(event.forecast)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Previous: \(event.previous)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(timeUntilEvent(event.timestamp))
                    .font(.caption)
                    .foregroundColor(.blue)

                Text(formatDate(event.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2)
    }

    private func colorForImportance(_ importance: EconomicEvent.Importance) -> Color {
        switch importance {
        case .low: return .gray
        case .medium: return .orange
        case .high: return .red
        }
    }

    private func timeUntilEvent(_ timestamp: Date) -> String {
        let now = Date()
        let timeInterval = timestamp.timeIntervalSince(now)

        if timeInterval > 0 {
            let days = Int(timeInterval / 86400)
            let hours = Int((timeInterval.truncatingRemainder(dividingBy: 86400)) / 3600)
            return "\(days)d \(hours)h"
        } else {
            return "Past"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
}

// AI Signals Alert Card
struct AISignalsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                Text("AI Signals")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                AISignalView(signal: AISignal(
                    pair: "EURUSD",
                    direction: "Buy",
                    confidence: 0.85,
                    reason: "EMA crossover with RSI confirmation"
                ))

                AISignalView(signal: AISignal(
                    pair: "GBPUSD",
                    direction: "Sell",
                    confidence: 0.92,
                    reason: "Bearish divergence on MACD"
                ))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5)
    }
}

struct AISignalView: View {
    let signal: AISignal

    var body: some View {
        HStack {
            Text(signal.pair)
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()

            Text(signal.direction)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(signal.direction == "Buy" ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                .foregroundColor(signal.direction == "Buy" ? .green : .red)
                .cornerRadius(4)

            Text("\(Int(signal.confidence * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AISignal {
    let pair: String
    let direction: String
    let confidence: Double
    let reason: String
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
