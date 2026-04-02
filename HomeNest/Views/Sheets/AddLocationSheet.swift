import SwiftUI
import SwiftData

// 预定义的位置图标选项
struct LocationIconOption: Identifiable {
    let id = UUID()
    let systemName: String
    let title: String
    
    init(_ systemName: String, _ title: String) {
        self.systemName = systemName
        self.title = title
    }
}

struct AddLocationSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let parentLocation: StorageLocation?
    let home: Home? // Added to support associating with a home
    let existingLocation: StorageLocation?  // Added to support editing existing locations
    let onSave: (StorageLocation) -> Void
    
    @State private var name = ""
    @State private var type = LocationType.room
    @State private var selectedIcon = "folder.fill" // Default icon
    @State private var selectedColorName = "primary" // Default color name
    @State private var isFavorite = false
    @State private var showingIconPicker = false
    @State private var showingColorPicker = false
    
    // 预定义的常用位置图标
    private let locationIcons = [
        LocationIconOption("folder.fill", "文件夹"),
        LocationIconOption("house.fill", "房间"),
        LocationIconOption("cabinet.fill", "柜子"),
        LocationIconOption("shelf.fill", "架子"),
        LocationIconOption("box.fill", "箱子"),
        LocationIconOption("archivebox.fill", "抽屉"),
        LocationIconOption("suitcase.fill", "行李箱"),
        LocationIconOption("cart.fill", "购物车"),
        LocationIconOption("briefcase.fill", "公文包"),
        LocationIconOption("lock.fill", "保险箱"),
        LocationIconOption("photo.fill", "相册"),
        LocationIconOption("tag.fill", "标签"),
        LocationIconOption("location.fill", "位置"),
        LocationIconOption("doc.fill", "文档")
    ]
    
    // 预定义的颜色选项（使用元组而不是 ColorOption 结构体）
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
    
    init(parentLocation: StorageLocation?, home: Home? = nil, existingLocation: StorageLocation? = nil, onSave: @escaping (StorageLocation) -> Void) {
        self.parentLocation = parentLocation
        self.home = home
        self.existingLocation = existingLocation
        self.onSave = onSave
        
        // Initialize state variables if editing an existing location
        if let existingLocation = existingLocation {
            _name = State(initialValue: existingLocation.name)
            _type = State(initialValue: existingLocation.type)
            _selectedIcon = State(initialValue: existingLocation.icon ?? "folder.fill")
            _selectedColorName = State(initialValue: existingLocation.iconColor ?? "primary")
            _isFavorite = State(initialValue: existingLocation.isFavorite)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("位置名称*", text: $name)
                    
                    Picker("类型", selection: $type) {
                        ForEach(LocationType.allCases, id: \.self) { locationType in
                            Text(locationType.rawValue).tag(locationType)
                        }
                    }
                    
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
                            if let currentIcon = existingLocation?.icon {
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
                
                Section("偏好设置") {
                    Toggle("收藏此位置", isOn: $isFavorite)
                        .foregroundColor(.orange)
                }
                
                if let parent = parentLocation {
                    Section("父位置") {
                        HStack {
                            if let parentIcon = parent.icon {
                                Image(systemName: parentIcon)
                            } else {
                                Image(systemName: "folder.fill")
                            }
                            Text(parent.name)
                            Spacer()
                            Text(parent.type.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let home = home {
                    Section("所属场所") {
                        HStack {
                            if let homeIcon = home.icon {
                                Image(systemName: homeIcon)
                            } else {
                                Image(systemName: "house.fill")
                            }
                            Text(home.name)
                            Spacer()
                            if home.isPrimary {
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
            }
            .navigationTitle(existingLocation == nil ? (parentLocation == nil ? "添加位置" : "添加子位置") : "编辑位置")
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
                        
                        if let existingLocation = existingLocation {
                            // Update existing location directly
                            existingLocation.name = name
                            existingLocation.type = type
                            existingLocation.icon = selectedIcon
                            existingLocation.iconColor = selectedColorName
                            existingLocation.isFavorite = isFavorite
                            // Remove the non-existent updatedAt field
                            
                            onSave(existingLocation)
                        } else {
                            // Create new location
                            let newLocation = StorageLocation(
                                name: name,
                                type: type,
                                parent: parentLocation,
                                home: home,
                                icon: selectedIcon,
                                iconColor: selectedColorName,
                                isFavorite: isFavorite
                            )
                            
                            onSave(newLocation)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                LocationIconPickerView(selectedIcon: $selectedIcon) {
                    showingIconPicker = false
                }
            }
            .sheet(isPresented: $showingColorPicker) {
                LocationColorPickerView(selectedColorName: $selectedColorName) {
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

// 位置图标选择器视图
struct LocationIconPickerView: View {
    @Binding var selectedIcon: String
    let onDismiss: () -> Void
    
    // 预定义的常用位置图标
    private let locationIcons = [
        LocationIconOption("folder.fill", "文件夹"),
        LocationIconOption("house.fill", "房间"),
        LocationIconOption("cabinet.fill", "柜子"),
        LocationIconOption("shelf.fill", "架子"),
        LocationIconOption("box.fill", "箱子"),
        LocationIconOption("archivebox.fill", "抽屉"),
        LocationIconOption("suitcase.fill", "行李箱"),
        LocationIconOption("cart.fill", "购物车"),
        LocationIconOption("briefcase.fill", "公文包"),
        LocationIconOption("lock.fill", "保险箱"),
        LocationIconOption("photo.fill", "相册"),
        LocationIconOption("tag.fill", "标签"),
        LocationIconOption("location.fill", "位置"),
        LocationIconOption("doc.fill", "文档")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 20) {
                    ForEach(locationIcons) { iconOption in
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

// 位置颜色选择器视图
struct LocationColorPickerView: View {
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
        AddLocationSheet(parentLocation: nil) { _ in }
    }
    .modelContainer(for: [Item.self, StorageLocation.self, Home.self], inMemory: true)
}