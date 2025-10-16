//
//  MainTabView.swift
//  ForexScalpingBot
//
//  Created by Cline on 10/16/2025.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }

            ForexPairsView()
                .tabItem {
                    Label("Pairs", systemImage: "arrow.triangle.2.circlepath")
                }

            BotControlsView()
                .tabItem {
                    Label("Bot", systemImage: "gear")
                }

            TradeJournalView()
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .accentColor(.blue)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
