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
                // Photo section - using cached async image
                CachedAsyncImage(
                    imageData: item.photoData,
                    cacheKey: String(describing: item.persistentModelID),
                    contentMode: .fit,
                    maxWidth: .infinity,
                    maxHeight: 300
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Receipt photo
                if let receiptData = item.receiptPhotoData,
                   let uiImage = UIImage(data: receiptData) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("📄 收据/发票")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    }
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

                        Text(item.status.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(item.status.color.opacity(0.1))
                            .foregroundColor(item.status.color)
                            .cornerRadius(8)

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
                
                // Restock toggle
                HStack {
                    Button(action: {
                        item.needsRestock.toggle()
                        item.updatedAt = Date()
                    }) {
                        HStack {
                            Image(systemName: item.needsRestock ? "cart.fill" : "cart")
                                .foregroundColor(item.needsRestock ? .orange : .secondary)
                            Text(item.needsRestock ? "已在购物清单" : "加入购物清单")
                                .font(.subheadline)
                                .foregroundColor(item.needsRestock ? .orange : .secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(item.needsRestock ? Color.orange.opacity(0.1) : Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    Spacer()
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
                
                // Family member section
                if let familyMember = item.familyMember {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("归属")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        HStack {
                            Text(familyMember.emoji)
                            Text(familyMember.name)
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
                
                // Warranty section
                if let warrantyEnd = item.warrantyEndDate {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("保修")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        let today = Date()
                        let isExpired = warrantyEnd < today
                        let daysRemaining = Calendar.current.dateComponents([.day], from: today, to: warrantyEnd).day ?? 0

                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(isExpired ? .red : .green)
                            Text("截止: \(warrantyEnd, style: .date)")
                                .foregroundColor(isExpired ? .red : (daysRemaining <= 30 ? .orange : .primary))
                            if !isExpired {
                                Text("(剩余 \(daysRemaining) 天)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("(已过期)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }

                        if let notes = item.warrantyNotes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                        }
                    }
                }

                // Lending section
                if item.status == .lent {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("借出详情")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        if let lentTo = item.lentTo {
                            HStack {
                                Image(systemName: "person.fill")
                                Text("借出给: \(lentTo)")
                            }
                            .font(.subheadline)
                        }

                        if let lentDate = item.lentDate {
                            HStack {
                                Image(systemName: "calendar")
                                Text("借出日期: \(lentDate, style: .date)")
                            }
                            .font(.subheadline)
                        }

                        if let returnDate = item.expectedReturnDate {
                            let today = Date()
                            let isOverdue = returnDate < today
                            let daysRemaining = Calendar.current.dateComponents([.day], from: today, to: returnDate).day ?? 0

                            HStack {
                                Image(systemName: isOverdue ? "exclamationmark.triangle.fill" : "calendar.badge.clock")
                                    .foregroundColor(isOverdue ? .red : .orange)
                                Text("预计归还: \(returnDate, style: .date)")
                                    .foregroundColor(isOverdue ? .red : .primary)
                                if isOverdue {
                                    Text("(已逾期 \(abs(daysRemaining)) 天)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                } else {
                                    Text("(剩余 \(daysRemaining) 天)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 4)
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
            AddItemSheet(location: item.location, existingItem: item) { _ in
                // No need to manually copy properties - AddItemSheet updates the existing item directly
                // The item is automatically persisted by SwiftData
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