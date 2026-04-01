//
//  AddPlaceSheet.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/1.
//

import SwiftUI
import SwiftData

struct AddPlaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let existingPlace: Home?  // Added to support editing existing places
    let onSave: (Home) -> Void
    
    @State private var name = ""
    @State private var address = ""
    @State private var icon = ""
    
    init(existingPlace: Home? = nil, onSave: @escaping (Home) -> Void) {
        self.existingPlace = existingPlace
        self.onSave = onSave
        
        // Initialize state variables if editing an existing place
        if let existingPlace = existingPlace {
            _name = State(initialValue: existingPlace.name)
            _address = State(initialValue: existingPlace.address ?? "")
            _icon = State(initialValue: existingPlace.icon ?? "")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("场所名称*", text: $name)
                    
                    TextField("地址", text: $address)
                    
                    TextField("图标 (SF Symbols)", text: $icon)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
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
                            existingPlace.icon = icon.isEmpty ? nil : icon
                            existingPlace.updatedAt = Date()
                        } else {
                            // Create new place
                            let newPlace = Home(
                                name: name,
                                address: address.isEmpty ? nil : address,
                                icon: icon.isEmpty ? nil : icon
                            )
                            
                            onSave(newPlace)
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
        AddPlaceSheet { _ in }
    }
    .modelContainer(for: [Item.self, StorageLocation.self, Home.self], inMemory: true)
}