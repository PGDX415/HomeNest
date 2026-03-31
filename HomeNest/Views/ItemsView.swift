import SwiftUI
import SwiftData

struct ItemsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    @State private var showingAddItemSheet = false
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var showExpiringSoon = false
    
    init() {
        // Default query for all items sorted by name
        _items = Query(sort: \Item.name)
    }
    
    // Filtered items based on search and filters
    var filteredItems: [Item] {
        var filtered = items
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                (item.category?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                item.tags.contains { tag in
                    tag.localizedCaseInsensitiveContains(searchText)
                } ||
                (item.location?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply expiring soon filter
        if showExpiringSoon {
            let today = Date()
            let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: today)!
            filtered = filtered.filter { item in
                if let expiryDate = item.expiryDate {
                    return expiryDate >= today && expiryDate <= nextMonth
                }
                return false
            }
        }
        
        return filtered
    }
    
    // Get unique categories for filtering
    var categories: [String] {
        Array(Set(items.compactMap { $0.category }))
            .sorted()
    }
    
    var body: some View {
        NavigationStack {
            List(filteredItems, id: \.persistentModelID) { item in
                NavigationLink(destination: ItemDetailView(item: item)) {
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
                        
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.headline)
                            
                            HStack {
                                if let location = item.location {
                                    Text(location.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let category = item.category {
                                    Text("• \(category)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if !item.tags.isEmpty {
                                HStack(spacing: 4) {
                                    ForEach(item.tags.prefix(2), id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .foregroundColor(.blue)
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Text("\(item.quantity)")
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("物品")
            .searchable(text: $searchText, prompt: "搜索物品、位置或标签")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Category filter
                        Section("类别") {
                            Button(action: {
                                selectedCategory = nil
                            }) {
                                Label("全部", systemImage: selectedCategory == nil ? "checkmark" : "")
                            }
                            
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category == selectedCategory ? nil : category
                                }) {
                                    Label(category, systemImage: category == selectedCategory ? "checkmark" : "")
                                }
                            }
                        }
                        
                        // Expiring soon filter
                        Section {
                            Button(action: {
                                showExpiringSoon.toggle()
                            }) {
                                Label("即将过期", systemImage: showExpiringSoon ? "checkmark" : "")
                            }
                        }
                        
                        Divider()
                        
                        Button(action: {
                            showingAddItemSheet = true
                        }) {
                            Label("添加物品", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddItemSheet) {
                AddItemSheet(location: nil) { newItem in
                    modelContext.insert(newItem)
                }
            }
        }
    }
}

#Preview {
    ItemsView()
        .modelContainer(for: [Item.self, StorageLocation.self], inMemory: true)
}