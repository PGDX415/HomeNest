import SwiftUI
import SwiftData
import LocalAuthentication

struct GroupedLocationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allLocations: [StorageLocation]
    @Query private var allHomes: [Home]
    
    @State private var showingAddLocationSheet = false
    @State private var searchText = ""
    
    // Biometric authentication state
    @State private var showingBiometricAlert = false
    @State private var biometricError: String = ""
    @State private var locationToDelete: StorageLocation?
    
    // Get valid home IDs to ensure we only reference existing homes
    private var validHomeIDs: Set<PersistentIdentifier> {
        Set(allHomes.map { $0.persistentModelID })
    }
    
    // Helper function to safely get home name for a location
    private func getSafeHomeName(for location: StorageLocation) -> String? {
        // Use direct home reference if available and valid
        if let home = location.home,
           validHomeIDs.contains(home.persistentModelID) {
            return home.name
        }
        
        // Fallback to location-based lookup for backward compatibility
        guard let parent = location.parent else {
            return nil
        }
        
        // Check parent's home
        if let home = parent.home,
           validHomeIDs.contains(home.persistentModelID) {
            return home.name
        }
        
        // Recursively check parent locations, but only access properties safely
        var currentLocation: StorageLocation? = parent.parent
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
    
    // Filtered locations based on search
    var filteredLocations: [StorageLocation] {
        var filtered = allLocations
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { location in
                let matchesName = location.name.localizedCaseInsensitiveContains(searchText)
                let matchesType = location.type.rawValue.localizedCaseInsensitiveContains(searchText)
                
                // For home matching, use safe lookup
                var matchesHome = false
                if let homeName = getSafeHomeName(for: location) {
                    matchesHome = homeName.localizedCaseInsensitiveContains(searchText)
                }
                
                // For parent path matching
                var matchesParentPath = false
                let parentPath = locationPath(for: location)
                if parentPath.localizedCaseInsensitiveContains(searchText) {
                    matchesParentPath = true
                }
                
                return matchesName || matchesType || matchesHome || matchesParentPath
            }
        }
        
        return filtered
    }
    
    // Group locations by home using safe approach
    var locationsByHome: [(homeName: String?, locations: [StorageLocation])] {
        var grouped: [String?: [StorageLocation]] = [:]
        
        // Group filtered locations by their home name using safe lookup
        for location in filteredLocations {
            let homeName = getSafeHomeName(for: location)
            grouped[homeName, default: []].append(location)
        }
        
        // Convert to array and sort - nil homes (unclassified) come first
        var result = grouped.map { (homeName: $0.key, locations: $0.value) }
        result.sort { (group1, group2) in
            // Locations without home come first
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
    
    // Helper function to get full location path - with nil safety
    func locationPath(for location: StorageLocation) -> String {
        var pathComponents: [String] = [location.name]
        var currentLocation: StorageLocation? = location.parent
        
        // Limit depth to prevent infinite loops (max 10 levels)
        var depth = 0
        while let current = currentLocation, depth < 10 {
            pathComponents.insert(current.name, at: 0)
            currentLocation = current.parent
            depth += 1
        }
        
        return pathComponents.joined(separator: " > ")
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(locationsByHome.indices, id: \.self) { index in
                    let homeGroup = locationsByHome[index]
                    Section(homeGroup.homeName ?? "未分类") {
                        ForEach(homeGroup.locations ?? [], id: \.persistentModelID) { location in
                            NavigationLink(destination: LocationDetailView(location: location)) {
                                HStack {
                                    // Safe icon handling - ensure non-empty valid SF Symbol with custom color
                                    if let icon = location.icon, !icon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Image(systemName: icon.trimmingCharacters(in: .whitespacesAndNewlines))
                                            .foregroundColor(location.getIconColor())
                                    } else {
                                        Image(systemName: "folder.fill")
                                            .foregroundColor(location.getIconColor())
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(location.name)
                                            .font(.headline)
                                        Text(locationPath(for: location))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                        
                                        // 显示物品数量（包括子位置的物品）
                                        let totalCount = location.totalItemCount()
                                        if totalCount > 0 {
                                            Text("\(totalCount) 个物品")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if location.isFavorite {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                    }
                                    
                                    Text(location.type.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    locationToDelete = location
                                    requestBiometricAuthentication(for: location)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button(role: .none) {
                                    toggleFavorite(for: location)
                                } label: {
                                    if location.isFavorite {
                                        Label("取消收藏", systemImage: "star.slash")
                                    } else {
                                        Label("收藏", systemImage: "star")
                                    }
                                }
                                .tint(location.isFavorite ? .gray : .orange)
                            }
                        }
                    }
                }
            }
            .navigationTitle("所有位置")
            .searchable(text: $searchText, prompt: "搜索位置、场所或类型")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddLocationSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddLocationSheet) {
                AddLocationSheet(parentLocation: nil) { newLocation in
                    modelContext.insert(newLocation)
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
    
    private func toggleFavorite(for location: StorageLocation) {
        withAnimation {
            location.isFavorite.toggle()
        }
    }
    
    // Biometric authentication function
    private func requestBiometricAuthentication(for location: StorageLocation) {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "验证身份以删除位置\"\(location.name)\"及其所有数据"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        // Authentication successful, proceed with deletion
                        deleteLocation(location)
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
    
    private func deleteLocation(_ location: StorageLocation) {
        withAnimation {
            modelContext.delete(location)
        }
        locationToDelete = nil
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
    GroupedLocationsView()
        .modelContainer(for: [Item.self, StorageLocation.self, Home.self], inMemory: true)
}