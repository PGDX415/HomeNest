//
//  AdvancedStatisticsManager.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/2.
//

import Foundation
import SwiftData

// 统计数据模型
struct CategoryDistribution: Identifiable {
    let id = UUID()
    let category: String
    let itemCount: Int
    let totalValue: Double?
}

struct HomeDistribution: Identifiable {
    let id = UUID()
    let homeName: String
    let itemCount: Int
    let locationCount: Int
    let totalValue: Double?
}

struct TimeDistribution: Identifiable {
    let id = UUID()
    let period: String // "今天", "本周", "本月", "今年"
    let itemCount: Int
    let addedCount: Int
    let modifiedCount: Int
}

struct StorageAnalysis: Identifiable {
    let id = UUID()
    let homeName: String
    let totalLocations: Int
    let usedLocations: Int
    let capacityPercentage: Double
    let totalItems: Int
}

struct ItemHistory: Identifiable {
    let id = UUID()
    let itemName: String
    let action: String // "添加" or "修改"
    let timestamp: Date
    let locationName: String?
}

// 高级统计管理器
class AdvancedStatisticsManager {
    static let shared = AdvancedStatisticsManager()
    
    private init() {}
    
    // MARK: - 物品分布统计
    
    /// 按分类统计物品分布
    func getCategoryDistribution(context: ModelContext) -> [CategoryDistribution] {
        var categoryMap: [String: (count: Int, totalValue: Double)] = [:]
        
        do {
            let itemDescriptor = FetchDescriptor<Item>()
            let items = try context.fetch(itemDescriptor)
            
            for item in items {
                let category = item.category ?? "未分类"
                let value = item.value ?? 0.0
                
                if var existing = categoryMap[category] {
                    existing.count += 1
                    existing.totalValue += value
                    categoryMap[category] = existing
                } else {
                    categoryMap[category] = (count: 1, totalValue: value)
                }
            }
            
            return categoryMap.map { key, value in
                CategoryDistribution(
                    category: key,
                    itemCount: value.count,
                    totalValue: value.totalValue > 0 ? value.totalValue : nil
                )
            }.sorted { $0.itemCount > $1.itemCount }
            
        } catch {
            print("获取分类统计失败: \(error)")
            return []
        }
    }
    
    /// 按场所统计物品分布
    func getHomeDistribution(context: ModelContext) -> [HomeDistribution] {
        var homeMap: [String: (itemCount: Int, locationCount: Int, totalValue: Double)] = [:]
        
        do {
            // 获取所有家庭
            let homeDescriptor = FetchDescriptor<Home>()
            let homes = try context.fetch(homeDescriptor)
            
            // 获取所有位置
            let locationDescriptor = FetchDescriptor<StorageLocation>()
            let locations = try context.fetch(locationDescriptor)
            
            // 获取所有物品
            let itemDescriptor = FetchDescriptor<Item>()
            let items = try context.fetch(itemDescriptor)
            
            // Initialize family mapping
            for home in homes {
                homeMap[home.name] = (itemCount: 0, locationCount: 0, totalValue: 0.0)
            }
            
            // Count locations
            for location in locations {
                if let home = location.home {
                    if var existing = homeMap[home.name] {
                        existing.locationCount += 1
                        homeMap[home.name] = existing
                    }
                }
            }
            
            // Count items and values
            for item in items {
                if let location = item.location, let home = location.home {
                    let value = item.value ?? 0.0
                    if var existing = homeMap[home.name] {
                        existing.itemCount += 1
                        existing.totalValue += value
                        homeMap[home.name] = existing
                    }
                }
            }
            
            return homeMap.map { key, value in
                HomeDistribution(
                    homeName: key,
                    itemCount: value.itemCount,
                    locationCount: value.locationCount,
                    totalValue: value.totalValue > 0 ? value.totalValue : nil
                )
            }.sorted { $0.itemCount > $1.itemCount }
            
        } catch {
            print("获取场所统计失败: \(error)")
            return []
        }
    }
    
