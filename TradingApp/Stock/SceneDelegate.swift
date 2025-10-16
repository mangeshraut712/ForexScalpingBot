//
//  SceneDelegate.swift
//  Stock
//
//  iOS 26 Scene Delegate for Enhanced Features
//

#if canImport(UIKit)
import UIKit
import SwiftUI
import BackgroundTasks

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let contentView = ContentView()

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = HostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }

        // iOS 26 Enhanced Features
        configureiOS26Features(windowScene)
    }

    private func configureiOS26Features(_ windowScene: UIWindowScene) {
        // Enhanced Performance Rendering (iOS 26)
        if #available(iOS 26.0, *) {
            windowScene.sizeRestrictions?.maximumSize = .init(width: 1024, height: 1366)

            // Advanced Rendering Options
            if let renderer = windowScene.screen.traitCollection.displayGamut {
                print("Display Gamut: \(renderer.rawValue)")
            }
        }

        // Background Tasks for iOS 26
        if #available(iOS 26.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.quantumscalptrading.backgroundupdate", using: nil) { task in
                self.handleBackgroundPriceUpdate(task)
            }

            BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.quantumscalptrading.datasync", using: nil) { task in
                self.handleDataSync(task)
            }
        }
    }

    private func handleBackgroundPriceUpdate(_ task: BGTask) {
        // Process expired task
        task.expirationHandler = {
            print("Background price update expired")
        }

        // Perform background price updates
        Task {
            await updateStockPrices()
            task.setTaskCompleted(success: true)
        }
    }

    private func handleDataSync(_ task: BGTask) {
        task.expirationHandler = {
            print("Data sync task expired")
        }

        // Sync portfolio data
        Task {
            await syncPortfolioData()
            task.setTaskCompleted(success: true)
        }
    }

    private func updateStockPrices() async {
        // Background price update logic
        // This would fetch latest prices without UI updates
        print("Performing background price updates...")
    }

    private func syncPortfolioData() async {
        // Background data sync
        print("Performing portfolio sync...")
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called when scene is being released
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Restart tasks when app becomes active
        if #available(iOS 26.0, *) {
            scheduleBackgroundTasks()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Scene will resign active
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Scene will enter foreground
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Schedule background tasks when entering background
        if #available(iOS 26.0, *) {
            scheduleBackgroundTasks()
        }
    }

    private func scheduleBackgroundTasks() {
        if #available(iOS 26.0, *) {
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
    }
}

// Enhanced Hosting Controller for iOS 26
class HostingController<Content>: UIHostingController<Content> where Content: View {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 26.0, *) {
            // iOS 26 Enhanced View Configuration
            view.backgroundColor = .systemBackground

            // Configure for enhanced rendering
            if let scene = view.window?.windowScene {
                configureForWindowScene(scene)
            }
        }
    }

    private func configureForWindowScene(_ scene: UIWindowScene) {
        if #available(iOS 26.0, *) {
            // Enhanced accessibility features
            scene.accessibilityContainerType = .semanticGroup

            // Power management optimizations
            scene.activationConditions = .init(
                canActivateForTargetContentIdentifierPredicate: .init(value: true),
                prefersToActivateForTargetContentIdentifierPredicate: .init(value: true)
            )
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 26.0, *) {
            // Respond to trait collection changes for iOS 26
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateForColorScheme()
            }
        }
    }

    private func updateForColorScheme() {
        if #available(iOS 26.0, *) {
            // Enhanced color scheme handling
            let colorScheme = traitCollection.userInterfaceStyle == .dark ? "dark" : "light"
            print("Switched to \(colorScheme) mode with enhanced iOS 26 features")
        }
    }
}
#endif
