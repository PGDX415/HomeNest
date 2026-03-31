import SwiftUI
import SwiftData

struct AddLocationSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let parentLocation: StorageLocation?
    let onSave: (StorageLocation) -> Void
    
    @State private var name = ""
    @State private var type = LocationType.room
    @State private var icon = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("位置名称", text: $name)
                    
                    Picker("类型", selection: $type) {
                        ForEach(LocationType.allCases, id: \.self) { locationType in
                            Text(locationType.rawValue).tag(locationType)
                        }
                    }
                    
                    TextField("图标 (SF Symbols)", text: $icon)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
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
            }
            .navigationTitle(parentLocation == nil ? "添加位置" : "添加子位置")
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
                        
                        let newLocation = StorageLocation(
                            name: name,
                            type: type,
                            parent: parentLocation,
                            icon: icon.isEmpty ? nil : icon
                        )
                        
                        onSave(newLocation)
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
    .modelContainer(for: [Item.self, StorageLocation.self], inMemory: true)
}