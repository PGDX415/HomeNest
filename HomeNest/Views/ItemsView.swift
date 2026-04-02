import SwiftUI
import SwiftData
import LocalAuthentication // Added for biometric authentication

struct ItemsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @Query private var homes: [Home] // Added to get all homes for grouping
    
    @State private var showingAddItemSheet = false
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var showExpiringSoon = false
    
    // Predefined categories matching AddItemSheet
    private let presetCategories = [
        "家电电器", "厨房用品", "衣物鞋帽", "书籍文具",
        "食品饮品", "清洁用品", "医药保健", "装饰摆件",
        "工具设备", "其他杂物"
    ]
    
    // Biometric authentication state
    @State private var showingBiometricAlert = false
    @State private var biometricError: String = ""
    @State private var itemToDelete: Item?
    
    init() {
        // Default query for all items sorted by name
        _items = Query(sort: \Item.name)
        _homes = Query(sort: \Home.name) // Added query for homes
    }
    
    // Helper function to safely get home name for an item
    private func getHomeName(for item: Item) -> String? {
        // First check if location exists and is valid
        guard let location = item.location else {
            return nil
        }
        
        // Check if home exists and is valid  
        guard let home = location.home else {
            return nil
        }
        
        // Try to access home name - if this crashes, the home is invalid
        // But we can't catch this, so we rely on the fact that if home is in @Query,
        // it should be valid
        return home.name
    }
    
    // Get valid home IDs from the homes query
    private var validHomeIDs: Set<PersistentIdentifier> {
        Set(homes.map { $0.persistentModelID })
    }
    
    // Filtered items based on search and filters
    var filteredItems: [Item] {
        var filtered = items
        
        // Filter out items that reference invalid homes
        filtered = filtered.filter { item in
            if let location = item.location,
               let home = location.home {
                // Only include if home is still in our valid homes list
                return validHomeIDs.contains(home.persistentModelID)
            }
            // Items without home or location are always valid
            return true
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                let matchesName = item.name.localizedCaseInsensitiveContains(searchText)
                let matchesCategory = item.category?.localizedCaseInsensitiveContains(searchText) ?? false
                let matchesTags = item.tags.contains { tag in
                    tag.localizedCaseInsensitiveContains(searchText)
                }
                let matchesLocation = item.location?.name.localizedCaseInsensitiveContains(searchText) ?? false
                
                // For home matching, only match if home is valid
                var matchesHome = false
                if let location = item.location,
                   let home = location.home,
                   validHomeIDs.contains(home.persistentModelID) {
                    matchesHome = home.name.localizedCaseInsensitiveContains(searchText)
                }
                
                return matchesName || matchesCategory || matchesTags || matchesLocation || matchesHome
            }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { item in
                return item.category == category
            }
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
    
    // Group items by home using safe approach
    var itemsByHome: [(homeName: String?, items: [Item])] {
        var grouped: [String?: [Item]] = [:]
        
        // Group filtered items by their home name (not home object)
        for item in filteredItems {
            let homeName: String?
            
            if let location = item.location,
               let home = location.home,
               validHomeIDs.contains(home.persistentModelID) {
                homeName = home.name
            } else {
                homeName = nil
            }
            
            grouped[homeName, default: []].append(item)
        }
        
        // Convert to array and sort - nil homes (unclassified) come first
        var result = grouped.map { (homeName: $0.key, items: $0.value) }
        result.sort { (group1, group2) in
            // Items without home come first
            if group1.homeName == nil && group2.homeName != nil {
                return true
            }
            if group1.homeName != nil && group2.homeName == nil {
                return false
            }
            // Both have homes, sort by name
            if let name1 = group1.homeName, let name2 = group2.homeName {
                return name1 < name2
            }
            // Both are nil
            return false
        }
        
        return result
    }
    
    // Get unique categories for filtering
    var categories: [String] {
        Array(Set(filteredItems.compactMap { $0.category }))
            .sorted()
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(itemsByHome.indices, id: \.self) { index in
                    let homeGroup = itemsByHome[index]
                    Section(homeGroup.homeName ?? "未分类") {
                        ForEach(homeGroup.items, id: \.persistentModelID) { item in
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    itemToDelete = item
                                    requestBiometricAuthentication(for: item)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
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
            .alert("🔒 安全验证", isPresented: $showingBiometricAlert) {
                Button("取消", role: .cancel) {
                    showingBiometricAlert = false
                }
            } message: {
                Text(biometricError.isEmpty ? "请使用 Face ID 或 Touch ID 验证身份以继续删除操作。" : biometricError)
            }
        }
    }
    
    // Biometric authentication function
    private func requestBiometricAuthentication(for item: Item) {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "验证身份以删除物品\"\(item.name)\""
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        // Authentication successful, proceed with deletion
                        deleteItem(item)
                    } else {
                        // Authentication failed
                        if let authError = authenticationError {
                            handleBiometricError(authError)
                        } else {
                            biometricError = "身份验证失败，请重试。"
                            showingBiometricAlert = true
                        }
                    }
                }
            }
        } else {
            // Biometric authentication not available
            biometricError = "设备不支持 Face ID 或 Touch ID。请在设置中启用生物识别功能。"
            showingBiometricAlert = true
        }
    }
    
    private func deleteItem(_ item: Item) {
        withAnimation {
            modelContext.delete(item)
        }
        itemToDelete = nil
    }
    
    private func handleBiometricError(_ error: Error) {
        let laError = error as? LAError
        
        switch laError?.code {
        case .userCancel:
            biometricError = "用户取消了身份验证。"
        case .userFallback:
            biometricError = "用户选择了备用验证方式。"
        case .systemCancel:
            biometricError = "系统取消了身份验证。"
        case .touchIDLockout:
            biometricError = "Touch ID 已被锁定，请使用设备密码解锁。"
        case .touchIDNotAvailable:
            biometricError = "Touch ID 不可用。"
        case .touchIDNotEnrolled:
            biometricError = "未注册 Touch ID，请在设置中添加指纹。"
        case .biometryNotEnrolled:
            biometricError = "未注册生物识别信息，请在设置中进行设置。"
        case .biometryNotAvailable:
            biometricError = "生物识别功能不可用。"
        case .biometryLockout:
            biometricError = "生物识别已被锁定，请使用设备密码解锁。"
        default:
            biometricError = "身份验证失败，请重试。"
        }
        
        showingBiometricAlert = true
    }
}

#Preview {
    ItemsView()
        .modelContainer(for: [Item.self, StorageLocation.self, Home.self], inMemory: true)
}