import Foundation
import SwiftData

// 物品模型
@Model
final class Item {
    var name: String
    var quantity: Int = 1
    var details: String?           // Renamed from 'description' to avoid conflict with reserved property
    var value: Double?              // 估价（保险用）
    var purchaseDate: Date?
    var expiryDate: Date?           // 保质期
    var category: String?           // "家电/衣物/书籍/厨房/食品"等
    var tags: [String] = []         // 自定义标签数组
    var photoData: Data?            // 主照片（压缩 Data），支持未来扩展多图
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    @Relationship
    var location: StorageLocation?  // 所属位置（可选）
    
    // 直接关联到家庭，提升查询性能
    var home: Home?
    
    init(name: String, quantity: Int = 1, location: StorageLocation? = nil, 
         details: String? = nil, value: Double? = nil, 
         purchaseDate: Date? = nil, expiryDate: Date? = nil,
         category: String? = nil, tags: [String] = [], photoData: Data? = nil) {
        self.name = name
        self.quantity = quantity
        self.location = location
        // Initialize home based on location's home if available
        self.home = location?.home
        self.details = details
        self.value = value
        self.purchaseDate = purchaseDate
        self.expiryDate = expiryDate
        self.category = category
        self.tags = tags
        self.photoData = photoData
    }
}