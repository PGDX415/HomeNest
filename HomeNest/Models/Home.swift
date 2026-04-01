//
//  Home.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/1.
//

import Foundation
import SwiftData

// 家庭/场所模型
@Model
final class Home {
    var name: String            // 家庭名称，如"主住宅"、"度假屋"、"办公室"
    var address: String?        // 地址（可选）
    var icon: String?           // 图标（SF Symbols 或 emoji）
    var isPrimary: Bool = false // 是否为主家庭
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    @Relationship(deleteRule: .cascade)
    var locations: [StorageLocation] = []
    
    init(name: String, address: String? = nil, icon: String? = nil, isPrimary: Bool = false) {
        self.name = name
        self.address = address
        self.icon = icon
        self.isPrimary = isPrimary
    }
    
    // 计算场所的总物品数量（包括所有子位置的物品）
    func totalItemCount() -> Int {
        var totalCount = 0
        
        // 限制递归深度以防止无限循环（最大10层）
        func countItemsInLocation(_ location: StorageLocation, depth: Int = 0) -> Int {
            guard depth < 10 else { return 0 }
            
            var count = location.items.count
            
            // 递归计算子位置的物品数量
            for subLocation in location.subLocations {
                count += countItemsInLocation(subLocation, depth: depth + 1)
            }
            
            return count
        }
        
        // 计算所有根位置的物品数量
        for location in locations {
            totalCount += countItemsInLocation(location)
        }
        
        return totalCount
    }
}