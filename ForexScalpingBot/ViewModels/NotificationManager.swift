//
//  NotificationManager.swift
//  ForexScalpingBot
//
//  Created by Cline on 10/16/2025.
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var isAuthorized = false
    @Published var pendingNotifications: [TradingNotification] = []

    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus()
    }

    func requestAuthorization() async {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            await MainActor.run {
                self.isAuthorized = granted
            }
        } catch {
            print("Notification authorization error: \(error)")
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // Send trading signal notification
    func sendTradingSignalNotification(signal: TradingSignal) {
        let content = UNMutableNotificationContent()
        content.title = "Trading Signal"
        content.body = "\(signal.action.rawValue.uppercased()) \(signal.pair) - \(String(format: "%.1f", signal.confidence * 100))% confidence"
        content.subtitle = signal.reason
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "tradingSignal", "pair": signal.pair, "action": signal.action.rawValue]

        let request = UNNotificationRequest(identifier: "tradingSignal-\(UUID().uuidString)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)

        // Add to pending notifications
        let notification = TradingNotification(
            id: UUID().uuidString,
            type: .tradingSignal,
            title: content.title,
            message: content.body,
            subtitle: content.subtitle,
            timestamp: Date(),
            relatedPair: signal.pair,
            tradingAction: signal.action.rawValue
        )
        pendingNotifications.insert(notification, at: 0)
    }

    // Send price alert notification
    func sendPriceAlertNotification(pair: String, targetPrice: Double, currentPrice: Double, condition: String) {
        let content = UNMutableNotificationContent()
        content.title = "Price Alert"
        content.body = "\(pair) \(condition) $\(String(format: "%.4f", targetPrice))"
        content.subtitle = "Current price: $\(String(format: "%.4f", currentPrice))"
        content.sound = UNNotificationSound.default
        content.badge = 1
        content.userInfo = ["type": "priceAlert", "pair": pair, "price": targetPrice]

        let request = UNNotificationRequest(identifier: "priceAlert-\(UUID().uuidString)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)

        let notification = TradingNotification(
            id: UUID().uuidString,
            type: .priceAlert,
            title: content.title,
            message: content.body,
            subtitle: content.subtitle,
            timestamp: Date(),
            relatedPair: pair
        )
        pendingNotifications.insert(notification, at: 0)
    }

    // Send trade closed notification
    func sendTradeClosedNotification(trade: ForexTrade) {
        let content = UNMutableNotificationContent()
        content.title = "Trade Closed"
        content.body = "\(trade.pair) - \(trade.direction.rawValue.capitalized)"
        let pnlString = trade.pnl ?? 0 >= 0 ? "+" : ""
        content.subtitle = "P&L: \(pnlString)$\(String(format: "%.2f", trade.pnl ?? 0))"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "tradeClosed", "pair": trade.pair, "pnl": trade.pnl ?? 0]

        let request = UNNotificationRequest(identifier: "tradeClosed-\(UUID().uuidString)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)

        let notification = TradingNotification(
            id: UUID().uuidString,
            type: .tradeClosed,
            title: content.title,
            message: content.body,
            subtitle: content.subtitle,
            timestamp: Date(),
            relatedPair: trade.pair,
            pnl: trade.pnl
        )
        pendingNotifications.insert(notification, at: 0)
    }

    // Send risk management alert
    func sendRiskAlert(type: RiskAlertType, message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Risk Alert"
        content.body = type.rawValue
        content.subtitle = message
        content.sound = .defaultCritical
        content.badge = 1
        content.userInfo = ["type": "riskAlert", "alertType": type.rawValue]

        let request = UNNotificationRequest(identifier: "riskAlert-\(UUID().uuidString)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)

        let notification = TradingNotification(
            id: UUID().uuidString,
            type: .riskAlert,
            title: content.title,
            message: content.body,
            subtitle: content.subtitle,
            timestamp: Date()
        )
        pendingNotifications.insert(notification, at: 0)
    }

    // Schedule daily summary notification
    func scheduleDailySummary() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Trading Summary"
        content.body = "Your trading performance summary is ready"
        content.sound = .default

        let components = DateComponents(hour: 22, minute: 0) // 10 PM daily
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: "dailySummary", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // Schedule economic event reminder
    func scheduleEconomicEventReminder(event: EconomicEvent, minutesBefore: Int = 15) {
        let content = UNMutableNotificationContent()
        content.title = "Economic Event Alert"
        content.body = event.title
        content.subtitle = "Impact: \(event.importance.rawValue) - \(event.country)"
        content.sound = .default
        content.userInfo = ["type": "economicEvent", "eventId": event.id.uuidString]

        let triggerDate = event.timestamp.addingTimeInterval(-Double(minutesBefore * 60))
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "economicEvent-\(event.id.uuidString)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // UNUserNotificationCenterDelegate methods
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        // Handle notification tap
        if let type = userInfo["type"] as? String {
            switch type {
            case "tradingSignal":
                // Navigate to bot controls
                break
            case "priceAlert":
                // Navigate to pair details
                break
            case "tradeClosed":
                // Navigate to trade journal
                break
            case "economicEvent":
                // Navigate to economic calendar
                break
            default:
                break
            }
        }

        completionHandler()
    }

    func clearNotification(_ notification: TradingNotification) {
        pendingNotifications.removeAll { $0.id == notification.id }
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [notification.id])
    }

    func clearAllNotifications() {
        pendingNotifications.removeAll()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func markNotificationAsRead(_ notification: TradingNotification) {
        if let index = pendingNotifications.firstIndex(where: { $0.id == notification.id }) {
            pendingNotifications[index].isRead = true
        }
    }

    enum RiskAlertType: String {
        case marginCall = "Margin Call"
        case stopOut = "Stop Out"
        case highDrawdown = "High Drawdown"
        case consecutiveLosses = "Consecutive Losses"
        case maxTradesReached = "Max Daily Trades Reached"
    }
}

// Trading Notification Model
struct TradingNotification: Identifiable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let subtitle: String?
    let timestamp: Date
    var isRead: Bool = false
    let relatedPair: String?
    let tradingAction: String?
    let pnl: Double?

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var iconName: String {
        switch type {
        case .tradingSignal:
            return tradingAction?.lowercased() == "buy" ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
        case .priceAlert:
            return "bell.fill"
        case .tradeClosed:
            return (pnl ?? 0) >= 0 ? "checkmark.circle.fill" : "xmark.circle.fill"
        case .riskAlert:
            return "exclamationmark.triangle.fill"
        case .economicEvent:
            return "calendar.circle.fill"
        }
    }

    var iconColor: Color {
        switch type {
        case .tradingSignal:
            return tradingAction?.lowercased() == "buy" ? .green : .red
        case .priceAlert:
            return .orange
        case .tradeClosed:
            return (pnl ?? 0) >= 0 ? .green : .red
        case .riskAlert:
            return .red
        case .economicEvent:
            return .blue
        }
    }

    enum NotificationType: String, Codable {
        case tradingSignal = "Trading Signal"
        case priceAlert = "Price Alert"
        case tradeClosed = "Trade Closed"
        case riskAlert = "Risk Alert"
        case economicEvent = "Economic Event"
    }
}

// Siri Integration for Voice Commands
class SiriIntegrationManager {
    static let shared = SiriIntegrationManager()

    func setupAppIntents() {
        // Register App Intents for Siri integration
        // This would integrate with App Intents framework for WWDC 2025 features

        // Example intents:
        // - "Start scalping bot for EURUSD"
        // - "Enable trading alerts"
        // - "Show current positions"
        // - "Pause all trading"

        // Implementation would include:
        // 1. Define AppIntent structs for each voice command
        // 2. Implement perform() methods with business logic
        // 3. Add Siri phrases for natural language recognition
        // 4. Handle Siri authorization and privacy
    }

    func handleSiriCommand(command: SiriCommand) async {
        switch command {
        case .startBot(let pair):
            // Start scalping bot for specific pair
            print("Starting bot for \(pair)")
        case .stopBot:
            // Stop all scalping bots
            print("Stopping all bots")
        case .getPositions:
            // Return current open positions
            print("Getting current positions")
        case .enableAlerts:
            // Enable notifications
            await NotificationManager.shared.requestAuthorization()
        }
    }

    enum SiriCommand {
        case startBot(pair: String)
        case stopBot
        case getPositions
        case enableAlerts
    }
}
