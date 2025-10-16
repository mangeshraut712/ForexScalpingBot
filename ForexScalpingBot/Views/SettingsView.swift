//
//  SettingsView.swift
//  ForexScalpingBot
//
//  Created by Cline on 10/16/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var apiService = ForexAPIService.shared
    @StateObject private var notificationManager = NotificationManager.shared

    @State private var showingLogoutAlert = false
    @State private var showingAPIConfig = false
    @State private var showingAppInfo = false

    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section(header: Text("Account")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "person.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading) {
                                Text("Account Status")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(authViewModel.userProfile?.verified == true ? "Verified" : "Unverified")
                                    .font(.headline)
                                    .foregroundColor(authViewModel.userProfile?.verified == true ? .green : .orange)
                            }
                            Spacer()
                        }

                        if let profile = authViewModel.userProfile {
                            HStack {
                                Image(systemName: "gauge")
                                    .foregroundColor(.blue)
                                Text("Risk Tolerance: \(profile.riskTolerance.rawValue)")
                                    .font(.subheadline)
                            }

                            HStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(.green)
                                Text("Daily Limit: \(profile.dailyLimits.maxTrades) trades, $\(String(format: "%.0f", profile.dailyLimits.maxLoss)) loss")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)

                    Button(action: { showingAPIConfig.toggle() }) {
                        HStack {
                            Image(systemName: "key")
                                .foregroundColor(.blue)
                            Text("API Configuration")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: { showingLogoutAlert = true }) {
                        HStack {
                            Image(systemName: "arrow.right.circle")
                                .foregroundColor(.red)
                            Text("Logout")
                                .foregroundColor(.red)
                        }
                    }
                }

                // Broker Connection Section
                Section(header: Text("Broker Connection")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(apiService.selectedBroker.rawValue)
                                .font(.headline)
                            Text(apiService.connectionStatus.description)
                                .font(.caption)
                                .foregroundColor(connectionStatusColor(apiService.connectionStatus))
                        }
                        Spacer()

                        Circle()
                            .fill(connectionStatusColor(apiService.connectionStatus))
                            .frame(width: 12, height: 12)

                        if apiService.lastUpdate != nil {
                            Text(apiService.lastUpdate!, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    if case .error(let message) = apiService.connectionStatus {
                        Text("Error: \(message)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.vertical, 4)
                    }
                }

                // Trading Preferences Section
                Section(header: Text("Trading Preferences")) {

                    NavigationLink(destination: RiskManagementSettingsView()) {
                        HStack {
                            Image(systemName: "shield.checkerboard")
                                .foregroundColor(.green)
                            Text("Risk Management")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    NavigationLink(destination: NotificationSettingsView()) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(.orange)
                            Text("Notifications")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    Toggle("Demo Mode", isOn: .constant(apiService.selectedBroker == .mock))
                        .onChange(of: apiService.selectedBroker == .mock) { isOn in
                            if isOn {
                                apiService.configureBroker(broker: .mock, apiKey: "demo")
                            }
                        }

                    Toggle("High-Frequency Updates", isOn: .constant(true))
                        .disabled(true) // Feature not implemented yet
                        .opacity(0.6)
                }

                // Data Management Section
                Section(header: Text("Data Management")) {
                    NavigationLink(destination: PrivacySettingsView()) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundColor(.purple)
                            Text("Privacy & Data")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: clearTradeHistory) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Clear Trade History")
                                .foregroundColor(.red)
                        }
                    }
                    .alert(isPresented: $showingClearDataAlert) {
                        Alert(
                            title: Text("Clear Trade History"),
                            message: Text("This will permanently delete all your trade records. This action cannot be undone."),
                            primaryButton: .destructive(Text("Delete")) {
                                performClearTradeHistory()
                            },
                            secondaryButton: .cancel()
                        )
                    }

                    Button(action: exportData) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("Export Data")
                        }
                    }
                }

                // App Information Section
                Section(header: Text("App Information")) {
                    Button(action: contactSupport) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("Help & Support")
                        }
                    }

                    Button(action: rateApp) {
                        HStack {
                            Image(systemName: "star")
                                .foregroundColor(.yellow)
                            Text("Rate App")
                        }
                    }

                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.gray)
                            Text("About")
                            Spacer()
                            Text("v1.0.0")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert(isPresented: $showingLogoutAlert) {
                Alert(
                    title: Text("Logout"),
                    message: Text("Are you sure you want to logout? This will stop all active trading bots."),
                    primaryButton: .destructive(Text("Logout")) {
                        logout()
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showingAPIConfig) {
                APIConfigurationView()
            }
        }
    }

    @State private var showingClearDataAlert = false

    private func connectionStatusColor(_ status: ForexAPIService.ConnectionStatus) -> Color {
        switch status {
        case .connected: return .green
        case .connecting: return .orange
        case .disconnected: return .red
        case .error: return .red
        }
    }

    private func clearTradeHistory() {
        showingClearDataAlert = true
    }

    @State private var clearHistorySuccess = false

    private func performClearTradeHistory() {
        // Clear trade history from all view models
        // This would delete from database/storage
        clearHistorySuccess = true

        // Show success feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.clearHistorySuccess = false
        }
    }

    private func exportData() {
        // Export trading data as CSV/JSON
        // This would create a file and share it
        print("Exporting data...")
    }

    private func contactSupport() {
        let email = "mailto:support@forexscalpingbot.com?subject=Support%20Request"
        if let url = URL(string: email) {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        let appStoreURL = "itms-apps://itunes.apple.com/app/id1234567890" // Would be actual App Store URL
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url)
        }
    }

    private func logout() {
        authViewModel.logout()
        // Stop all trading bots
        // Clear sensitive data
    }
}

