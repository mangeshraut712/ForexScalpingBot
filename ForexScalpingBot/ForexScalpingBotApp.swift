//
//  ForexScalpingBotApp.swift
//  ForexScalpingBot
//
//  Created by Cline on 10/16/2025.
//

import SwiftUI

@main
struct ForexScalpingBotApp: App {
    // Initialize ViewModel for state management across the app
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                AuthView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
