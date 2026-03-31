import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let item: Item
    
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Photo section
                if let photoData = item.photoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                // Basic info section
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("数量: \(item.quantity)")
                            .font(.title2)
                        
                        Spacer()
                        
                        if let category = item.category {
                            Text(category)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
                
                // Description section - updated to use 'details'
                if let details = item.details, !details.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("描述")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(details)
                    }
                }
                
                // Location section
                if let location = item.location {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("位置")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        HStack {
                            if let icon = location.icon {
                                Image(systemName: icon)
                            } else {
                                Image(systemName: "folder.fill")
                            }
                            Text(locationPath(for: location))
                        }
                    }
                }
                
                // Value section
                if let value = item.value {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("估价")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("¥\(String(format: "%.2f", value))")
                            .font(.title2)
                    }
                }
                
                // Dates section
                HStack {
                    if let purchaseDate = item.purchaseDate {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("购买日期")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text(purchaseDate, style: .date)
                        }
                    }
                    
                    Spacer()
                    
                    if let expiryDate = item.expiryDate {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("保质期")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            let today = Date()
                            let isExpired = expiryDate < today
                            let isExpiringSoon = !isExpired && Calendar.current.date(byAdding: .day, value: 30, to: today)! > expiryDate
                            
                            Text(expiryDate, style: .date)
                                .foregroundColor(isExpired ? .red : (isExpiringSoon ? .orange : .primary))
                        }
                    }
                }
                
                // Tags section
                if !item.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("标签")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            ForEach(item.tags, id: \.self) { tag in
                                Text(tag)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.green.opacity(0.1))
                                    .foregroundColor(.green)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("物品详情")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Label("编辑", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        showingDeleteConfirmation = true
                    }) {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AddItemSheet(location: item.location) { updatedItem in
                // Update existing item properties
                item.name = updatedItem.name
                item.quantity = updatedItem.quantity
                item.details = updatedItem.details  // Updated to use 'details'
                item.value = updatedItem.value
                item.purchaseDate = updatedItem.purchaseDate
                item.expiryDate = updatedItem.expiryDate
                item.category = updatedItem.category
                item.tags = updatedItem.tags
                item.photoData = updatedItem.photoData
                item.location = updatedItem.location
                item.updatedAt = Date()
            }
        }
        .alert("确认删除", isPresented: $showingDeleteConfirmation) {
            Button("删除", role: .destructive) {
                modelContext.delete(item)
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除\"\(item.name)\"吗？此操作无法撤销。")
        }
    }
    
    // Helper function to get full location path
    func locationPath(for location: StorageLocation) -> String {
        var pathComponents: [String] = []
        var currentLocation: StorageLocation? = location
        
        while let current = currentLocation {
            pathComponents.insert(current.name, at: 0)
            currentLocation = current.parent
        }
        
        return pathComponents.joined(separator: " > ")
    }
}

#Preview {
    ItemDetailView(item: Item(name: "测试物品", quantity: 2, details: "这是一个测试物品的描述", category: "测试类别", tags: ["测试", "标签"]))
        .modelContainer(for: [Item.self, StorageLocation.self], inMemory: true)
}
