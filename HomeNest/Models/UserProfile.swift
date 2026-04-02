//
//  UserProfile.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/2.
//

import Foundation
import SwiftData
import SwiftUI

// 用户配置模型，用于存储个人信息
@Model
final class UserProfile {
    var displayName: String          // 显示名称
    var avatarData: Data?           // 头像图片数据（PNG格式）
    var createdAt: Date = Date()    // 创建时间
    var updatedAt: Date = Date()    // 更新时间
    
    init(displayName: String = "HomeNest 用户", avatarData: Data? = nil) {
        self.displayName = displayName
        self.avatarData = avatarData
    }
    
    // 获取头像图片，如果没有则返回默认头像
    func getAvatarImage() -> Image {
        if let avatarData = self.avatarData,
           let uiImage = UIImage(data: avatarData) {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: "person.circle.fill")
        }
    }
    
    // 更新显示名称
    func updateDisplayName(_ newName: String) {
        self.displayName = newName.isEmpty ? "HomeNest 用户" : newName
        self.updatedAt = Date()
    }
    
    // 更新头像
    func updateAvatar(_ imageData: Data?) {
        self.avatarData = imageData
        self.updatedAt = Date()
    }
}