import Foundation
import SwiftData

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
    var type: LocationType
    var parent: StorageLocation?    // 父位置（可选）
    var isFavorite: Bool = false    // 收藏/标记状态
    
    @Relationship(deleteRule: .cascade, inverse: \StorageLocation.parent)
    var subLocations: [StorageLocation] = []
    
    @Relationship(deleteRule: .cascade)
    var items: [Item] = []
    
    // 新增：关联到家庭
    var home: Home?
    
    init(name: String, type: LocationType, parent: StorageLocation? = nil, home: Home? = nil, icon: String? = nil, isFavorite: Bool = false) {
        self.name = name
        self.type = type
        self.parent = parent
        self.home = home
        self.icon = icon
        self.isFavorite = isFavorite
    }
}