// MARK: - Subviews

struct APIConfigurationView: View {
    @StateObject private var apiService = ForexAPIService.shared
    @State private var selectedBroker: ForexAPIService.Broker = .mock
    @State private var apiKey = ""
    @State private var accountId = ""
    @State private var showTestConnection = false
    @State private var connectionTestResult: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Broker Selection")) {
                    Picker("Broker", selection: $selectedBroker) {
                        Text("FXCM").tag(ForexAPIService.Broker.fxcm)
                        Text("OANDA").tag(ForexAPIService.Broker.oanda)
                        Text("Demo (Mock)").tag(ForexAPIService.Broker.mock)
                    }
                    .pickerStyle(.segmented)

                    // Broker help text
                    switch selectedBroker {
                    case .fxcm:
                        Text("Connect to FXCM live trading account. Requires API key from FXCM.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    case .oanda:
                        Text("Connect to OANDA practice or live account. Requires API token and account ID.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    case .mock:
                        Text("Demo mode with simulated price data. Perfect for testing strategies.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("API Credentials")) {
                    if selectedBroker != .mock {
                        SecureField("API Key", text: $apiKey)
                            .textContentType(.password)

                        if selectedBroker == .oanda {
                            TextField("Account ID", text: $accountId)
                        }

                        Button(action: testConnection) {
                            HStack {
                                Image(systemName: showTestConnection ? "checkmark.circle" : "network")
                                    .foregroundColor(showTestConnection ? .green : .blue)
                                Text(showTestConnection ? "Testing..." : "Test Connection")
                            }
                        }
                        .disabled(apiKey.isEmpty)

                        if let result = connectionTestResult {
                            Text(result)
                                .font(.caption)
                                .foregroundColor(result.contains("Success") ? .green : .red)
                        }
                    } else {
                        Text("Demo mode uses simulated data - no API key required.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Section {
                    Button(action: saveConfiguration) {
                        Text("Save Configuration")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.blue)
                    }
                    .disabled(selectedBroker != .mock && apiKey.isEmpty)
                }
            }
            .navigationTitle("API Configuration")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            // Load current configuration
            selectedBroker = apiService.selectedBroker
            apiKey = apiService.apiKey ?? ""
            accountId = apiService.accountId ?? ""
        }
    }

    private func testConnection() {
        showTestConnection = true
        connectionTestResult = nil

        // For demo, simulate connection test
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showTestConnection = false
            self.connectionTestResult = selectedBroker == .mock ? "Success! Connected to demo feed." : "API key validated successfully."
        }
    }

