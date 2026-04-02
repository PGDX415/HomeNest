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
        do {
            let homes = try fetchAllHomes(context: context)
            var homeDtos: [[String: Any]] = []
            
            for home in homes {
                let homeDto: [String: Any] = [
                    "name": home.name,
                    "address": home.address ?? NSNull(),
                    "icon": home.icon ?? NSNull(),
                    "iconColor": home.iconColor ?? NSNull(),
                    "isPrimary": home.isPrimary,
                    "createdAt": dateFormatter.string(from: home.createdAt),
                    "updatedAt": dateFormatter.string(from: home.updatedAt)
                ]
                homeDtos.append(homeDto)
            }
            
            backupData["homes"] = homeDtos
        }
        
        // 备份位置（简化版，不处理父子关系）
        do {
            let locations = try fetchAllLocations(context: context)
            var locationDtos: [[String: Any]] = []
            
            for location in locations {
                var locationDto: [String: Any] = [
                    "name": location.name,
                    "type": location.type.rawValue,
                    "isFavorite": location.isFavorite
                ]
                
                // 添加图标信息
                if let icon = location.icon {
                    locationDto["icon"] = icon
                }
                if let iconColor = location.iconColor {
                    locationDto["iconColor"] = iconColor
                }
                
                locationDtos.append(locationDto)
            }
            
            backupData["locations"] = locationDtos
        }
        
        // 备份物品（简化版，不处理位置关联）
        do {
            let items = try fetchAllItems(context: context)
            var itemDtos: [[String: Any]] = []
            
            for item in items {
                var itemDto: [String: Any] = [
                    "name": item.name,
                    "quantity": item.quantity,
                    "details": item.details ?? NSNull(),
                    "value": item.value ?? NSNull(),
                    "category": item.category ?? NSNull(),
                    "tags": item.tags,
                    "createdAt": dateFormatter.string(from: item.createdAt),
                    "updatedAt": dateFormatter.string(from: item.updatedAt)
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