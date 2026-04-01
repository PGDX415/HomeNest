import SwiftUI
import SwiftData

struct AddLocationSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let parentLocation: StorageLocation?
    let home: Home? // Added to support associating with a home
    let existingLocation: StorageLocation?  // Added to support editing existing locations
    let onSave: (StorageLocation) -> Void
    
    @State private var name = ""
    @State private var type = LocationType.room
    @State private var icon = ""
    @State private var isFavorite = false
    
    init(parentLocation: StorageLocation?, home: Home? = nil, existingLocation: StorageLocation? = nil, onSave: @escaping (StorageLocation) -> Void) {
        self.parentLocation = parentLocation
        self.home = home
        self.existingLocation = existingLocation
        self.onSave = onSave
        
        // Initialize state variables if editing an existing location
        if let existingLocation = existingLocation {
            _name = State(initialValue: existingLocation.name)
            _type = State(initialValue: existingLocation.type)
            _icon = State(initialValue: existingLocation.icon ?? "")
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
                    
                    TextField("图标 (SF Symbols)", text: $icon)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
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
                    Section("所属家庭") {
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
                            existingLocation.icon = icon.isEmpty ? nil : icon
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
                                icon: icon.isEmpty ? nil : icon,
                                isFavorite: isFavorite
                            )
                            
                            onSave(newLocation)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
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