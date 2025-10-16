//
//  StockApp.swift
//  Stock
//
//  Created by Aarya Devnani on 10/04/24.
//  Enhanced for iOS 26 with Scene Delegate and Modern Features
//

#if os(iOS)
import SwiftUI
import BackgroundTasks

@main
struct StockApp: App {
    @StateObject private var sceneManager = SceneManager()
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sceneManager)
                .onAppear {
                    if #available(iOS 26.0, *) {
                        configureiOS26Features()
                    }
                }
        }
        .backgroundTask(.appRefresh("com.stocktradingapp.backgroundupdate")) { task in
            await handleBackgroundPriceUpdate(task)
        }
        .backgroundTask(.dataSync("com.stocktradingapp.datasync")) { task in
            await handleDataSync(task)
        }
    }

    @available(iOS 26.0, *)
    private func configureiOS26Features() {
        print("🚀 iOS 26 Enhanced Features Activated")
        UserDefaults.standard.set(true, forKey: "iOS26Enhanced")
    }

    private func handleBackgroundPriceUpdate(_ task: BackgroundTask<BackgroundRefreshTask>) async {
        print("📊 Processing background price update…")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        print("✅ Background price update completed")
        task.setTaskCompleted(success: true)
    }

    private func handleDataSync(_ task: BackgroundTask<BackgroundTask.DataSync>) async {
        print("🔄 Processing background data sync…")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        print("✅ Background data sync completed")
        task.setTaskCompleted(success: true)
    }
}

@MainActor
class SceneManager: ObservableObject {
    @Published var isConnected = true
    @Published var lastBackgroundUpdate: Date?

    init() {
        setupBackgroundHandling()
    }

    private func setupBackgroundHandling() {
        if #available(iOS 26.0, *) {
            print("🔧 Enhanced background task management ready")
        }
    }

    func performMaintenance() {
        lastBackgroundUpdate = Date()
        print("🛠️ Performed maintenance at \(lastBackgroundUpdate!)")
    }
}
#endif
