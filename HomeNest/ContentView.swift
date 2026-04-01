//
//  ContentView.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/3/31.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Homes Tab - Main entry point for multi-home support
            NavigationStack {
                HomesView()
            }
            .tabItem {
                Label("家庭", systemImage: "house.fill")
            }
            .tag(0)
            
            // Dashboard Tab - Will need to be updated to work with selected home
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("首页", systemImage: "house.fill")
            }
            .tag(1)
            
            // Locations Tab - Will need to be updated to work with selected home
            NavigationStack {
                LocationsView(home: nil) // This will need to be updated
            }
            .tabItem {
                Label("位置", systemImage: "folder.fill")
            }
            .tag(2)
            
            // Items Tab - Will need to be updated to work with selected home
            NavigationStack {
                ItemsView()
            }
            .tabItem {
                Label("物品", systemImage: "list.bullet.rectangle")
            }
            .tag(3)
            
            // Profile Tab
            NavigationStack {
                Text("Profile View - 我的")
                    .navigationTitle("我")
            }
            .tabItem {
                Label("我", systemImage: "person.fill")
            }
            .tag(4)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, StorageLocation.self, Home.self], inMemory: true)
}