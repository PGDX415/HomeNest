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
}