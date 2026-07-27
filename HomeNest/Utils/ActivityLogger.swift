//
//  ActivityLogger.swift
//  HomeNest
//

import SwiftData
import Foundation

struct ActivityLogger {
    static func log(context: ModelContext, itemName: String, action: String, detail: String? = nil) {
        let entry = ActivityLog(itemName: itemName, action: action, detail: detail)
        context.insert(entry)
        try? context.save()
        print("📝 操作日志: \(action) - \(itemName)")
    }

    static func logItemCreated(_ item: Item, context: ModelContext) {
        let location = item.location?.name ?? "未知"
        log(context: context, itemName: item.name, action: "添加", detail: "位置: \(location)")
    }

    static func logItemUpdated(_ item: Item, context: ModelContext) {
        log(context: context, itemName: item.name, action: "编辑")
    }

    static func logItemDeleted(_ item: Item, context: ModelContext) {
        log(context: context, itemName: item.name, action: "删除")
    }

    static func logItemMoved(_ item: Item, to locationName: String, context: ModelContext) {
        log(context: context, itemName: item.name, action: "移动", detail: "→ \(locationName)")
    }

    static func logItemStatusChanged(_ item: Item, context: ModelContext) {
        log(context: context, itemName: item.name, action: "状态变更", detail: item.status.rawValue)
    }
}
