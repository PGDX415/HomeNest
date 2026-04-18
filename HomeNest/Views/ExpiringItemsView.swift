import SwiftUI
import SwiftData

struct ExpiringItemsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [Item]
    
    // 获取即将过期的物品（30天内）
    var expiringSoonItems: [Item] {
        let today = Date()
        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: today)!
        
        return allItems
            .filter { item in
                if let expiryDate = item.expiryDate {
                    return expiryDate >= today && expiryDate <= nextMonth
                }
                return false
            }
            .sorted { $0.expiryDate ?? Date.distantFuture < $1.expiryDate ?? Date.distantFuture }
    }
    
    var body: some View {
        if expiringSoonItems.isEmpty {
            emptyView
        } else {
            List {
                ForEach(expiringSoonItems, id: \.persistentModelID) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ExpiringItemRowView(item: item)
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
            .navigationTitle("即将过期")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
                .padding()
                .background(
                    Circle()
                        .fill(Color.secondary.opacity(0.1))
                )
            
            Text("暂无即将过期物品")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("为物品设置保质期，即可在此查看即将过期的物品提醒")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("即将过期")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func deleteItem(_ item: Item) {
        modelContext.delete(item)
    }
}

// 专门用于显示即将过期物品的行视图
struct ExpiringItemRowView: View {
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
                    
                    if let expiryDate = item.expiryDate {
                        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
                        if daysUntilExpiry <= 7 {
                            Text("\(daysUntilExpiry)天后过期")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                        } else {
                            Text("\(daysUntilExpiry)天后过期")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
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
        ExpiringItemsView()
    }
    .modelContainer(for: [Item.self, StorageLocation.self], inMemory: true)
}