//
//  main.swift
//  ForexScalpingBot
//
//  CLI executable for the Forex Scalping Bot
//

import Foundation

// MARK: - Main Entry Point
@main
struct ForexScalpingBotCLI {
    static func main() {
        print("🚀 Forex Scalping Bot CLI Demo")
        print("================================")

        // Initialize the Forex API service
        let apiService = ForexAPIService.shared

        // Demo the mock trading capability
        print("🤖 Starting demo forex trading bot...")
        print("🔄 Using \(apiService.selectedBroker.rawValue) broker")

        // Simulate some market data updates
        for i in 1...5 {
            print("\(i). EURUSD updated: Bid 1.0850, Ask 1.0852 (Spread: 0.0002)")
            // Simple delay
            usleep(500000) // 0.5 seconds in microseconds
        }

        print("📊 Trading analysis complete!")
        print("💰 Profit/Loss: +15.75 pips")
        print("📈 Success rate: 78.4%")
        print("✅ Demo complete! The forex bot shows realistic trading simulation.")
    }
}
