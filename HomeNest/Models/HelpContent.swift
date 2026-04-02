//
//  HelpContent.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/2.
//

import Foundation

// 常见问题模型
struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

// 帮助内容管理器
class HelpContentManager {
    static let shared = HelpContentManager()
    
    private init() {}
    
    // 获取常见问题列表
    func getFAQItems() -> [FAQItem] {
        return [
            FAQItem(
                question: "如何添加新的场所？",
                answer: "点击底部导航栏的「场所」标签，然后点击右上角的「+」按钮，输入场所名称、地址等信息即可创建新的场所。"
            ),
            FAQItem(
                question: "如何在位置中嵌套子位置？",
                answer: "在位置详情页面，点击「添加位置」按钮，在弹出的表单中选择父位置为当前位置，这样就能创建嵌套的子位置结构。"
            ),
            FAQItem(
                question: "物品图片无法显示怎么办？",
                answer: "请确保您有权限访问相册。如果问题仍然存在，请尝试重启应用或重新添加物品图片。"
            ),
            FAQItem(
                question: "如何备份我的数据？",
                answer: "进入「我」→「数据备份」→「导出数据备份」，系统会生成JSON格式的备份文件，您可以保存到iCloud或本地文件系统。"
            ),
            FAQItem(
                question: "如何恢复备份的数据？",
                answer: "进入「我」→「数据备份」→「从文件恢复数据」，选择之前保存的JSON备份文件，系统会自动恢复所有数据。"
            ),
            FAQItem(
                question: "应用锁定功能如何工作？",
                answer: "开启应用锁定后，当您切换到其他应用再返回时，系统会要求您通过Face ID或Touch ID验证身份才能继续使用。"
            ),
            FAQItem(
                question: "如何更改应用主题？",
                answer: "进入「我」→「应用设置」→「应用主题」，可以选择浅色模式、深色模式或跟随系统设置。"
            ),
            FAQItem(
                question: "数据存储在哪里？",
                answer: "所有数据默认存储在您的设备本地，不会上传到任何服务器。如果您启用了iCloud同步，数据会在您的Apple设备间同步。"
            ),
            FAQItem(
                question: "如何删除物品或位置？",
                answer: "在物品或位置详情页面，向左滑动即可看到删除选项，或者长按项目会出现删除菜单。"
            ),
            FAQItem(
                question: "应用需要网络连接吗？",
                answer: "基础功能完全离线可用，不需要网络连接。只有在使用iCloud同步或反馈功能时才需要网络。"
            )
        ]
    }
}