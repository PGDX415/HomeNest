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
    
    @State private var showingAddPlaceSheet = false
    
    // Biometric authentication state
    @State private var showingBiometricAlert = false
    @State private var biometricError: String = ""
    
    var body: some View {
        List {
            ForEach(allPlaces, id: \.persistentModelID) { place in
                NavigationLink(destination: LocationsView(home: place)) {
                    HStack {
                        Image(systemName: place.getSafeIconName())
                            .foregroundColor(place.getIconColor())
                        
                        VStack(alignment: .leading) {
                            Text(place.name)
                                .font(.headline)
                            if let address = place.address {
                                Text(address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // 显示物品数量
                            let itemCount = place.totalItemCount()
                            if itemCount > 0 {
                                Text("\(itemCount) 个物品")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if place.isPrimary {
                            Text("主")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
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
    @State private var placeToDelete: Home?
    
    // Helper function to generate delete confirmation message
    private func deleteConfirmationMessage() -> Text {
        guard let place = placeToDelete else {
            return Text("确定要删除此场所吗？\n\n⚠️ 此操作将永久删除所有相关数据，无法恢复！")
        }
        
        let locationCount = place.locations.count
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