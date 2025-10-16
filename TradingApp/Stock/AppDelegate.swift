//
//  AppDelegate.swift
//  Stock
//
//  App Delegate for iOS 26 Enhanced Features
//

#if canImport(UIKit)
import UIKit
import BackgroundTasks

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Register background tasks for iOS 26
        if #available(iOS 26.0, *) {
            registerBackgroundTasks()
        }

        // Configure Siri intents
        if #available(iOS 26.0, *) {
            configureAppIntents()
        }

        return true
    }

    // MARK: - iOS 26 Background Tasks
    @available(iOS 26.0, *)
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.quantumscalptrading.backgroundupdate", using: nil) { task in
            self.handleBackgroundPriceUpdate(task)
        }

        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.quantumscalptrading.datasync", using: nil) { task in
            self.handleDataSync(task)
        }
    }

    @available(iOS 26.0, *)
    private func handleBackgroundPriceUpdate(_ task: BGTask) {
        task.expirationHandler = {
            print("Background price update task expired")
        }

        // Perform background price updates without UI
        Task {
            await self.updateStockPricesInBackground()
            task.setTaskCompleted(success: true)
        }
    }

    @available(iOS 26.0, *)
    private func handleDataSync(_ task: BGTask) {
        task.expirationHandler = {
            print("Data sync task expired")
        }

        Task {
            await self.syncPortfolioData()
            task.setTaskCompleted(success: true)
        }
    }

    private func updateStockPricesInBackground() async {
        // Fetch latest prices without UI updates
        // This maintains app freshness
        print("Performing background price updates...")
        // In real app, would call your API methods here
    }

    private func syncPortfolioData() async {
        // Sync portfolio data in background
        print("Syncing portfolio data...")
    }

    // MARK: - App Intents (iOS 26)
    @available(iOS 26.0, *)
    private func configureAppIntents() {
        // Configure Siri Shortcuts and App Intents
        print("Configuring App Intents for iOS 26...")
    }

    // MARK: - App Lifecycle
    func applicationDidBecomeActive(_ application: UIApplication) {
        // App became active - refresh data if needed
        if #available(iOS 26.0, *) {
            scheduleBackgroundTasks()
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // App entered background - schedule tasks
        if #available(iOS 26.0, *) {
            scheduleBackgroundTasks()
        }
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }

    // MARK: - Push Notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Handle device token for push notifications
        print("Registered for remote notifications: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    // MARK: - Background Task Scheduling
    @available(iOS 26.0, *)
    private func scheduleBackgroundTasks() {
        let priceUpdateTask = BGAppRefreshTaskRequest(identifier: "com.quantumscalptrading.backgroundupdate")
        priceUpdateTask.earliestBeginDate = Date(timeIntervalSinceNow: 3600) // 1 hour

        let dataSyncTask = BGProcessingTaskRequest(identifier: "com.quantumscalptrading.datasync")
        dataSyncTask.requiresNetworkConnectivity = true
        dataSyncTask.earliestBeginDate = Date(timeIntervalSinceNow: 7200) // 2 hours

        do {
            try BGTaskScheduler.shared.submit(priceUpdateTask)
            try BGTaskScheduler.shared.submit(dataSyncTask)
        } catch {
            print("Failed to schedule background tasks: \(error)")
        }
    }

    // MARK: - URL Handling
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle deep links (e.g., stock://AAPL)
        if url.scheme == "stock" {
            // Handle stock deep link
            let ticker = url.host ?? ""
            print("Opening stock: \(ticker)")
            // Navigate to the stock view
            return true
        }
        return false
    }
}
#endif
