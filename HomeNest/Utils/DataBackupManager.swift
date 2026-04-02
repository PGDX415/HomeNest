//
//  DataBackupManager.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/2.
//

import Foundation
import SwiftData
import SwiftUI

// 数据备份管理器
class DataBackupManager {
    static let shared = DataBackupManager()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 导出所有数据为JSON文件
    /// - Parameters:
    ///   - context: ModelContext用于获取数据
    ///   - completion: 完成回调，返回文件URL或错误
    func exportDataAsJSON(context: ModelContext, completion: @escaping (Result<URL, Error>) -> Void) {
        do {
            // 创建备份数据结构
            let backupData = try createBackupData(context: context)
            
            // 转换为JSON数据
            let jsonData = try JSONSerialization.data(withJSONObject: backupData, options: [.prettyPrinted, .sortedKeys])
            
            // 保存到文件
            let fileURL = try saveJSONToFile(jsonData: jsonData)
            
            completion(.success(fileURL))
        } catch {
            completion(.failure(error))
        }
    }
    
    /// 从JSON文件导入数据
    /// - Parameters:
    ///   - fileURL: JSON文件URL（可能为安全范围URL）
    ///   - context: ModelContext用于保存数据
    ///   - completion: 完成回调
    func importDataFromJSON(fileURL: URL, context: ModelContext, completion: @escaping (Result<Int, Error>) -> Void) {
        // 处理安全范围URL（来自.fileImporter）
        var jsonData: Data?
        var readError: Error?
        
        if fileURL.startAccessingSecurityScopedResource() {
            do {
                jsonData = try Data(contentsOf: fileURL)
            } catch {
                readError = error
            }
            fileURL.stopAccessingSecurityScopedResource()
        } else {
            // 如果不是安全范围URL，直接读取
            do {
                jsonData = try Data(contentsOf: fileURL)
            } catch {
                readError = error
            }
        }
        
        if let error = readError {
            completion(.failure(error))
            return
        }
        
        guard let jsonData = jsonData else {
            completion(.failure(BackupError.invalidFormat))
            return
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            guard let backupData = jsonObject as? [String: Any] else {
                throw BackupError.invalidFormat
            }
            
            // 清除现有数据（可选：用户可以选择是否清空现有数据）
            // clearAllData(context: context)
            
            try restoreData(from: backupData, context: context)
            try context.save()
            
            // 计算恢复的数据项数量
            let itemCount = try getItemCount(context: context)
            completion(.success(itemCount))
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Private Methods
    
    /// 创建备份数据结构
    private func createBackupData(context: ModelContext) throws -> [String: Any] {
        var backupData: [String: Any] = [:]
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
        
        // 备份用户配置
        do {
            let userProfiles = try fetchAllUserProfiles(context: context)
            var userProfileDtos: [[String: Any]] = []
            
            for profile in userProfiles {
                var dto: [String: Any] = [
                    "displayName": profile.displayName,
                    "createdAt": dateFormatter.string(from: profile.createdAt),
                    "updatedAt": dateFormatter.string(from: profile.updatedAt)
                ]
                
                if let avatarData = profile.avatarData {
                    dto["avatarData"] = avatarData.base64EncodedString()
                }
                
                userProfileDtos.append(dto)
            }
            
            backupData["userProfiles"] = userProfileDtos
        }
        
        // 备份家庭/场所
        let homes: [Home]
        do {
            homes = try fetchAllHomes(context: context)
            var homeDtos: [[String: Any]] = []
            
            for (index, home) in homes.enumerated() {
                let homeDto: [String: Any] = [
                    "name": home.name,
                    "address": home.address ?? NSNull(),
                    "icon": home.icon ?? NSNull(),
                    "iconColor": home.iconColor ?? NSNull(),
                    "isPrimary": home.isPrimary,
                    "createdAt": dateFormatter.string(from: home.createdAt),
                    "updatedAt": dateFormatter.string(from: home.updatedAt),
                    "backupId": "home_\(index)" // 添加备份ID用于关联重建
                ]
                homeDtos.append(homeDto)
            }
            
            backupData["homes"] = homeDtos
        }
        
        // 备份位置（包含关联信息）
        let locations: [StorageLocation]
        do {
            locations = try fetchAllLocations(context: context)
            var locationDtos: [[String: Any]] = []
            
            // 创建位置到索引的映射
            var locationIndexMap: [ObjectIdentifier: Int] = [:]
            for (index, location) in locations.enumerated() {
                locationIndexMap[ObjectIdentifier(location)] = index
            }
            
            for (index, location) in locations.enumerated() {
                var locationDto: [String: Any] = [
                    "name": location.name,
                    "type": location.type.rawValue,
                    "isFavorite": location.isFavorite,
                    "backupId": "location_\(index)" // 添加备份ID
                ]
                
                // 添加图标信息
                if let icon = location.icon {
                    locationDto["icon"] = icon
                }
                if let iconColor = location.iconColor {
                    locationDto["iconColor"] = iconColor
                }
                
                // 添加关联信息（使用备份ID而不是persistentModelID）
                if let parent = location.parent,
                   let parentIndex = locationIndexMap[ObjectIdentifier(parent)] {
                    locationDto["parentId"] = "location_\(parentIndex)"
                }
                if let home = location.home {
                    // 找到home在数组中的索引
                    if let homeIndex = homes.firstIndex(where: { $0 === home }) {
                        locationDto["homeId"] = "home_\(homeIndex)"
                    }
                }
                
                locationDtos.append(locationDto)
            }
            
            backupData["locations"] = locationDtos
        }
        
        // 备份物品（包含位置关联）
        do {
            let items = try fetchAllItems(context: context)
            var itemDtos: [[String: Any]] = []
            
            for (index, item) in items.enumerated() {
                var itemDto: [String: Any] = [
                    "name": item.name,
                    "quantity": item.quantity,
                    "details": item.details ?? NSNull(),
                    "value": item.value ?? NSNull(),
                    "category": item.category ?? NSNull(),
                    "tags": item.tags,
                    "createdAt": dateFormatter.string(from: item.createdAt),
                    "updatedAt": dateFormatter.string(from: item.updatedAt),
                    "backupId": "item_\(index)" // 添加备份ID
                ]
                
                // 添加日期信息
                if let purchaseDate = item.purchaseDate {
                    itemDto["purchaseDate"] = dateFormatter.string(from: purchaseDate)
                }
                if let expiryDate = item.expiryDate {
                    itemDto["expiryDate"] = dateFormatter.string(from: expiryDate)
                }
                
                // 添加图片数据
                if let photoData = item.photoData {
                    itemDto["photoData"] = photoData.base64EncodedString()
                }
                
                // 添加位置关联
                if let location = item.location {
                    // 找到location在数组中的索引
                    if let locationIndex = locations.firstIndex(where: { $0 === location }) {
                        itemDto["locationId"] = "location_\(locationIndex)"
                    }
                }
                
                itemDtos.append(itemDto)
            }
            
            backupData["items"] = itemDtos
        }
        
        // 添加元数据
        backupData["metadata"] = [
            "version": "1.0",
            "exportedAt": dateFormatter.string(from: Date()),
            "appName": "HomeNest",
            "deviceModel": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion
        ]
        
        return backupData
    }
    
    /// 从备份数据恢复
    private func restoreData(from backupData: [String: Any], context: ModelContext) throws {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
        
        // 存储恢复的对象映射，用于重建关联
        var restoredHomes: [String: Home] = [:]
        var restoredLocations: [String: StorageLocation] = [:]
        
        // 恢复用户配置
        if let userProfileDtos = backupData["userProfiles"] as? [[String: Any]] {
            for dto in userProfileDtos {
                let profile = UserProfile()
                profile.displayName = dto["displayName"] as? String ?? "HomeNest 用户"
                
                if let createdAtStr = dto["createdAt"] as? String,
                   let createdAt = dateFormatter.date(from: createdAtStr) {
                    profile.createdAt = createdAt
                }
                
                if let updatedAtStr = dto["updatedAt"] as? String,
                   let updatedAt = dateFormatter.date(from: updatedAtStr) {
                    profile.updatedAt = updatedAt
                }
                
                if let avatarDataStr = dto["avatarData"] as? String,
                   let avatarData = Data(base64Encoded: avatarDataStr) {
                    profile.avatarData = avatarData
                }
                
                context.insert(profile)
            }
        }
        
        // 恢复家庭/场所
        if let homeDtos = backupData["homes"] as? [[String: Any]] {
            for dto in homeDtos {
                let name = dto["name"] as? String ?? "未命名场所"
                let address = dto["address"] as? String
                let icon = dto["icon"] as? String
                let iconColor = dto["iconColor"] as? String
                let isPrimary = dto["isPrimary"] as? Bool ?? false
                
                let home = Home(name: name, address: address, icon: icon, iconColor: iconColor, isPrimary: isPrimary)
                
                if let createdAtStr = dto["createdAt"] as? String,
                   let createdAt = dateFormatter.date(from: createdAtStr) {
                    home.createdAt = createdAt
                }
                
                if let updatedAtStr = dto["updatedAt"] as? String,
                   let updatedAt = dateFormatter.date(from: updatedAtStr) {
                    home.updatedAt = updatedAt
                }
                
                context.insert(home)
                
                // 保存备份ID映射
                if let backupId = dto["backupId"] as? String {
                    restoredHomes[backupId] = home
                }
            }
        }
        
        // 恢复位置（第一遍：创建对象）
        var locationDtos: [[String: Any]] = []
        if let dtos = backupData["locations"] as? [[String: Any]] {
            locationDtos = dtos
            for dto in locationDtos {
                let name = dto["name"] as? String ?? "未命名位置"
                let typeRawValue = dto["type"] as? String ?? "custom"
                let type = LocationType(rawValue: typeRawValue) ?? .custom
                let isFavorite = dto["isFavorite"] as? Bool ?? false
                let icon = dto["icon"] as? String
                let iconColor = dto["iconColor"] as? String
                
                let location = StorageLocation(
                    name: name,
                    type: type,
                    parent: nil, // 暂时不设置父级
                    home: nil,   // 暂时不设置家庭
                    icon: icon,
                    iconColor: iconColor,
                    isFavorite: isFavorite
                )
                
                context.insert(location)
                
                // 保存备份ID映射
                if let backupId = dto["backupId"] as? String {
                    restoredLocations[backupId] = location
                }
            }
        }
        
        // 恢复位置（第二遍：设置关联）
        for (index, dto) in locationDtos.enumerated() {
            guard let location = restoredLocations["location_\(index)"] else { continue }
            
            // 设置父级位置
            if let parentId = dto["parentId"] as? String,
               let parentLocation = restoredLocations[parentId] {
                location.parent = parentLocation
            }
            
            // 设置家庭关联
            if let homeId = dto["homeId"] as? String,
               let home = restoredHomes[homeId] {
                location.home = home
            }
        }
        
        // 恢复物品
        if let itemDtos = backupData["items"] as? [[String: Any]] {
            for dto in itemDtos {
                let name = dto["name"] as? String ?? "未命名物品"
                let quantity = dto["quantity"] as? Int ?? 1
                let details = dto["details"] as? String
                let value = dto["value"] as? Double
                let category = dto["category"] as? String
                let tags = dto["tags"] as? [String] ?? []
                let photoData = (dto["photoData"] as? String).flatMap { Data(base64Encoded: $0) }
                
                let item = Item(
                    name: name,
                    quantity: quantity,
                    location: nil, // 暂时不设置位置
                    details: details,
                    value: value,
                    purchaseDate: nil,
                    expiryDate: nil,
                    category: category,
                    tags: tags,
                    photoData: photoData
                )
                
                // 设置日期
                if let createdAtStr = dto["createdAt"] as? String,
                   let createdAt = dateFormatter.date(from: createdAtStr) {
                    item.createdAt = createdAt
                }
                
                if let updatedAtStr = dto["updatedAt"] as? String,
                   let updatedAt = dateFormatter.date(from: updatedAtStr) {
                    item.updatedAt = updatedAt
                }
                
                if let purchaseDateStr = dto["purchaseDate"] as? String,
                   let purchaseDate = dateFormatter.date(from: purchaseDateStr) {
                    item.purchaseDate = purchaseDate
                }
                
                if let expiryDateStr = dto["expiryDate"] as? String,
                   let expiryDate = dateFormatter.date(from: expiryDateStr) {
                    item.expiryDate = expiryDate
                }
                
                // 设置位置关联
                if let locationId = dto["locationId"] as? String,
                   let location = restoredLocations[locationId] {
                    item.location = location
                }
                
                context.insert(item)
            }
        }
    }
    
    /// 保存JSON数据到文件
    private func saveJSONToFile(jsonData: Data) throws -> URL {
        let fileName = "HomeNest_Backup_\(Date().formatted(.iso8601.dateSeparator(.dash).timeSeparator(.colon))).json"
        
        // 使用文档目录
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        try jsonData.write(to: fileURL)
        return fileURL
    }
    
    /// 获取所有用户配置
    private func fetchAllUserProfiles(context: ModelContext) throws -> [UserProfile] {
        let descriptor = FetchDescriptor<UserProfile>()
        return try context.fetch(descriptor)
    }
    
    /// 获取所有家庭/场所
    private func fetchAllHomes(context: ModelContext) throws -> [Home] {
        let descriptor = FetchDescriptor<Home>()
        return try context.fetch(descriptor)
    }
    
    /// 获取所有位置
    private func fetchAllLocations(context: ModelContext) throws -> [StorageLocation] {
        let descriptor = FetchDescriptor<StorageLocation>()
        return try context.fetch(descriptor)
    }
    
    /// 获取所有物品
    private func fetchAllItems(context: ModelContext) throws -> [Item] {
        let descriptor = FetchDescriptor<Item>()
        return try context.fetch(descriptor)
    }
    
    /// 获取物品总数（用于导入后统计）
    private func getItemCount(context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<Item>()
        return try context.fetchCount(descriptor)
    }
    
    /// 清除所有现有数据（谨慎使用）
    private func clearAllData(context: ModelContext) {
        // 删除所有物品
        do {
            let itemDescriptor = FetchDescriptor<Item>()
            let items = try context.fetch(itemDescriptor)
            for item in items {
                context.delete(item)
            }
        } catch {
            print("清除物品失败: \(error)")
        }
        
        // 删除所有位置
        do {
            let locationDescriptor = FetchDescriptor<StorageLocation>()
            let locations = try context.fetch(locationDescriptor)
            for location in locations {
                context.delete(location)
            }
        } catch {
            print("清除位置失败: \(error)")
        }
        
        // 删除所有家庭
        do {
            let homeDescriptor = FetchDescriptor<Home>()
            let homes = try context.fetch(homeDescriptor)
            for home in homes {
                context.delete(home)
            }
        } catch {
            print("清除家庭失败: \(error)")
        }
        
        // 删除所有用户配置
        do {
            let profileDescriptor = FetchDescriptor<UserProfile>()
            let profiles = try context.fetch(profileDescriptor)
            for profile in profiles {
                context.delete(profile)
            }
        } catch {
            print("清除用户配置失败: \(error)")
        }
    }
    
    // MARK: - Error Types
    
    enum BackupError: Error, LocalizedError {
        case invalidFormat
        case noDataToExport
        
        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "备份文件格式无效"
            case .noDataToExport:
                return "没有数据可导出"
            }
        }
    }
}