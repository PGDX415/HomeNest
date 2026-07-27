//
//  ExpiryNotificationManager.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/7/27.
//

import Foundation
import UserNotifications
import SwiftData

/// 管理物品保质期到期提醒的本地通知
final class ExpiryNotificationManager {
    static let shared = ExpiryNotificationManager()

    @MainActor var isAuthorized = false

    private init() {}

    // MARK: - 权限请求

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            print("🔔 通知权限: \(granted ? "已授权" : "被拒绝")")
        } catch {
            print("🔔 通知权限请求失败: \(error)")
        }
    }

    // MARK: - 调度到期提醒

    /// 扫描所有物品，为即将过期的物品设置通知
    func scheduleExpiryNotifications(for items: [Item]) {
        let center = UNUserNotificationCenter.current()

        // 仅清除过期类通知，保留其他类型
        center.removePendingNotificationRequests(withPrefix: "expiry-")

        let now = Date()
        let calendar = Calendar.current

        for item in items {
            guard let expiryDate = item.expiryDate else { continue }

            // 只提醒未来到期（或今天到期）的物品
            guard expiryDate >= calendar.startOfDay(for: now) else { continue }

            let daysRemaining = calendar.dateComponents([.day], from: now, to: expiryDate).day ?? 0

            // 根据剩余天数决定提醒时机
            var reminderDays: [Int] = []
            if daysRemaining > 7 {
                reminderDays = [7, 3, 1, 0]  // 提前7天、3天、1天、当天
            } else if daysRemaining > 3 {
                reminderDays = [3, 1, 0]
            } else if daysRemaining > 1 {
                reminderDays = [1, 0]
            } else {
                reminderDays = [0]  // 仅当天
            }

            for daysBefore in reminderDays {
                guard let triggerDate = calendar.date(byAdding: .day, value: -daysBefore, to: expiryDate) else {
                    continue
                }
                // 跳过已经过去的时间点
                guard triggerDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = "🔔 物品即将到期"
                if daysBefore == 0 {
                    content.body = "「\(item.name)」今天到期！"
                } else {
                    content.body = "「\(item.name)」将在 \(daysBefore) 天后到期"
                }
                content.sound = .default
                content.badge = 1

                let dateComponents = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: triggerDate
                )
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: dateComponents,
                    repeats: false
                )

                let identifier = "expiry-\(item.persistentModelID.hashValue)-\(daysBefore)"
                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )

                center.add(request) { error in
                    if let error = error {
                        print("🔔 添加通知失败: \(error)")
                    }
                }
            }
        }
        print("🔔 已为 \(items.count) 个物品安排到期提醒")
    }

    /// 扫描所有物品，为保修即将到期的物品设置通知
    func scheduleWarrantyNotifications(for items: [Item]) {
        let center = UNUserNotificationCenter.current()

        // 仅清除保修类通知，保留其他类型
        center.removePendingNotificationRequests(withPrefix: "warranty-")

        let now = Date()
        let calendar = Calendar.current

        for item in items {
            guard let warrantyEnd = item.warrantyEndDate else { continue }
            guard warrantyEnd >= calendar.startOfDay(for: now) else { continue }

            let daysRemaining = calendar.dateComponents([.day], from: now, to: warrantyEnd).day ?? 0

            // 保修提醒：提前30天、14天、7天
            var reminderDays: [Int] = []
            if daysRemaining > 30 {
                reminderDays = [30, 14, 7]
            } else if daysRemaining > 14 {
                reminderDays = [14, 7]
            } else if daysRemaining > 7 {
                reminderDays = [7]
            } else {
                reminderDays = [daysRemaining] // 最后几天每天提醒
            }

            for daysBefore in reminderDays {
                guard let triggerDate = calendar.date(byAdding: .day, value: -daysBefore, to: warrantyEnd),
                      triggerDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = "🛡️ 保修即将到期"
                if daysBefore == 0 {
                    content.body = "「\(item.name)」的保修今天到期！"
                } else {
                    content.body = "「\(item.name)」保修将在 \(daysBefore) 天后到期"
                }
                content.sound = .default
                content.badge = 1

                let dateComponents = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: triggerDate
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

                let identifier = "warranty-\(item.persistentModelID.hashValue)-\(daysBefore)"
                let request = UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )

                center.add(request) { error in
                    if let error = error {
                        print("🛡️ 添加保修通知失败: \(error)")
                    }
                }
            }
        }
        print("🛡️ 已为 \(items.count) 个物品安排保修提醒")
    }

    /// 调度所有通知（保质期 + 保修）
    func scheduleAllNotifications(for items: [Item]) {
        scheduleExpiryNotifications(for: items)
        scheduleWarrantyNotifications(for: items)
    }

    /// 清除单个物品的所有通知
    func removeNotifications(for item: Item) {
        let prefix = "expiry-\(item.persistentModelID.hashValue)"
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix(prefix) }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    /// 清除所有到期通知
    func removeAllExpiryNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withPrefix: "expiry-")
    }
}

// MARK: - Helper

extension UNUserNotificationCenter {
    func removePendingNotificationRequests(withPrefix prefix: String) {
        getPendingNotificationRequests { requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix(prefix) }
                .map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
