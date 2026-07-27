import Foundation
import SwiftData
import SwiftUI

// MARK: - LocationType

enum LocationType: String, Codable, CaseIterable {
    case room = "房间"
    case cabinet = "柜子"
    case shelf = "架子"
    case box = "箱子"
    case drawer = "抽屉"
    case custom = "自定义"
}

// MARK: - ItemStatus

enum ItemStatus: String, Codable, CaseIterable {
    case active = "在用"
    case idle = "闲置"
    case lent = "借出"
    case sold = "已售"
    case disposed = "已丢弃"

    var icon: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .idle: return "circle.slash"
        case .lent: return "arrowshape.turn.up.right"
        case .sold: return "tag.fill"
        case .disposed: return "trash"
        }
    }

    var color: Color {
        switch self {
        case .active: return .green
        case .idle: return .orange
        case .lent: return .blue
        case .sold: return .gray
        case .disposed: return .red
        }
    }
}

// MARK: - Home (declared first — no inverse: needed, others point back here)

@Model
final class Home {
    var name: String = ""
    var address: String?
    var icon: String?
    var iconColor: String?
    var isPrimary: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(deleteRule: .cascade)
    var locations: [StorageLocation]?

    @Relationship(deleteRule: .nullify)
    var items: [Item]?

    init(name: String, address: String? = nil, icon: String? = nil, iconColor: String? = nil, isPrimary: Bool = false) {
        self.name = name
        self.address = address
        self.icon = (icon?.isEmpty == true) ? nil : icon
        self.iconColor = iconColor
        self.isPrimary = isPrimary
        self.locations = []
        self.items = []
    }

    func getSafeIconName() -> String {
        guard let icon = self.icon, !icon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "house.fill"
        }
        return icon.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func getIconColor() -> Color {
        guard let colorName = iconColor else { return .primary }
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "indigo": return .indigo
        case "teal": return .teal
        case "gray": return .gray
        default: return .primary
        }
    }

    func getTotalLocationCount() -> Int {
        var totalCount = 0
        func countLocationsInLocation(_ location: StorageLocation, depth: Int = 0) -> Int {
            guard depth < 10 else { return 0 }
            var count = 1
            for subLocation in location.subLocations ?? [] {
                count += countLocationsInLocation(subLocation, depth: depth + 1)
            }
            return count
        }
        for location in locations ?? [] {
            totalCount += countLocationsInLocation(location)
        }
        return totalCount
    }

    func totalItemCount() -> Int {
        var totalCount = 0
        func countItemsInLocation(_ location: StorageLocation, depth: Int = 0) -> Int {
            guard depth < 10 else { return 0 }
            var count = location.items?.count ?? 0
            for subLocation in location.subLocations ?? [] {
                count += countItemsInLocation(subLocation, depth: depth + 1)
            }
            return count
        }
        for location in locations ?? [] {
            totalCount += countItemsInLocation(location)
        }
        return totalCount
    }
}

// MARK: - StorageLocation (declared second — inverse: points to Home, self-referential)

@Model
final class StorageLocation {
    var name: String = ""
    var icon: String?
    var iconColor: String?
    var type: LocationType = LocationType.custom
    var isFavorite: Bool = false

    // Self-referential: subLocations first (no inverse), parent second (inverse points back)
    @Relationship(deleteRule: .cascade)
    var subLocations: [StorageLocation]?

    @Relationship(inverse: \StorageLocation.subLocations)
    var parent: StorageLocation?

    // items — no inverse here (Item will point back)
    @Relationship(deleteRule: .cascade)
    var items: [Item]?

    // home — inverse points back to Home (which is already declared)
    @Relationship(inverse: \Home.locations)
    var home: Home?

    init(name: String, type: LocationType, parent: StorageLocation? = nil, home: Home? = nil, icon: String? = nil, iconColor: String? = nil, isFavorite: Bool = false) {
        self.name = name
        self.type = type
        self.parent = parent
        self.home = home
        self.icon = (icon?.isEmpty == true) ? nil : icon
        self.iconColor = iconColor
        self.isFavorite = isFavorite
        self.subLocations = []
        self.items = []
    }

