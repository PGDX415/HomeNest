import SwiftUI
import SwiftData

struct ValuableItemsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [Item]
    
    // 过滤出有价值且按价值降序排列的物品
    var valuableItems: [Item] {
        allItems
            .filter { ($0.value ?? 0) > 0 }
            .sorted { ($0.value ?? 0) > ($1.value ?? 0) }
    }
    
    var body: some View {
        if valuableItems.isEmpty {
            emptyView
        } else {
            List {
                ForEach(valuableItems, id: \.persistentModelID) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ItemRowView(item: item)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteItem(item)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                        
                        Button {
                            // 编辑操作
                            // TODO: 实现编辑功能
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                    }
                }
            }
            .navigationTitle("高价值物品")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
                .padding()
                .background(
                    Circle()
                        .fill(Color.secondary.opacity(0.1))
                )
            
            Text("暂无高价值物品")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("添加物品时设置价值，即可在此查看高价值物品列表")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("高价值物品")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func deleteItem(_ item: Item) {
        modelContext.delete(item)
    }
}

// 复用现有的 ItemRowView，如果不存在则创建简化版本
struct ItemRowView: View {
    let item: Item
    
    var body: some View {
        HStack {
            if let photoData = item.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "photo")
                    .frame(width: 50, height: 50)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    if let location = item.location {
                        Text(location.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let category = item.category {
                        Text(category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let value = item.value, value > 0 {
                        Text("¥\(String(format: "%.0f", value))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            Text("x\(item.quantity)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ValuableItemsView()
    }
    .modelContainer(for: [Item.self, StorageLocation.self], inMemory: true)
}