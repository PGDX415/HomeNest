//
//  AppLockManager.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/2.
//

import Foundation
import LocalAuthentication
import Combine
import SwiftUI

// 应用锁定管理器
class AppLockManager: ObservableObject {
    // 单例模式
    static let shared = AppLockManager()
    
    // 用户偏好设置
    private let userDefaults = UserDefaults.standard
    
    // 锁定状态
    @Published var isLocked = false
    @Published var shouldShowLockScreen = false
    
    // 设置键
    private let appLockEnabledKey = "AppLockEnabled"
    private let appLockTimeoutKey = "AppLockTimeout"
    
    // 超时选项（分钟）
    enum LockTimeout: Int, CaseIterable {
        case immediate = 0
        case oneMinute = 1
        case fiveMinutes = 5
        case tenMinutes = 10
        
        var displayName: String {
            switch self {
            case .immediate:
                return "立即锁定"
            case .oneMinute:
                return "1分钟后"
            case .fiveMinutes:
                return "5分钟后"
            case .tenMinutes:
                return "10分钟后"
            }
        }
    }
    
    private init() {
        // 初始化锁定状态
        updateLockState()
        
        // 监听应用状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    // MARK: - Public Properties
    
    var isAppLockEnabled: Bool {
        get {
            return userDefaults.bool(forKey: appLockEnabledKey)
        }
        set {
            userDefaults.set(newValue, forKey: appLockEnabledKey)
            if !newValue {
                // 如果禁用锁定，重置锁定状态
                isLocked = false
                shouldShowLockScreen = false
            }
        }
    }
    
    var lockTimeout: LockTimeout {
        get {
            let rawValue = userDefaults.integer(forKey: appLockTimeoutKey)
            return LockTimeout(rawValue: rawValue) ?? .immediate
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: appLockTimeoutKey)
        }
    }
    
    // MARK: - Public Methods
    
    // 验证生物识别
    func authenticate(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // 检查生物识别是否可用
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "验证身份以访问HomeNest"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        // 验证成功
                        self.isLocked = false
                        self.shouldShowLockScreen = false
                        completion(true)
                    } else {
                        // 验证失败
                        completion(false)
                    }
                }
            }
        } else {
            // 生物识别不可用，直接解锁（或显示错误）
            DispatchQueue.main.async {
                self.isLocked = false
                self.shouldShowLockScreen = false
                completion(true)
            }
        }
    }
    
    // 手动锁定应用
    func lockApp() {
        isLocked = true
        shouldShowLockScreen = true
    }
    
    // 手动解锁应用
    func unlockApp() {
        isLocked = false
        shouldShowLockScreen = false
    }
    
    // MARK: - Private Methods
    
    @objc private func appDidEnterBackground() {
        guard isAppLockEnabled else { return }
        
        // 立即锁定或设置定时器
        if lockTimeout == .immediate {
            isLocked = true
        } else {
            // 设置超时锁定
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(lockTimeout.rawValue * 60)) {
                if self.isAppLockEnabled && !self.isLocked {
                    self.isLocked = true
                }
            }
        }
    }
    
    @objc private func appWillEnterForeground() {
        guard isAppLockEnabled, isLocked else {
            shouldShowLockScreen = false
            return
        }
        
        // 需要显示锁定屏幕
        shouldShowLockScreen = true
    }
    
    private func updateLockState() {
        // 根据设置更新锁定状态
        if !isAppLockEnabled {
            isLocked = false
            shouldShowLockScreen = false
        }
    }
}