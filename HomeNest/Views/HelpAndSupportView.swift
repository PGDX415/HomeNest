//
//  HelpAndSupportView.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/2.
//

import SwiftUI

struct HelpAndSupportView: View {
    @State private var faqItems = [FAQItem]()
    @State private var showingFeedbackForm = false
    
    var body: some View {
        List {
            // 常见问题区域
            Section("常见问题") {
                ForEach(faqItems) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.question)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(item.answer)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // 反馈和支持区域
            Section("联系我们") {
                NavigationLink(destination: FeedbackFormView()) {
                    Label("提交反馈", systemImage: "envelope")
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("开发者邮箱")
                            .font(.subheadline)
                        Text("paul.dexin.gong@example.com")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .onTapGesture {
                    // 复制邮箱到剪贴板
                    UIPasteboard.general.string = "paul.dexin.gong@example.com"
                    // 显示提示
                    let alert = UIAlertController(title: "已复制", message: "邮箱地址已复制到剪贴板", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "确定", style: .default))
                    UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
                }
            }
            
            // 使用提示区域
            Section("使用提示") {
                VStack(alignment: .leading, spacing: 12) {
                    Group {
                        HStack {
                            Image(systemName: "house.fill")
                                .foregroundColor(.blue)
                            Text("场所管理：先添加场所，再在场所中添加位置")
                        }
                        
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.green)
                            Text("位置嵌套：支持无限层级的位置结构")
                        }
                        
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.orange)
                            Text("物品分类：为物品设置分类便于快速查找")
                        }
                        
                        HStack {
                            Image(systemName: "icloud.and.arrow.down")
                                .foregroundColor(.purple)
                            Text("数据备份：定期备份重要数据到iCloud")
                        }
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("帮助与支持")
        .onAppear {
            faqItems = HelpContentManager.shared.getFAQItems()
        }
    }
}

#Preview {
    NavigationStack {
        HelpAndSupportView()
    }
}