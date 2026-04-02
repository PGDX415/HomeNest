//
//  ThemeManager.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/2.
//

import Foundation
import SwiftUI
import Combine

// 应用主题管理器
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    // 用户偏好设置
    private let userDefaults = UserDefaults.standard
    
    // 主题设置键
    private let appThemeKey = "AppTheme"
    
    // 主题选项
    enum AppTheme: String, CaseIterable, Codable {
        case system = "跟随系统"
        case light = "浅色模式"
        case dark = "深色模式"
        
        var displayName: String {
            return self.rawValue
        }
        
        var colorScheme: ColorScheme? {
            switch self {
            case .system:
                return nil // 使用系统默认
            case .light:
                return .light
            case .dark:
                return .dark
            }
        }
    }
    
    @Published var currentTheme: AppTheme {
        didSet {
            userDefaults.set(currentTheme.rawValue, forKey: appThemeKey)
        }
    }
    
    private init() {
        // 从UserDefaults加载保存的主题设置
        if let savedTheme = userDefaults.string(forKey: appThemeKey),
           let theme = AppTheme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            // 默认跟随系统
            self.currentTheme = .system
        }
    }
    
    // 获取当前实际的颜色方案
    func getCurrentColorScheme() -> ColorScheme? {
        return currentTheme.colorScheme
    }
}