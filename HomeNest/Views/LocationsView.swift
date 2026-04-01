import SwiftUI
import SwiftData
import LocalAuthentication // Added for biometric authentication

struct LocationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allLocations: [StorageLocation]
    
    let home: Home? // Added to support filtering by home
    
    @State private var showingAddLocationSheet = false
    @State private var showingEditLocationSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var locationToDelete: StorageLocation?
    @State private var locationToEdit: StorageLocation?
    
    // Biometric authentication state
    @State private var showingBiometricAlert = false
    @State private var biometricError: String = ""
    
    // Get locations filtered by home and sorted by name
    var filteredLocations: [StorageLocation] {
        if let home = home {
            return allLocations.filter { $0.home?.persistentModelID == home.persistentModelID }
        } else {
            // For backward compatibility or when no home is selected
            return allLocations.filter { $0.home == nil }
        }
    }
    
    var sortedLocations: [StorageLocation] {
        filteredLocations.sorted { $0.name < $1.name }
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
    
    // Helper function to generate delete confirmation message
    private func deleteConfirmationMessage(for location: StorageLocation) -> String {
        let itemCount = location.items.count
        let subLocationCount = location.subLocations.count
        var message = "确定要删除位置\"\(location.name)\"吗？"
        
        if itemCount > 0 || subLocationCount > 0 {
            message += "\n\n此操作将同时删除："
            if itemCount > 0 {
                message += "\n• \(itemCount) 个物品"
            }
            if subLocationCount > 0 {
                message += "\n• \(subLocationCount) 个子位置"
            }
            message += "\n\n此操作无法撤销。"
        }
        
        return message
    }
    
    var body: some View {
        List {
            ForEach(sortedLocations, id: \.persistentModelID) { location in
                NavigationLink(destination: LocationDetailView(location: location)) {
                    HStack {
                        Image(systemName: location.getSafeIconName())
                            .foregroundColor(location.getIconColor())
                        
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
                    // Edit action
                    Button(role: .none) {
                        locationToEdit = location
                        showingEditLocationSheet = true
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    .tint(.blue)
                    
                    // Delete action
                    Button(role: .destructive) {
                        locationToDelete = location
                        showingDeleteConfirmation = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    // Favorite toggle action
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
        .navigationTitle(home?.name ?? "位置")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddLocationSheet = true
                }) {
                    Label("添加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddLocationSheet) {
            AddLocationSheet(parentLocation: nil, home: home) { newLocation in
                modelContext.insert(newLocation)
            }
        }
        .sheet(isPresented: $showingEditLocationSheet) {
            if let location = locationToEdit {
                AddLocationSheet(parentLocation: location.parent, home: location.home, existingLocation: location) { _ in
                    // No need to manually save - the sheet updates the existing location directly
                }
            }
        }
        .alert("确认删除位置", isPresented: $showingDeleteConfirmation) {
            Button("删除", role: .destructive) {
                if let location = locationToDelete {
                    // Request biometric authentication before deletion
                    requestBiometricAuthentication(for: location)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            if let location = locationToDelete {
                Text(deleteConfirmationMessage(for: location))
            } else {
                Text("确定要删除此位置吗？此操作无法撤销。")
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
    
    private func toggleFavorite(for location: StorageLocation) {
        withAnimation {
            location.isFavorite.toggle()
        }
    }
    
    private func confirmDeleteLocations(offsets: IndexSet) {
        // Only handle single deletion for now (swipe-to-delete typically deletes one item)
        guard let index = offsets.first, index < sortedLocations.count else { return }
        let location = sortedLocations[index]
        locationToDelete = location
        showingDeleteConfirmation = true
    }
    
    private func deleteLocation(_ location: StorageLocation) {
        withAnimation {
            modelContext.delete(location)
        }
        locationToDelete = nil
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
                        showingDeleteConfirmation = false
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
    LocationsView(home: nil)
        .modelContainer(for: [Item.self, StorageLocation.self, Home.self], inMemory: true)
}