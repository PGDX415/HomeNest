//
//  SplashView.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/1.
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var opacity = 0.0
    
    var body: some View {
        ZStack {
            // 渐变背景 - 温馨的家庭色调
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.92, blue: 0.89), // 柔和米色
                    Color(red: 0.88, green: 0.82, blue: 0.75)  // 温暖浅棕色
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) { // 减少 spacing 从 30 到 20
                Spacer() // 添加顶部 Spacer 让内容更居中
                
                // 主要图标 - 使用系统图标模拟家庭物品管理
                Image(systemName: "house.fill")
                    .font(.system(size: 70, weight: .thin)) // 稍微减小图标大小
                    .foregroundColor(Color(red: 0.65, green: 0.45, blue: 0.35)) // 温暖棕色
                    .padding(25) // 稍微增加内边距
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.85))
                            .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 5)
                    )
                
                // 应用名称
                Text("家物管")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.55, green: 0.35, blue: 0.25)) // 深棕色
                    .padding(.horizontal, 20)
                
                // 副标题
                Text("智能家庭物品管理专家")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.65, green: 0.55, blue: 0.45)) // 中等棕色
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // 装饰性图标行 - 代表不同类型的物品
                HStack(spacing: 25) {
                    Image(systemName: "folder.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.75, green: 0.65, blue: 0.55))
                    
                    Image(systemName: "photo.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.75, green: 0.65, blue: 0.55))
                    
                    Image(systemName: "tag.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.75, green: 0.65, blue: 0.55))
                    
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.75, green: 0.65, blue: 0.55))
                }
                .padding(.top, 15) // 稍微增加顶部间距
                
                Spacer() // 添加底部 Spacer 平衡布局
                
                // 版权信息
                Text("© 2026 家物管")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.75, green: 0.65, blue: 0.55))
                    .padding(.bottom, 20)
            }
            .opacity(opacity)
            .onAppear {
                // 渐显动画
                withAnimation(.easeInOut(duration: 1.2)) {
                    opacity = 1.0
                }
                
                // 2秒后跳转到主界面
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        opacity = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        isActive = true
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            ContentView()
        }
    }
}

#Preview {
    SplashView()
}