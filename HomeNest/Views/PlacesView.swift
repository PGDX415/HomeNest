//
//  PlacesView.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/1.
//

import SwiftUI
import SwiftData
import LocalAuthentication // Added for biometric authentication

struct PlacesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allPlaces: [Home]
    @Query private var allItems: [Item]
    @Query private var allLocations: [StorageLocation]
    
    @State private var showingAddPlaceSheet = false
    
    // Biometric authentication state
    @State private var showingBiometricAlert = false
    @State private var biometricError: String = ""
    
    var body: some View {
        List {
            ForEach(allPlaces, id: \.persistentModelID) { place in
                NavigationLink(destination: LocationsView(home: place)) {
                    HStack {
                        // Use safe icon handling method to avoid empty string warnings
                        Image(systemName: place.getSafeIconName())
                            .foregroundColor(place.getIconColor())
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(place.getIconColor().opacity(0.1))
                            )
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(place.name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                if place.isPrimary {
                                    Text("主")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.blue.opacity(0.15))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }
                            }
                            
                            if let address = place.address {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text(address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            
                            // 统计信息行 - 使用独立查询确保准确性
                            HStack(spacing: 12) {
                                // 简化逻辑：只显示物品总数，因为这是最关键的指标
                                let itemCount = getItemCount(for: place)
                                
                                if itemCount > 0 {
                                    HStack(spacing: 4) {
                                        Image(systemName: "list.bullet.rectangle")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text("\(itemCount) 个物品")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    // 检查是否有位置（即使没有物品）
                                    let locationCount = getLocationCount(for: place)
                                    if locationCount > 0 {
                                        HStack(spacing: 4) {
                                            Image(systemName: "folder.fill")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Text("\(locationCount) 个位置")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    } else {
                                        Text("暂无数据")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Edit button
                        Button(action: {
                            placeToEdit = place
                            showingEditPlaceSheet = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.vertical, 8)
                }
            }
            .onDelete(perform: deletePlaces)
        }
        .navigationTitle("场所")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddPlaceSheet = true
                }) {
                    Label("添加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPlaceSheet) {
            AddPlaceSheet { newPlace in
                // Set as primary if this is the first place
                if allPlaces.isEmpty {
                    newPlace.isPrimary = true
                }
                modelContext.insert(newPlace)
            }
        }
        .sheet(isPresented: $showingEditPlaceSheet) {
            if let placeToEdit = placeToEdit {
                AddPlaceSheet(existingPlace: placeToEdit) { updatedPlace in
                    // The sheet updates the existing place directly, no need to manually update properties
                    // Just dismiss the sheet
                }
            }
        }
        .alert("⚠️ 警告：永久删除场所", isPresented: $showingDeleteConfirmation) {
            Button("永久删除", role: .destructive) {
                if let place = placeToDelete {
                    // Request biometric authentication before deletion
                    requestBiometricAuthentication(for: place)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            deleteConfirmationMessage()
        }
        .alert("🔒 安全验证", isPresented: $showingBiometricAlert) {
            Button("取消", role: .cancel) {
                showingBiometricAlert = false
            }
        } message: {
            Text(biometricError.isEmpty ? "请使用 Face ID 或 Touch ID 验证身份以继续删除操作。" : biometricError)
        }
    }
    
    @State private var showingDeleteConfirmation = false
    @State private var showingEditPlaceSheet = false
    @State private var placeToDelete: Home?
    @State private var placeToEdit: Home?
    
    // Helper function to generate delete confirmation message
    private func deleteConfirmationMessage() -> Text {
        guard let place = placeToDelete else {
            return Text("确定要删除此场所吗？\n\n⚠️ 此操作将永久删除所有相关数据，无法恢复！")
        }
        
        let locationCount = place.locations?.count ?? 0
        let totalItemCount = place.totalItemCount()
        var message = "⚠️ **严重警告**\n\n"
        message += "您即将永久删除场所\"\(place.name)\"及其所有数据！\n\n"
        
        if locationCount > 0 || totalItemCount > 0 {
            message += "**将被永久删除的数据包括：**\n"
            if locationCount > 0 {
                message += "• \(locationCount) 个位置\n"
            }
            if totalItemCount > 0 {
                message += "• \(totalItemCount) 个物品\n"
            }
            message += "\n"
        }
        
        message += "**重要提醒：**\n"
        message += "• 此操作**无法撤销**\n"
        message += "• 所有数据将**永久丢失**\n"
        message += "• 请确保您已备份重要数据\n\n"
        message += "确定要继续吗？"
        
        return Text(message)
    }
    
    private func deletePlaces(offsets: IndexSet) {
        guard let index = offsets.first, index < allPlaces.count else { return }
        let place = allPlaces[index]
        placeToDelete = place
        showingDeleteConfirmation = true
    }
    
    private func deletePlace(_ place: Home) {
        withAnimation {
            modelContext.delete(place)
        }
        placeToDelete = nil
    }
    
    // Helper function to get accurate item count for a place using independent query
    private func getItemCount(for place: Home) -> Int {
        // Count all items that belong to locations associated with this place
        var totalCount = 0
        
        for location in allLocations {
            // Check if this location belongs to the place (directly or through parent chain)
            if isLocationInPlace(location, place: place) {
                totalCount += location.items?.count ?? 0
                
                // Add items from sub-locations
                totalCount += getItemsInSubLocations(of: location)
            }
        }
        
        return totalCount
    }
    
    // Helper function to get items in all sub-locations recursively
    private func getItemsInSubLocations(of location: StorageLocation) -> Int {
        var count = 0
        
        for subLocation in allLocations {
            if subLocation.parent?.persistentModelID == location.persistentModelID {
                count += subLocation.items?.count ?? 0
                count += getItemsInSubLocations(of: subLocation)
            }
        }
        
        return count
    }
    
    // Helper function to check if a location belongs to a specific place
    private func isLocationInPlace(_ location: StorageLocation, place: Home) -> Bool {
        // Direct association
        if let locationHome = location.home,
           locationHome.persistentModelID == place.persistentModelID {
            return true
        }
        
        // Check parent chain for home association
        var currentLocation: StorageLocation? = location.parent
        var depth = 0
        
        while let current = currentLocation, depth < 10 {
            if let parentHome = current.home,
               parentHome.persistentModelID == place.persistentModelID {
                return true
            }
            currentLocation = current.parent
            depth += 1
        }
        
        return false
    }
    
    // Helper function to get accurate location count for a place
    private func getLocationCount(for place: Home) -> Int {
        var count = 0
        for location in allLocations {
            if isLocationInPlace(location, place: place) {
                count += 1
            }
        }
        return count
    }
    
    // Biometric authentication function
    private func requestBiometricAuthentication(for place: Home) {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "验证身份以删除场所\"\(place.name)\"及其所有数据"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        // Authentication successful, proceed with deletion
                        deletePlace(place)
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
    PlacesView()
        .modelContainer(for: [Item.self, StorageLocation.self, Home.self], inMemory: true)
}
