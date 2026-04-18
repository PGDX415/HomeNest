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
    @State private var isBatchMode = false
    @State private var selectedItems: Set<PersistentIdentifier> = []
    
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
    @State private var itemsToDelete: [Item] = [] // For batch deletion
    
    init() {
        // Default query for all items sorted by name
        _items = Query(sort: \Item.name)
        _homes = Query(sort: \Home.name) // Added query for homes
    }
    
    // Get valid home IDs to ensure we only reference existing homes
    private var validHomeIDs: Set<PersistentIdentifier> {
        Set(homes.map { $0.persistentModelID })
    }
    
    // Helper function to safely get home name for an item
    private func getSafeHomeName(for item: Item) -> String? {
        // Use direct home reference if available and valid
        if let home = item.home,
           validHomeIDs.contains(home.persistentModelID) {
            return home.name
        }
        
        // Fallback to location-based lookup for backward compatibility
        guard let location = item.location else {
            return nil
        }
        
        // Check location's home
        if let home = location.home,
           validHomeIDs.contains(home.persistentModelID) {
            return home.name
        }
        
        // Recursively check parent locations, but only access properties safely
        var currentLocation: StorageLocation? = location.parent
        var depth = 0
        
        while let current = currentLocation, depth < 10 {
            // Only access home if it exists in our valid set
            if let home = current.home,
               validHomeIDs.contains(home.persistentModelID) {
                return home.name
            }
            currentLocation = current.parent
            depth += 1
        }
        
        return nil
    }
    
    // Filtered items based on search and filters
    var filteredItems: [Item] {
        var filtered = items
        
        // First, filter out items that reference invalid homes through any path
        filtered = filtered.filter { item in
            // If item has no location, it's unclassified (valid)
            guard let location = item.location else {
                return true
            }
            
            // Check if this item can be associated with a valid home
            let homeName = getSafeHomeName(for: item)
            return homeName != nil || location.home == nil
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
                
                // For home matching, use safe lookup
                var matchesHome = false
                if let homeName = getSafeHomeName(for: item) {
                    matchesHome = homeName.localizedCaseInsensitiveContains(searchText)
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
        
        // Group filtered items by their home name using safe lookup
        for item in filteredItems {
            let homeName = getSafeHomeName(for: item)
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
                            HStack {
                                if isBatchMode {
                                    // Batch mode: show selection checkbox
                                    Button(action: {
                                        toggleSelection(for: item)
                                    }) {
                                        Image(systemName: selectedItems.contains(item.persistentModelID) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedItems.contains(item.persistentModelID) ? .blue : .secondary)
                                            .font(.title2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    // Normal mode: show photo or placeholder
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
                                }
                                
                                if isBatchMode {
                                    // Batch mode: use Button instead of NavigationLink
                                    Button(action: {
                                        toggleSelection(for: item)
                                    }) {
                                        itemContent(for: item)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    // Normal mode: use NavigationLink
                                    NavigationLink(destination: ItemDetailView(item: item)) {
                                        itemContent(for: item)
                                    }
                                }
                                
                                if !isBatchMode {
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
            .navigationTitle(isBatchMode ? "选择物品 (\(selectedItems.count))" : "物品")
            .searchable(text: $searchText, prompt: "搜索物品、位置或标签")
            .toolbar {
                // Batch mode toolbar items
                if isBatchMode {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("取消") {
                            exitBatchMode()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: {
                                selectAllVisibleItems()
                            }) {
                                Label("全选", systemImage: "checkmark.circle")
                            }
                            
                            Button(action: {
                                deselectAllItems()
                            }) {
                                Label("取消全选", systemImage: "circle")
                            }
                            
                            Divider()
                            
                            if !selectedItems.isEmpty {
                                Button(role: .destructive) {
                                    prepareBatchDeletion()
                                } label: {
                                    Label("删除选中", systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .disabled(selectedItems.isEmpty)
                    }
                } else {
                    // Normal mode toolbar items
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button(action: {
                                enterBatchMode()
                            }) {
                                Image(systemName: "square.and.pencil")
                                    .accessibilityLabel("批量操作")
                            }
                            .disabled(filteredItems.isEmpty)
                            
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
                    // Clear batch deletion state if cancelled
                    itemsToDelete = []
                }
            } message: {
                Text(biometricError.isEmpty ? "请使用 Face ID 或 Touch ID 验证身份以继续删除操作。" : biometricError)
            }
        }
    }
    
    // Helper function to create item content view
    private func itemContent(for item: Item) -> some View {
        HStack {
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
            
            // Removed duplicate quantity display - it's already shown in the main HStack
        }
    }
    
    // Batch mode functions
    private func enterBatchMode() {
        isBatchMode = true
        selectedItems.removeAll()
    }
    
    private func exitBatchMode() {
        isBatchMode = false
        selectedItems.removeAll()
        itemsToDelete = []
    }
    
    private func toggleSelection(for item: Item) {
        let id = item.persistentModelID
        if selectedItems.contains(id) {
            selectedItems.remove(id)
        } else {
            selectedItems.insert(id)
        }
    }
    
    private func selectAllVisibleItems() {
        selectedItems = Set(filteredItems.map { $0.persistentModelID })
    }
    
    private func deselectAllItems() {
        selectedItems.removeAll()
    }
    
    private func prepareBatchDeletion() {
        // Get the actual Item objects for deletion
        itemsToDelete = filteredItems.filter { selectedItems.contains($0.persistentModelID) }
        if !itemsToDelete.isEmpty {
            requestBiometricAuthenticationForBatch()
        }
    }
    
    private func requestBiometricAuthenticationForBatch() {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "验证身份以删除 \(itemsToDelete.count) 个选中的物品"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        // Authentication successful, proceed with batch deletion
                        deleteSelectedItems()
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
    
    private func deleteSelectedItems() {
        withAnimation {
            for item in itemsToDelete {
                modelContext.delete(item)
            }
        }
        exitBatchMode()
    }
    
    // Existing biometric functions (keeping them for single item deletion)
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