    func getIconColor() -> Color {
        guard let colorName = iconColor else { return .primary }
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "indigo": return .indigo
        case "teal": return .teal
        case "gray": return .gray
        default: return .primary
        }
    }

    func getSafeIconName() -> String {
        guard let icon = self.icon, !icon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "folder.fill"
        }
        return icon.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func totalItemCount() -> Int {
        var totalCount = items?.count ?? 0
        func countItemsInSubLocations(_ locations: [StorageLocation], depth: Int = 0) -> Int {
            guard depth < 10 else { return 0 }
            var count = 0
            for location in locations {
                count += location.items?.count ?? 0
                count += countItemsInSubLocations(location.subLocations ?? [], depth: depth + 1)
            }
            return count
        }
        totalCount += countItemsInSubLocations(subLocations ?? [])
        return totalCount
    }
}

// MARK: - Item (declared last — all inverses point backward)

@Model
final class Item {
    var name: String = ""
    var quantity: Int = 1
    var needsRestock: Bool = false
    var status: ItemStatus = ItemStatus.active
    var details: String?
    var value: Double?
    var purchaseDate: Date?
    var expiryDate: Date?
    var warrantyEndDate: Date?
    var warrantyNotes: String?
    var lentTo: String?
    var lentDate: Date?
    var expectedReturnDate: Date?
    var category: String?
    var tags: [String] = []
    var photoData: Data?
    var receiptPhotoData: Data?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(inverse: \StorageLocation.items)
    var location: StorageLocation?

    @Relationship(inverse: \Home.items)
    var home: Home?

    // 归属家庭成员
    @Relationship
    var familyMember: FamilyMember?

    init(name: String, quantity: Int = 1, location: StorageLocation? = nil,
         details: String? = nil, value: Double? = nil,
         purchaseDate: Date? = nil, expiryDate: Date? = nil,
         category: String? = nil, tags: [String] = [], photoData: Data? = nil) {
        self.name = name
        self.quantity = quantity
        self.location = location
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

// MARK: - UserProfile

@Model
final class UserProfile {
    var displayName: String = "HomeNest 用户"
    var avatarData: Data?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(displayName: String = "HomeNest 用户", avatarData: Data? = nil) {
        self.displayName = displayName
        self.avatarData = avatarData
    }

    func getAvatarImage() -> Image {
        if let avatarData = self.avatarData,
           let uiImage = UIImage(data: avatarData) {
            return Image(uiImage: uiImage)
        } else {
            return Image(systemName: "person.circle.fill")
        }
    }

    func updateDisplayName(_ newName: String) {
        self.displayName = newName.isEmpty ? "HomeNest 用户" : newName
        self.updatedAt = Date()
    }

    func updateAvatar(_ imageData: Data?) {
        self.avatarData = imageData
        self.updatedAt = Date()
    }
}

// MARK: - ActivityLog

@Model
final class ActivityLog {
    var itemName: String = ""
    var action: String = ""
    var detail: String?
    var timestamp: Date = Date()

    init(itemName: String, action: String, detail: String? = nil) {
        self.itemName = itemName
        self.action = action
        self.detail = detail
        self.timestamp = Date()
    }
}

// MARK: - FamilyMember

@Model
final class FamilyMember {
    var name: String = ""
    var identifier: String?  // Apple ID / 邮箱 / 手机号，用于跨设备关联真实用户
    var emoji: String = "👤"
    var colorName: String = "blue"
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // 关联到此成员的所有物品
    @Relationship(deleteRule: .nullify, inverse: \Item.familyMember)
    var items: [Item]?

    init(name: String, identifier: String? = nil, emoji: String = "👤", colorName: String = "blue") {
        self.name = name
        self.identifier = identifier
        self.emoji = emoji
        self.colorName = colorName
        self.items = []
    }
}
