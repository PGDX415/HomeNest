//
//  ContentView.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/3/31.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allHomes: [Home]
    
    @State private var selectedTab = 0  // 首页默认显示「场所」
    
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
            
            // Dashboard Tab - Statistics overview as default landing page
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
                ProfileView()
            }
            .tabItem {
                Label("我", systemImage: "person.fill")
            }
            .tag(3)
        }
        .onChange(of: allHomes.count) { newCount in
            // 当添加第一个场所时，自动切换到场所标签页
            if newCount > 0 && selectedTab == 1 {
                selectedTab = 0
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, StorageLocation.self, Home.self], inMemory: true)
}