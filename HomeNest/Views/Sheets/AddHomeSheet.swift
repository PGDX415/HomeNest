//
//  AddHomeSheet.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/1.
//

import SwiftUI
import SwiftData

struct AddHomeSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let existingHome: Home?  // Added to support editing existing homes
    let onSave: (Home) -> Void
    
    @State private var name = ""
    @State private var address = ""
    @State private var icon = ""
    
    init(existingHome: Home? = nil, onSave: @escaping (Home) -> Void) {
        self.existingHome = existingHome
        self.onSave = onSave
        
        // Initialize state variables if editing an existing home
        if let existingHome = existingHome {
            _name = State(initialValue: existingHome.name)
            _address = State(initialValue: existingHome.address ?? "")
            _icon = State(initialValue: existingHome.icon ?? "")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("家庭名称*", text: $name)
                    
                    TextField("地址", text: $address)
                    
                    TextField("图标 (SF Symbols)", text: $icon)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle(existingHome == nil ? "添加家庭" : "编辑家庭")
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
                        
                        if let existingHome = existingHome {
                            // Update existing home directly
                            existingHome.name = name
                            existingHome.address = address.isEmpty ? nil : address
                            existingHome.icon = icon.isEmpty ? nil : icon
                            existingHome.updatedAt = Date()
                        } else {
                            // Create new home
                            let newHome = Home(
                                name: name,
                                address: address.isEmpty ? nil : address,
                                icon: icon.isEmpty ? nil : icon
                            )
                            
                            onSave(newHome)
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
        AddHomeSheet { _ in }
    }
    .modelContainer(for: [Item.self, StorageLocation.self, Home.self], inMemory: true)
}