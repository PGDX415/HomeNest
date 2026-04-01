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
            Home.self,
        ])
        
        // Configure for CloudKit sync with proper settings
        let modelConfiguration = ModelConfiguration(
            schema: schema, 
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            // Try to create the model container
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Log the error but don't crash - this handles recovery scenarios gracefully
            print("Warning: ModelContainer creation encountered an issue: \(error)")
            print("This may be due to database recovery or CloudKit sync state.")
            
            // Attempt to create a fallback container without CloudKit if needed
            let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even with fallback: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
        .modelContainer(sharedModelContainer)
    }
}