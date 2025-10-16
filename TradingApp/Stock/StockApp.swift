#if canImport(SwiftUI) && os(iOS)
import SwiftUI

@main
struct StockApp: App {
    @StateObject private var sceneManager = SceneManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sceneManager)
        }
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
