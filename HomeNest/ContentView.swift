//
//  ContentView.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/3/31.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 1 // Changed default to 统计 tab
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Places Tab - Main entry point for multi-place support
            NavigationStack {
                PlacesView()
            }
            .tabItem {
                Label("场所", systemImage: "house.fill")
            }
            .tag(0)
            
            // Dashboard Tab - Updated to "统计" for better clarity
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("统计", systemImage: "chart.bar.fill")
            }
            .tag(1)
            
            // Items Tab - Browse all items across all places
            NavigationStack {
                ItemsView()
            }
            .tabItem {
                Label("物品", systemImage: "list.bullet.rectangle")
            }
            .tag(2)
            
            // Profile Tab
            NavigationStack {
                Text("Profile View - 我的")
                    .navigationTitle("我")
            }
            .tabItem {
                Label("我", systemImage: "person.fill")
            }
            .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, StorageLocation.self, Home.self], inMemory: true)
}