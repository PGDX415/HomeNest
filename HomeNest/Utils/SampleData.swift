import Foundation
import SwiftData

struct SampleData {
    static func createSampleLocations() -> [StorageLocation] {
        // Create root locations
        let livingRoom = StorageLocation(name: "客厅", type: .room, icon: "house.fill")
        let kitchen = StorageLocation(name: "厨房", type: .room, icon: "fork.knife.circle")
        let bedroom = StorageLocation(name: "卧室", type: .room, icon: "bed.double.fill")
        
        // Create sub-locations
        let tvCabinet = StorageLocation(name: "电视柜", type: .cabinet, parent: livingRoom, icon: "tv")
        let bookshelf = StorageLocation(name: "书架", type: .shelf, parent: livingRoom, icon: "books.vertical")
        
        let fridge = StorageLocation(name: "冰箱", type: .cabinet, parent: kitchen, icon: "refrigerator")
        let pantry = StorageLocation(name: "食品柜", type: .cabinet, parent: kitchen, icon: "cup.and.saucer")
        
        let wardrobe = StorageLocation(name: "衣柜", type: .cabinet, parent: bedroom, icon: "tshirt")
        let nightstand = StorageLocation(name: "床头柜", type: .cabinet, parent: bedroom, icon: "deskclock")
        
        // Set up relationships
        livingRoom.subLocations = [tvCabinet, bookshelf]
        kitchen.subLocations = [fridge, pantry]
        bedroom.subLocations = [wardrobe, nightstand]
        
        return [livingRoom, kitchen, bedroom]
    }
    
    static func createSampleItems(in container: ModelContainer) {
        let context = container.mainContext
        
        // Get or create locations
        var locations: [StorageLocation] = []
        if let existingLocations = try? context.fetch(FetchDescriptor<StorageLocation>()) {
            locations = existingLocations
        } else {
            locations = createSampleLocations()
            for location in locations {
                context.insert(location)
            }
        }
        
        // Create sample items
        let tv = Item(
            name: "55寸智能电视",
            quantity: 1,
            location: locations.first(where: { $0.name == "电视柜" }),
            details: "4K超高清，支持HDR",  // Updated to use 'details'
            value: 3500.0,
            purchaseDate: Calendar.current.date(byAdding: .month, value: -12, to: Date()),
            category: "家电",
            tags: ["娱乐", "客厅"]
        )
        
        let coffee = Item(
            name: "咖啡豆",
            quantity: 2,
            location: locations.first(where: { $0.name == "食品柜" }),
            details: "哥伦比亚精品咖啡豆",  // Updated to use 'details'
            expiryDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
            category: "食品",
            tags: ["饮品", "厨房"]
        )
        
        let shirt = Item(
            name: "白色衬衫",
            quantity: 3,
            location: locations.first(where: { $0.name == "衣柜" }),
            details: "纯棉，尺码L",  // Updated to use 'details'
            value: 299.0,
            category: "衣物",
            tags: ["上衣", "正式"]
        )
        
        // Insert items into context
        context.insert(tv)
        context.insert(coffee)
        context.insert(shirt)
    }
}