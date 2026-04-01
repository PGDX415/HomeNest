import Foundation
import SwiftData
import SwiftUI

// 位置类型枚举
enum LocationType: String, Codable, CaseIterable {
    case room = "房间"
    case cabinet = "柜子"
    case shelf = "架子"
    case box = "箱子"
    case drawer = "抽屉"
    case custom = "自定义"
}

// 存放位置模型（支持无限层级嵌套）
@Model
final class StorageLocation {
    var name: String
    var icon: String?               // SF Symbols 或 emoji（如 "🛋️"）
    var iconColor: String?          // 图标颜色名称（"primary", "blue", "green", "orange", "red", "purple", "indigo", "teal", "gray"）
    var type: LocationType
    var parent: StorageLocation?    // 父位置（可选）
    var isFavorite: Bool = false    // 收藏/标记状态
    
    @Relationship(deleteRule: .cascade, inverse: \StorageLocation.parent)
    var subLocations: [StorageLocation] = []
    
    @Relationship(deleteRule: .cascade)
    var items: [Item] = []
    
    // 新增：关联到家庭
    var home: Home?
    
    init(name: String, type: LocationType, parent: StorageLocation? = nil, home: Home? = nil, icon: String? = nil, iconColor: String? = nil, isFavorite: Bool = false) {
        self.name = name
        self.type = type
        self.parent = parent
        self.home = home
        self.icon = icon
        self.iconColor = iconColor
        self.isFavorite = isFavorite
    }
    
    // 将颜色名称转换为实际 Color
    func getIconColor() -> Color {
        guard let colorName = iconColor else {
            return .primary
        }
        
        switch colorName {
        case "blue":
            return .blue
        case "green":
            return .green
        case "orange":
            return .orange
        case "red":
            return .red
        case "purple":
            return .purple
        case "indigo":
            return .indigo
        case "teal":
            return .teal
        case "gray":
            return .gray
        default:
            return .primary
        }
    }
    
    // 安全获取图标名称，确保返回有效的SF Symbols名称
    func getSafeIconName() -> String {
        guard let iconName = icon else {
            return "folder.fill"
        }
        
        let trimmedIcon = iconName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedIcon.isEmpty {
            // 调试：打印空图标信息
            print("⚠️ StorageLocation '\(name)' has empty icon string: '\(iconName)'")
            return "folder.fill"
        }
        return trimmedIcon
    }
    
    // 计算位置的总物品数量（包括所有子位置的物品）
    func totalItemCount() -> Int {
        var totalCount = items.count
        
        // 限制递归深度以防止无限循环（最大10层）
        func countItemsInSubLocations(_ locations: [StorageLocation], depth: Int = 0) -> Int {
            guard depth < 10 else { return 0 }
            
            var count = 0
            for location in locations {
                count += location.items.count
                count += countItemsInSubLocations(location.subLocations, depth: depth + 1)
            }
            return count
        }
        
        totalCount += countItemsInSubLocations(subLocations)
        return totalCount
    }
}
