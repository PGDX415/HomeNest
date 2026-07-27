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
            UserProfile.self,
            FamilyMember.self,
        ])

        let cloudKitContainerID = "iCloud.com.gongdexin.paul.HomeNest"
        print("☁️ App: 初始化 ModelContainer，CloudKit 容器: \(cloudKitContainerID)")

        // Explicitly use private CloudKit database for sync across devices
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("☁️ App: CloudKit ModelContainer 创建成功 ✅")
            if FileManager.default.ubiquityIdentityToken != nil {
                print("☁️ App: iCloud 已登录")
            } else {
                print("☁️ App: ⚠️ iCloud 未登录！")
            }
            cleanUpEmptyIcons(in: container.mainContext)
            return container
        } catch {
            print("☁️ App: CloudKit container 失败，使用本地存储 ⚠️: \(error)")
            let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                let container = try ModelContainer(for: schema, configurations: [fallbackConfiguration])
                print("☁️ App: 本地存储模式")
                cleanUpEmptyIcons(in: container.mainContext)
                return container
            } catch {
                fatalError("Could not create ModelContainer even with fallback: \(error)")
            }
        }
    }()
    
    @StateObject private var appLockManager = AppLockManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var cloudKitSyncMonitor = CloudKitSyncMonitor.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if appLockManager.shouldShowLockScreen {
                    AppLockView()
                } else {
                    SplashView()
                }
            }
            .environmentObject(appLockManager)
            .environmentObject(themeManager)
            .environmentObject(cloudKitSyncMonitor)
            .environment(\.colorScheme, themeManager.getCurrentColorScheme() ?? .light)
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
                
                // 修复 StorageLocation 的 home 属性
                if location.home == nil {
                    // 尝试从父位置继承 home
                    var currentLocation: StorageLocation? = location.parent
                    var depth = 0
                    
                    while let current = currentLocation, depth < 10 {
                        if let parentHome = current.home {
                            location.home = parentHome
                            print("🔧 Fixed home reference for Location: \(location.name)")
                            break
                        }
                        currentLocation = current.parent
                        depth += 1
                    }
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