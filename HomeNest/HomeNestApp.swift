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
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Clean up empty icon strings in the database
            cleanUpEmptyIcons(in: container.mainContext)
            
            return container
        } catch {
            // Log the error but don't crash - this handles recovery scenarios gracefully
            print("Warning: ModelContainer creation encountered an issue: \(error)")
            print("This may be due to database recovery or CloudKit sync state.")
            
            // Attempt to create a fallback container without CloudKit if needed
            let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                let container = try ModelContainer(for: schema, configurations: [fallbackConfiguration])
                
                // Clean up empty icon strings in the database
                cleanUpEmptyIcons(in: container.mainContext)
                
                return container
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
    
    /// 清理数据库中的空字符串图标数据
    private static func cleanUpEmptyIcons(in context: ModelContext) {
        print("🧹 开始清理数据库中的空字符串图标数据...")
        
        var cleanedCount = 0
        
        // 清理 Home 模型中的空图标
        do {
            let homeFetchDescriptor = FetchDescriptor<Home>()
            let homes = try context.fetch(homeFetchDescriptor)
            
            for home in homes {
                if let icon = home.icon, icon.isEmpty {
                    home.icon = nil
                    cleanedCount += 1
                    print("🧹 Cleaned empty icon for Home: \(home.name)")
                }
            }
        } catch {
            print("⚠️ Failed to clean Home icons: \(error)")
        }
        
        // 清理 StorageLocation 模型中的空图标
        do {
            let locationFetchDescriptor = FetchDescriptor<StorageLocation>()
            let locations = try context.fetch(locationFetchDescriptor)
            
            for location in locations {
                if let icon = location.icon, icon.isEmpty {
                    location.icon = nil
                    cleanedCount += 1
                    print("🧹 Cleaned empty icon for Location: \(location.name)")
                }
            }
        } catch {
            print("⚠️ Failed to clean StorageLocation icons: \(error)")
        }
        
        if cleanedCount > 0 {
            // 保存更改
            do {
                try context.save()
                print("✅ 数据库清理完成！共清理了 \(cleanedCount) 个空字符串图标。")
            } catch {
                print("❌ Failed to save cleanup changes: \(error)")
            }
        } else {
            print("ℹ️ 数据库中未发现空字符串图标，无需清理。")
        }
    }
}