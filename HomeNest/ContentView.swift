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
            // Dashboard Tab
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("首页", systemImage: "house.fill")
            }
            .tag(0)
            
            // Locations Tab
            NavigationStack {
                LocationsView()
            }
            .tabItem {
                Label("位置", systemImage: "folder.fill")
            }
            .tag(1)
            
            // Items Tab
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
        .modelContainer(for: [Item.self, StorageLocation.self], inMemory: true)
}