import SwiftUI
import SwiftData
import PhotosUI

struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let location: StorageLocation?
    let existingItem: Item?  // Added to support editing existing items
    let onSave: (Item) -> Void
    
    @State private var name = ""
    @State private var quantity = 1
    @State private var descriptionText = ""  // This is the UI field name, not the model property
    @State private var value: Double?
    @State private var purchaseDate: Date?
    @State private var expiryDate: Date?
    @State private var category = ""
    @State private var tagsText = ""
    @State private var selectedLocation: StorageLocation?
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?
    
    // Predefined categories
    private let predefinedCategories = ["家电", "衣物", "书籍", "厨房", "食品", "工具", "装饰", "其他"]
    
    init(location: StorageLocation?, existingItem: Item? = nil, onSave: @escaping (Item) -> Void) {
        self.location = location
        self.existingItem = existingItem
        self.onSave = onSave
        
        // Initialize state variables if editing an existing item
        if let existingItem = existingItem {
            _name = State(initialValue: existingItem.name)
            _quantity = State(initialValue: existingItem.quantity)
            _descriptionText = State(initialValue: existingItem.details ?? "")
            _value = State(initialValue: existingItem.value)
            _purchaseDate = State(initialValue: existingItem.purchaseDate)
            _expiryDate = State(initialValue: existingItem.expiryDate)
            _category = State(initialValue: existingItem.category ?? "")
            _tagsText = State(initialValue: existingItem.tags.joined(separator: ", "))
            _photoData = State(initialValue: existingItem.photoData)
            _selectedLocation = State(initialValue: existingItem.location)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("物品名称*", text: $name)
                    
                    Stepper("数量: \(quantity)", value: $quantity, in: 1...999)
                    
                    TextField("描述", text: $descriptionText)
                }
                
                Section("分类与标签") {
                    Picker("类别", selection: $category) {
                        Text("无").tag("")
                        ForEach(predefinedCategories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                        if !predefinedCategories.contains(category) && !category.isEmpty {
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    TextField("标签 (用逗号分隔)", text: $tagsText)
                        .textInputAutocapitalization(.never)
                }
                
                Section("价值与日期") {
                    HStack {
                        Text("估价 (¥)")
                        Spacer()
                        TextField("0.00", value: $value, format: .number.precision(.fractionLength(2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker("购买日期", selection: Binding(
                        get: { purchaseDate ?? Date() },
                        set: { purchaseDate = $0 }
                    ), displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    
                    DatePicker("保质期", selection: Binding(
                        get: { expiryDate ?? Date() },
                        set: { expiryDate = $0 }
                    ), displayedComponents: [.date])
                    .datePickerStyle(.compact)
                }
                
                Section("位置") {
                    // Always allow location selection in edit mode, or when no location is pre-selected in add mode
                    if existingItem != nil || selectedLocation != nil {
                        // In edit mode, or user has already selected a location in add mode
                        let currentLocation = selectedLocation ?? location
                        if let loc = currentLocation {
                            HStack {
                                if let icon = loc.icon {
                                    Image(systemName: icon)
                                } else {
                                    Image(systemName: "folder.fill")
                                }
                                Text(loc.name)
                                Spacer()
                                Text(loc.type.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        // Always show the navigation link to change location in edit mode
                        if existingItem != nil {
                            NavigationLink(destination: LocationPickerView(selectedLocation: $selectedLocation)) {
                                Label("更改位置", systemImage: "arrow.triangle.2.circlepath")
                                    .foregroundColor(.blue)
                            }
                        }
                    } else {
                        // Add mode with no pre-selected location
                        NavigationLink(destination: LocationPickerView(selectedLocation: $selectedLocation)) {
                            Label("选择位置", systemImage: "folder.fill")
                        }
                    }
                }
                
                Section("照片") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        if let photoData = photoData,
                           let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Label("添加照片", systemImage: "photo.on.rectangle")
                                .frame(height: 200)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
            }
            .navigationTitle(existingItem == nil ? "添加物品" : "编辑物品")  // Updated title based on mode
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
                        
                        let tags = tagsText.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
                        
                        if let existingItem = existingItem {
                            // Update existing item directly - no new item creation
                            existingItem.name = name
                            existingItem.quantity = quantity
                            existingItem.details = descriptionText.isEmpty ? nil : descriptionText
                            existingItem.value = value
                            existingItem.purchaseDate = purchaseDate
                            existingItem.expiryDate = expiryDate
                            existingItem.category = category.isEmpty ? nil : category
                            existingItem.tags = tags
                            existingItem.photoData = photoData
                            existingItem.location = selectedLocation ?? location
                            // Synchronize home property with location's home
                            existingItem.home = (selectedLocation ?? location)?.home
                            existingItem.updatedAt = Date()
                            
                            // Call onSave with the existing (now updated) item
                            onSave(existingItem)
                        } else {
                            // Create new item for add mode
                            let newItem = Item(
                                name: name,
                                quantity: quantity,
                                location: selectedLocation ?? location,
                                details: descriptionText.isEmpty ? nil : descriptionText,
                                value: value,
                                purchaseDate: purchaseDate,
                                expiryDate: expiryDate,
                                category: category.isEmpty ? nil : category,
                                tags: tags,
                                photoData: photoData
                            )
                            
                            onSave(newItem)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .task(id: selectedPhotoItem) {
                guard let selectedItem = selectedPhotoItem else { return }
                
                // Load the selected photo
                if let data = try? await selectedItem.loadTransferable(type: Data.self) {
                    // Compress the image if it's too large
                    if let uiImage = UIImage(data: data),
                       let compressedData = compressImage(uiImage, quality: 0.8) {
                        photoData = compressedData
                    } else {
                        photoData = data
                    }
                }
            }
        }
    }
    
    // Helper function to compress image
    func compressImage(_ image: UIImage, quality: CGFloat) -> Data? {
        // Convert to JPEG with specified quality
        return image.jpegData(compressionQuality: quality)
    }
}

// Simple location picker view - FLAT LIST APPROACH
struct LocationPickerView: View {
    @Binding var selectedLocation: StorageLocation?
    @Query private var allLocations: [StorageLocation]
    
    var sortedLocations: [StorageLocation] {
        allLocations.sorted { $0.name < $1.name }
    }
    
    // Helper function to get full location path - with nil safety and depth limit
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
        List {
            ForEach(sortedLocations, id: \.persistentModelID) { location in
                Button(action: {
                    selectedLocation = location
                }) {
                    HStack {
                        if let icon = location.icon, !icon.isEmpty {
                            Image(systemName: icon)
                        } else {
                            Image(systemName: "folder.fill")
                        }
                        VStack(alignment: .leading) {
                            Text(location.name)
                                .font(.headline)
                            Text(locationPath(for: location))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        if selectedLocation?.persistentModelID == location.persistentModelID {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("选择位置")
    }
}

#Preview {
    NavigationStack {
        AddItemSheet(location: nil) { _ in }
    }
    .modelContainer(for: [Item.self, StorageLocation.self], inMemory: true)
}