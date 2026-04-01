import SwiftUI
import SwiftData
import PhotosUI

struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Predefined categories for home inventory
    private let presetCategories = [
        "家电电器", "厨房用品", "衣物鞋帽", "书籍文具",
        "食品饮品", "清洁用品", "医药保健", "装饰摆件",
        "工具设备", "其他杂物"
    ]
    
    // Item properties
    @State private var name: String = ""
    @State private var quantity: Int = 1
    @State private var category: String = ""  // Selected category
    @State private var details: String = ""
    @State private var value: Double?  // Changed to Double?
    @State private var purchaseDate: Date?
    @State private var expiryDate: Date?
    @State private var tagsText: String = ""  // For tag input
    
    // Location selection
    @State private var selectedLocation: StorageLocation?
    let location: StorageLocation?  // Pre-selected location (for adding item to specific location)
    
    // Photo handling
    @State private var photoData: Data?
    @State private var showingImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    // Existing item reference (for edit mode)
    let existingItem: Item?
    
    // Completion handler
    let onAdd: (Item) -> Void
    
    init(location: StorageLocation?, existingItem: Item? = nil, onAdd: @escaping (Item) -> Void) {
        self.location = location
        self.existingItem = existingItem
        self.onAdd = onAdd
        
        // Initialize with existing item data if in edit mode
        if let existingItem = existingItem {
            _name = State(initialValue: existingItem.name)
            _quantity = State(initialValue: existingItem.quantity)
            _category = State(initialValue: existingItem.category ?? "")
            _details = State(initialValue: existingItem.details ?? "")
            _value = State(initialValue: existingItem.value)
            _purchaseDate = State(initialValue: existingItem.purchaseDate)
            _expiryDate = State(initialValue: existingItem.expiryDate)
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
                    
                    TextField("描述", text: $details)
                }
                
                Section("分类与标签") {
                    Picker("类别", selection: $category) {
                        Text("未分类").tag("")
                        ForEach(presetCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    TextField("标签 (用逗号分隔)", text: $tagsText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
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
                                Image(systemName: loc.getSafeIconName())
                                VStack(alignment: .leading) {
                                    Text(loc.name)
                                        .font(.headline)
                                    Text(getLocationPath(for: loc))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
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
                        
                        let tags = tagsText.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }.filter { !$0.isEmpty }
                        let numericValue = value
                        
                        if let existingItem = existingItem {
                            // Update existing item directly - no new item creation
                            existingItem.name = name
                            existingItem.quantity = quantity
                            existingItem.details = details.isEmpty ? nil : details
                            existingItem.value = numericValue
                            existingItem.purchaseDate = purchaseDate
                            existingItem.expiryDate = expiryDate
                            existingItem.category = category.isEmpty ? nil : category
                            existingItem.tags = tags
                            existingItem.photoData = photoData
                            existingItem.location = selectedLocation ?? location
                            existingItem.updatedAt = Date()
                            
                            // Call onSave with the existing (now updated) item
                            onAdd(existingItem)
                        } else {
                            // Create new item for add mode
                            let newItem = Item(
                                name: name,
                                quantity: quantity,
                                location: selectedLocation ?? location,
                                details: details.isEmpty ? nil : details,
                                value: numericValue,
                                purchaseDate: purchaseDate,
                                expiryDate: expiryDate,
                                category: category.isEmpty ? nil : category,
                                tags: tags,
                                photoData: photoData
                            )
                            
                            onAdd(newItem)
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
    
    // Helper function to get full location path - with nil safety and depth limit
    func getLocationPath(for location: StorageLocation) -> String {
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
}

// Simple location picker view - FLAT LIST APPROACH
struct LocationPickerView: View {
    @Binding var selectedLocation: StorageLocation?
    @Query private var allLocations: [StorageLocation]
    
    var sortedLocations: [StorageLocation] {
        allLocations.sorted { $0.name < $1.name }
    }
    
    // Helper function to get full location path - with nil safety and depth limit
    func getLocationPath(for location: StorageLocation) -> String {
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
                        Image(systemName: location.getSafeIconName())
                        VStack(alignment: .leading) {
                            Text(location.name)
                                .font(.headline)
                            Text(getLocationPath(for: location))
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