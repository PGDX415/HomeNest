//
//  AddPlaceSheet.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/1.
//

import SwiftUI
import SwiftData

// 预定义的场所图标选项
struct PlaceIconOption: Identifiable {
    let id = UUID()
    let systemName: String
    let title: String
    
    init(_ systemName: String, _ title: String) {
        self.systemName = systemName
        self.title = title
    }
}

struct AddPlaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let existingPlace: Home?  // Added to support editing existing places
    let onSave: (Home) -> Void
    
    @State private var name = ""
    @State private var address = ""
    @State private var selectedIcon = "house.fill" // Default icon
    @State private var selectedColorName = "primary" // Default color name
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false
    
    // 预定义的常用场所图标
    private let placeIcons = [
        PlaceIconOption("house.fill", "住宅"),
        PlaceIconOption("building.2.fill", "公寓"),
        PlaceIconOption("person.wave.2.fill", "度假屋"),
        PlaceIconOption("briefcase.fill", "办公室"),
        PlaceIconOption("archivebox.fill", "仓库"), // Fixed: replaced warehouse.fill with archivebox.fill
        PlaceIconOption("cart.fill", "商铺"),
        PlaceIconOption("car.fill", "车库"),
        PlaceIconOption("archivebox.fill", "储物间"),
        PlaceIconOption("lock.fill", "保险箱"),
        PlaceIconOption("suitcase.fill", "旅行箱"),
        PlaceIconOption("folder.fill", "文件夹"),
        PlaceIconOption("location.fill", "位置"),
        PlaceIconOption("tag.fill", "标签"),
        PlaceIconOption("photo.fill", "照片")
    ]
    
    init(existingPlace: Home? = nil, onSave: @escaping (Home) -> Void) {
        self.existingPlace = existingPlace
        self.onSave = onSave
        
        // Initialize state variables if editing an existing place
        if let existingPlace = existingPlace {
            _name = State(initialValue: existingPlace.name)
            _address = State(initialValue: existingPlace.address ?? "")
            _selectedIcon = State(initialValue: existingPlace.icon ?? "house.fill")
            _selectedColorName = State(initialValue: existingPlace.iconColor ?? "primary")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("场所名称*", text: $name)
                    
                    TextField("地址", text: $address)
                    
                    // 图标选择器替代文本输入
                    Button(action: {
                        showingIconPicker = true
                    }) {
                        HStack {
                            Image(systemName: selectedIcon)
                                .font(.title2)
                                .foregroundColor(getColorFromName(selectedColorName))
                            Text("选择图标")
                                .foregroundColor(.primary)
                            Spacer()
                            if let currentIcon = existingPlace?.icon {
                                Image(systemName: currentIcon)
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // 颜色选择器
                    Button(action: {
                        showingColorPicker = true
                    }) {
                        HStack {
                            Text("图标颜色")
                                .foregroundColor(.primary)
                            Spacer()
                            // 显示当前颜色预览
                            RoundedRectangle(cornerRadius: 8)
                                .fill(getColorFromName(selectedColorName))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .navigationTitle(existingPlace == nil ? "添加场所" : "编辑场所")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        guard !name.isEmpty else { return }
                        
                        if let existingPlace = existingPlace {
                            // Update existing place directly
                            existingPlace.name = name
                            existingPlace.address = address.isEmpty ? nil : address
                            existingPlace.icon = selectedIcon
                            existingPlace.iconColor = selectedColorName
                            existingPlace.updatedAt = Date()
                        } else {
                            // Create new place
                            let newPlace = Home(
                                name: name,
                                address: address.isEmpty ? nil : address,
                                icon: selectedIcon,
                                iconColor: selectedColorName
                            )
                            
                            onSave(newPlace)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView(selectedIcon: $selectedIcon) {
                    showingIconPicker = false
                }
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerView(selectedColorName: $selectedColorName) {
                    showingColorPicker = false
                }
            }
        }
    }
    
    // Helper function to convert color name to Color
    func getColorFromName(_ colorName: String) -> Color {
        switch colorName {
        case "blue":
            return .blue
        case "green":
            return .green
        case "orange":
            return .orange
        case "red":
            return .red
        case "purple":
            return .purple
        case "indigo":
            return .indigo
        case "teal":
            return .teal
        case "gray":
            return .gray
        default:
            return .primary
        }
    }
}

// 图标选择器视图
struct IconPickerView: View {
    @Binding var selectedIcon: String
    let onDismiss: () -> Void
    
    // 预定义的常用场所图标
    private let placeIcons = [
        PlaceIconOption("house.fill", "住宅"),
        PlaceIconOption("building.2.fill", "公寓"),
        PlaceIconOption("person.wave.2.fill", "度假屋"),
        PlaceIconOption("briefcase.fill", "办公室"),
        PlaceIconOption("archivebox.fill", "仓库"), // Fixed: replaced warehouse.fill with archivebox.fill
        PlaceIconOption("cart.fill", "商铺"),
        PlaceIconOption("car.fill", "车库"),
        PlaceIconOption("archivebox.fill", "储物间"),
        PlaceIconOption("lock.fill", "保险箱"),
        PlaceIconOption("suitcase.fill", "旅行箱"),
        PlaceIconOption("folder.fill", "文件夹"),
        PlaceIconOption("location.fill", "位置"),
        PlaceIconOption("tag.fill", "标签"),
        PlaceIconOption("photo.fill", "照片")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
                    ForEach(placeIcons) { iconOption in
                        VStack(spacing: 8) {
                            Button(action: {
                                selectedIcon = iconOption.systemName
                                onDismiss()
                            }) {
                                Image(systemName: iconOption.systemName)
                                    .font(.largeTitle)
                                    .foregroundColor(.primary)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedIcon == iconOption.systemName ? Color.blue.opacity(0.1) : Color.clear)
                                            .stroke(selectedIcon == iconOption.systemName ? Color.blue : Color.gray.opacity(0.3), lineWidth: selectedIcon == iconOption.systemName ? 2 : 1)
                                    )
                            }
                            
                            Text(iconOption.title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("选择图标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// 颜色选择器视图
struct ColorPickerView: View {
    @Binding var selectedColorName: String
    let onDismiss: () -> Void
    
    // 预定义的颜色选项
    private let colorOptions = [
        ("primary", Color.primary, "默认"),
        ("blue", Color.blue, "蓝色"),
        ("green", Color.green, "绿色"),
        ("orange", Color.orange, "橙色"),
        ("red", Color.red, "红色"),
        ("purple", Color.purple, "紫色"),
        ("indigo", Color.indigo, "靛蓝"),
        ("teal", Color.teal, "青色"),
        ("gray", Color.gray, "灰色")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
                    ForEach(colorOptions, id: \.0) { colorName, color, displayName in
                        VStack(spacing: 8) {
                            Button(action: {
                                selectedColorName = colorName
                                onDismiss()
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(color)
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedColorName == colorName ? Color.black : Color.gray.opacity(0.3), lineWidth: selectedColorName == colorName ? 2 : 1)
                                        )
                                    
                                    if selectedColorName == colorName {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                    }
                                }
                            }
                            
                            Text(displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("选择颜色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddPlaceSheet { _ in }
    }
    .modelContainer(for: [Item.self, StorageLocation.self, Home.self], inMemory: true)
}