//
//  AppLockView.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/2.
//

import SwiftUI
import LocalAuthentication

struct AppLockView: View {
    @EnvironmentObject private var appLockManager: AppLockManager
    @State private var isAuthenticating = false
    @State private var authenticationError: String?
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            // 主要内容
            VStack(spacing: 32) {
                // 应用图标和名称
                VStack(spacing: 16) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    Text("HomeNest")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // 提示文本
                Text("请验证您的身份")
                    .font(.title2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // 错误信息（如果有）
                if let errorMessage = authenticationError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                
                // 验证按钮（仅在错误时显示）
                if authenticationError != nil {
                    Button(action: {
                        authenticate()
                    }) {
                        Text("重试验证")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
            .onAppear {
                // 自动开始验证
                if !isAuthenticating {
                    authenticate()
                }
            }
        }
        .onReceive(appLockManager.$shouldShowLockScreen) { shouldShow in
            if shouldShow && !isAuthenticating {
                authenticate()
            }
        }
    }
    
    private func authenticate() {
        isAuthenticating = true
        authenticationError = nil
        
        appLockManager.authenticate { success in
            DispatchQueue.main.async {
                self.isAuthenticating = false
                
                if !success {
                    // 检查是否支持生物识别
                    let context = LAContext()
                    var error: NSError?
                    
                    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                        self.authenticationError = "生物识别验证失败，请重试"
                    } else {
                        // 不支持生物识别，直接解锁
                        appLockManager.unlockApp()
                    }
                }
            }
        }
    }
}

#Preview {
    AppLockView()
        .environmentObject(AppLockManager.shared)
}