    /// 按时间维度统计物品分布
    func getTimeDistribution(context: ModelContext) -> [TimeDistribution] {
        let now = Date()
        let calendar = Calendar.current
        
        var todayCount = 0
        var thisWeekCount = 0
        var thisMonthCount = 0
        var thisYearCount = 0
        
        var todayAdded = 0
        var thisWeekAdded = 0
        var thisMonthAdded = 0
        var thisYearAdded = 0
        
        var todayModified = 0
        var thisWeekModified = 0
        var thisMonthModified = 0
        var thisYearModified = 0
        
        do {
            let itemDescriptor = FetchDescriptor<Item>()
            let items = try context.fetch(itemDescriptor)
            
            for item in items {
                // 统计创建时间
                if calendar.isDateInToday(item.createdAt) {
                    todayCount += 1
                    todayAdded += 1
                }
                if calendar.isDate(item.createdAt, equalTo: now, toGranularity: .weekOfYear) {
                    thisWeekCount += 1
                    thisWeekAdded += 1
                }
                if calendar.isDate(item.createdAt, equalTo: now, toGranularity: .month) {
                    thisMonthCount += 1
                    thisMonthAdded += 1
                }
                if calendar.isDate(item.createdAt, equalTo: now, toGranularity: .year) {
                    thisYearCount += 1
                    thisYearAdded += 1
                }
                
                // 统计修改时间（排除刚创建的情况）
                if item.updatedAt != item.createdAt {
                    if calendar.isDateInToday(item.updatedAt) {
                        todayModified += 1
                    }
                    if calendar.isDate(item.updatedAt, equalTo: now, toGranularity: .weekOfYear) {
                        thisWeekModified += 1
                    }
                    if calendar.isDate(item.updatedAt, equalTo: now, toGranularity: .month) {
                        thisMonthModified += 1
                    }
                    if calendar.isDate(item.updatedAt, equalTo: now, toGranularity: .year) {
                        thisYearModified += 1
                    }
                }
            }
            
            return [
                TimeDistribution(period: "今天", itemCount: todayCount, addedCount: todayAdded, modifiedCount: todayModified),
                TimeDistribution(period: "本周", itemCount: thisWeekCount, addedCount: thisWeekAdded, modifiedCount: thisWeekModified),
                TimeDistribution(period: "本月", itemCount: thisMonthCount, addedCount: thisMonthAdded, modifiedCount: thisMonthModified),
                TimeDistribution(period: "今年", itemCount: thisYearCount, addedCount: thisYearAdded, modifiedCount: thisYearModified)
            ]
            
        } catch {
            print("获取时间统计失败: \(error)")
            return []
        }
    }
    
    // MARK: - 存储空间分析
    
    /// 分析各场所容量使用情况
    func getStorageAnalysis(context: ModelContext) -> [StorageAnalysis] {
        var analysisResults: [StorageAnalysis] = []
        
        do {
            // 获取所有家庭
            let homeDescriptor = FetchDescriptor<Home>()
            let homes = try context.fetch(homeDescriptor)
            
            // 获取所有位置
            let locationDescriptor = FetchDescriptor<StorageLocation>()
            let locations = try context.fetch(locationDescriptor)
            
            // 获取所有物品
            let itemDescriptor = FetchDescriptor<Item>()
            let items = try context.fetch(itemDescriptor)
            
            for home in homes {
                let homeLocations = locations.filter { $0.home?.persistentModelID == home.persistentModelID }
                let homeItems = items.filter { $0.location?.home?.persistentModelID == home.persistentModelID }
                
                let totalLocations = homeLocations.count
                let usedLocations = homeLocations.filter { !($0.items ?? []).isEmpty || !($0.subLocations ?? []).isEmpty }.count
                let capacityPercentage = totalLocations > 0 ? Double(usedLocations) / Double(totalLocations) * 100 : 0
                
                analysisResults.append(
                    StorageAnalysis(
                        homeName: home.name,
                        totalLocations: totalLocations,
                        usedLocations: usedLocations,
                        capacityPercentage: capacityPercentage,
                        totalItems: homeItems.count
                    )
                )
            }
            
            return analysisResults.sorted { $0.capacityPercentage > $1.capacityPercentage }
            
        } catch {
            print("获取存储分析失败: \(error)")
            return []
        }
    }
    
    // MARK: - 历史记录
    
    /// 获取物品添加/修改历史记录
    func getItemHistory(context: ModelContext, limit: Int = 50) -> [ItemHistory] {
        var history: [ItemHistory] = []
        
        do {
            let itemDescriptor = FetchDescriptor<Item>()
            let items = try context.fetch(itemDescriptor)
            
            for item in items {
                // 添加记录（创建）
                history.append(
                    ItemHistory(
                        itemName: item.name,
                        action: "添加",
                        timestamp: item.createdAt,
                        locationName: item.location?.name
                    )
                )
                
                // 修改记录（如果更新时间不同）
                if item.updatedAt != item.createdAt {
                    history.append(
                        ItemHistory(
                            itemName: item.name,
                            action: "修改",
                            timestamp: item.updatedAt,
                            locationName: item.location?.name
                        )
                    )
                }
            }
            
            // 按时间倒序排序并限制数量
            return history.sorted { $0.timestamp > $1.timestamp }.prefix(limit).map { $0 }
            
        } catch {
            print("获取历史记录失败: \(error)")
            return []
        }
    }
}