//
//  HomeNestApp.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/3/31.
//

import SwiftUI
import SwiftData

@main
struct HomeNestApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            StorageLocation.self,
            Home.self,  // Added Home model
        ])
        // Configure for CloudKit sync with proper settings
        let modelConfiguration = ModelConfiguration(
            schema: schema, 
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
        .modelContainer(sharedModelContainer)
    }
}