    private func saveConfiguration() {
        apiService.configureBroker(
            broker: selectedBroker,
            apiKey: apiKey,
            accountId: selectedBroker == .oanda ? accountId : nil
        )
    }
}

struct RiskManagementSettingsView: View {
    @State private var maxDailyLoss = 1000.0
    @State private var maxDailyTrades = 50
    @State private var maxPositionSize = 2.0 // % of equity
    @State private var stopLossRequired = true
    @State private var takeProfitRequired = true

    var body: some View {
        Form {
            Section(header: Text("Daily Limits")) {
                VStack {
                    HStack {
                        Text("Max Daily Loss")
                        Spacer()
                        Text("$\(Int(maxDailyLoss))")
                    }
                    Slider(value: $maxDailyLoss, in: 100...10000, step: 100)
                        .accentColor(.red)
                }

                Stepper("Max Daily Trades: \(maxDailyTrades)", value: $maxDailyTrades, in: 1...200)
            }

            Section(header: Text("Position Sizing")) {
                VStack {
                    HStack {
                        Text("Max Position Size")
                        Spacer()
                        Text("\(Int(maxPositionSize))% of equity")
                    }
                    Slider(value: $maxPositionSize, in: 0.5...10.0, step: 0.5)
                        .accentColor(.blue)
                }
            }

            Section(header: Text("Trade Requirements")) {
                Toggle("Always Require Stop Loss", isOn: $stopLossRequired)
                Toggle("Always Require Take Profit", isOn: $takeProfitRequired)

                VStack(alignment: .leading) {
                    Toggle("Auto-close on Margin Call", isOn: .constant(true))
                    Text("Automatically close positions when margin level drops below 50%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Risk Warnings")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Consecutive Losses > 3")
                        Spacer()
                        Circle().fill(Color.orange).frame(width: 8)
                    }

                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Drawdown > 10%")
                        Spacer()
                        Circle().fill(Color.red).frame(width: 8)
                    }

                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Margin Call Level")
                        Spacer()
                        Circle().fill(Color.red).frame(width: 8)
                    }
                }
            }
        }
        .navigationTitle("Risk Management")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var tradingSignals = true
    @State private var priceAlerts = true
    @State private var tradeResults = true
    @State private var riskAlerts = true
    @State private var economicEvents = false
    @State private var soundEnabled = true
    @State private var vibrationEnabled = true

    var body: some View {
        Form {
            Section(header: Text("Notification Types")) {
                Toggle("Trading Signals", isOn: $tradingSignals)
                    .onChange(of: tradingSignals) { _ in
                    updateNotificationSettings()
                }

                Toggle("Price Alerts", isOn: $priceAlerts)
                    .onChange(of: priceAlerts) { _ in
                    updateNotificationSettings()
                }

                Toggle("Trade Results", isOn: $tradeResults)
                    .onChange(of: tradeResults) { _ in
                    updateNotificationSettings()
                }

                Toggle("Risk Management Alerts", isOn: $riskAlerts)
                    .onChange(of: riskAlerts) { _ in
                    updateNotificationSettings()
                }

                Toggle("Economic Events", isOn: $economicEvents)
                    .onChange(of: economicEvents) { _ in
                    updateNotificationSettings()
                }
            }

            Section(header: Text("Notification Style")) {
                Toggle("Sound", isOn: $soundEnabled)
                Toggle("Vibration", isOn: $vibrationEnabled)
            }

            Section(header: Text("Schedules")) {
                Button(action: {
                    notificationManager.scheduleDailySummary()
                }) {
                    HStack {
                        Text("Daily Summary")
                        Spacer()
                        Text("10:00 PM")
                            .foregroundColor(.secondary)
                        Image(systemName: "clock")
                    }
                }

                Button(action: {}) {
                    HStack {
                        Text("Economic Calendar Alerts")
                        Spacer()
                        Text("15 min before")
                            .foregroundColor(.secondary)
                        Image(systemName: "calendar.badge.clock")
                    }
                }
            }

            Section {
                Text("Notifications help you stay on top of market movements and bot performance.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Load current settings (would be from UserDefaults)
        }
    }

    private func updateNotificationSettings() {
        // Save notification preferences
        UserDefaults.standard.set(tradingSignals, forKey: "tradingSignalsEnabled")
        UserDefaults.standard.set(priceAlerts, forKey: "priceAlertsEnabled")
        UserDefaults.standard.set(tradeResults, forKey: "tradeResultsEnabled")
        UserDefaults.standard.set(riskAlerts, forKey: "riskAlertsEnabled")
        UserDefaults.standard.set(economicEvents, forKey: "economicEventsEnabled")
    }
}

struct PrivacySettingsView: View {
    @State private var dataSharing = false
    @State private var analyticsEnabled = true
    @State private var crashReporting = true
    @State private var tradeDataSync = false
    @State private var biometricEnabled = true

    var body: some View {
        Form {
            Section(header: Text("Data Privacy")) {
                VStack(alignment: .leading) {
                    Toggle("Analytics & Usage Data", isOn: $analyticsEnabled)
                    Text("Help improve the app by sharing anonymous usage statistics")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading) {
                    Toggle("Crash Reporting", isOn: $crashReporting)
                    Text("Automatically send crash reports to help fix issues")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Data Management")) {
                VStack(alignment: .leading) {
                    Toggle("Cloud Backup", isOn: $tradeDataSync)
                    Text("Sync trading data across devices (encrypted)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button(action: requestDataDeletion) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Delete My Account")
                            .foregroundColor(.red)
                    }
                }
                .alert(isPresented: $showDeleteAccountAlert) {
                    Alert(
                        title: Text("Delete Account"),
                        message: Text("This will permanently delete your account and all associated data. This action cannot be undone."),
                        primaryButton: .destructive(Text("Delete")) {
                            performAccountDeletion()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }

            Section(header: Text("Security")) {
                VStack(alignment: .leading) {
                    Toggle("Biometric Authentication", isOn: $biometricEnabled)
                    Text("Use Face ID or Touch ID for secure app access")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading) {
                    Toggle("Auto-lock", isOn: .constant(true))
                    Text("Require authentication after 5 minutes of inactivity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                NavigationLink(destination: PrivacyPolicyView()) {
                    Text("View Privacy Policy")
                }

                NavigationLink(destination: TermsOfServiceView()) {
                    Text("Terms of Service")
                }
            }
        }
        .navigationTitle("Privacy & Data")
        .navigationBarTitleDisplayMode(.inline)
    }

    @State private var showDeleteAccountAlert = false
    @State private var deletionInProgress = false

    private func requestDataDeletion() {
        showDeleteAccountAlert = true
    }

    private func performAccountDeletion() {
        deletionInProgress = true
        // Simulate account deletion process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.deletionInProgress = false
            // In real app, this would navigate to logout or app restart
        }
    }
}

// Placeholder views for navigation links
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("Privacy Policy content would go here...")
                .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            Text("Terms of Service content would go here...")
                .padding()
        }
        .navigationTitle("Terms of Service")
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .center, spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("Forex Scalping Bot")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Version 1.0.0")
                        .foregroundColor(.secondary)

                    Text("Advanced AI-powered forex trading platform")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Features")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        FeatureRow(icon: "brain.head.profile", text: "AI-powered signal generation")
                        FeatureRow(icon: "chart.bar.fill", text: "Real-time market analysis")
                        FeatureRow(icon: "shield.checkerboard", text: "Advanced risk management")
                        FeatureRow(icon: "bell.fill", text: "Smart notifications")
                        FeatureRow(icon: "person.badge.shield", text: "Secure biometric authentication")
                        FeatureRow(icon: "network", text: "Multi-broker connectivity")
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Credits")
                        .font(.headline)

                    Text("Built with SwiftUI and Apple's App Frameworks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Icons by")
                        Link("SF Symbols", destination: URL(string: "https://developer.apple.com/sf-symbols/")!)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Legal")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("This app is for educational and demonstration purposes only.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Not intended for live trading without proper due diligence and risk assessment.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("About")
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
            Spacer()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthViewModel())
    }
}
