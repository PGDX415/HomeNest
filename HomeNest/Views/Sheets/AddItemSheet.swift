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
    @State private var warrantyEndDate: Date?
    @State private var warrantyNotes = ""
    @State private var lentTo = ""
    @State private var lentDate: Date?
    @State private var expectedReturnDate: Date?
    @State private var category = ""
    @State private var tagsText = ""
    @State private var selectedLocation: StorageLocation?
    @State private var selectedFamilyMember: FamilyMember?
    @State private var selectedStatus: ItemStatus = .active

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?

    // Barcode scanner
    @State private var showingScanner = false
    @State private var scannedBarcode = ""
    @State private var isLookingUp = false

    @Query(sort: \FamilyMember.name) private var familyMembers: [FamilyMember]

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
            _warrantyEndDate = State(initialValue: existingItem.warrantyEndDate)
            _warrantyNotes = State(initialValue: existingItem.warrantyNotes ?? "")
            _lentTo = State(initialValue: existingItem.lentTo ?? "")
            _lentDate = State(initialValue: existingItem.lentDate)
            _expectedReturnDate = State(initialValue: existingItem.expectedReturnDate)
            _category = State(initialValue: existingItem.category ?? "")
            _tagsText = State(initialValue: existingItem.tags.joined(separator: ", "))
            _photoData = State(initialValue: existingItem.photoData)
            _selectedLocation = State(initialValue: existingItem.location)
            _selectedStatus = State(initialValue: existingItem.status)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    // 条形码扫描按钮
                    Button(action: { showingScanner = true }) {
                        HStack {
                            if isLookingUp {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("正在查询产品信息...")
                            } else if !scannedBarcode.isEmpty {
                                Image(systemName: "barcode.viewfinder")
                                    .foregroundColor(.green)
                                Text("已扫描: \(scannedBarcode)")
                                    .foregroundColor(.secondary)
                            } else {
                                Image(systemName: "barcode.viewfinder")
                                Text("扫描条形码")
                            }
                        }
                    }
                    .disabled(isLookingUp)

                    TextField("物品名称*", text: $name)

                    Stepper("数量: \(quantity)", value: $quantity, in: 1...999)
                    
                    TextField("描述", text: $descriptionText)
                }
                
                Section("状态") {
                    Picker("物品状态", selection: $selectedStatus) {
                        ForEach(ItemStatus.allCases, id: \.self) { status in
                            Label(status.rawValue, systemImage: status.icon)
                                .tag(status)
                        }
                    }
                }

                if selectedStatus == .lent {
                    Section("借出详情") {
                        TextField("借出给谁", text: $lentTo)

                        DatePicker("借出日期", selection: Binding(
                            get: { lentDate ?? Date() },
                            set: { lentDate = $0 }
                        ), displayedComponents: [.date])
                        .datePickerStyle(.compact)

                        DatePicker("预计归还", selection: Binding(
                            get: { expectedReturnDate ?? Date().addingTimeInterval(7 * 24 * 3600) },
                            set: { expectedReturnDate = $0 }
                        ), displayedComponents: [.date])
                        .datePickerStyle(.compact)
                    }
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

                    DatePicker("保修截止", selection: Binding(
                        get: { warrantyEndDate ?? Date() },
                        set: { warrantyEndDate = $0 }
                    ), displayedComponents: [.date])
                    .datePickerStyle(.compact)

                    TextField("保修备注（如延保信息）", text: $warrantyNotes)
                        .font(.caption)
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

                if !familyMembers.isEmpty {
                    Section("归属") {
                        Picker("家庭成员", selection: $selectedFamilyMember) {
                            Text("无").tag(FamilyMember?.none)
                            ForEach(familyMembers, id: \.persistentModelID) { member in
                                Text("\(member.emoji) \(member.name)").tag(member as FamilyMember?)
                            }
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
                            existingItem.warrantyEndDate = warrantyEndDate
                            existingItem.warrantyNotes = warrantyNotes.isEmpty ? nil : warrantyNotes
                            existingItem.lentTo = lentTo.isEmpty ? nil : lentTo
                            existingItem.lentDate = lentDate
                            existingItem.expectedReturnDate = expectedReturnDate
                            existingItem.status = selectedStatus
                            existingItem.category = category.isEmpty ? nil : category
                            existingItem.tags = tags
                            existingItem.photoData = photoData
                            existingItem.location = selectedLocation ?? location
                            // Synchronize home property with location's home
                            existingItem.home = (selectedLocation ?? location)?.home
                            existingItem.familyMember = selectedFamilyMember
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
                            newItem.warrantyEndDate = warrantyEndDate
                            newItem.warrantyNotes = warrantyNotes.isEmpty ? nil : warrantyNotes
                            newItem.lentTo = lentTo.isEmpty ? nil : lentTo
                            newItem.lentDate = lentDate
                            newItem.expectedReturnDate = expectedReturnDate
                            newItem.familyMember = selectedFamilyMember
                            newItem.status = selectedStatus

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
                    // Use ImageManager for compression
                    if let uiImage = UIImage(data: data),
                       let compressedData = ImageManager.shared.compressImage(uiImage) {
                        photoData = compressedData
                    } else {
                        photoData = data
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingScanner) {
            BarcodeScanSheetView(
                onScanResult: { barcode in
                    scannedBarcode = barcode
                    showingScanner = false
                    Task {
                        await lookupProduct(barcode: barcode)
                    }
                },
                onCancel: {
                    showingScanner = false
                }
            )
        }
    }

    /// 查询条形码对应的产品信息并填入表单
    private func lookupProduct(barcode: String) async {
        isLookingUp = true
        defer { isLookingUp = false }

        print("🔍 开始查询条码: \(barcode)")

        // 解码条码前缀，获取产地信息
        let barcodeInfo = ProductLookupService.shared.decodeBarcode(barcode)
        print("🔍 条码产地: \(barcodeInfo.country)")

        guard let info = await ProductLookupService.shared.lookup(barcode: barcode) else {
            print("🔍 未查到产品信息，条码号: \(barcode)")
            // 回退：根据产地给出分类提示
            if let hint = barcodeInfo.categoryHint {
                category = hint
                print("🔍 根据产地自动填入分类: \(hint)")
            }
            return
        }

        guard let productName = info.name, !productName.isEmpty else {
            print("🔍 产品名为空，条码号: \(barcode)")
            if let hint = barcodeInfo.categoryHint {
                category = hint
            }
            return
        }

        name = productName
        if let brand = info.brand, !brand.isEmpty {
            name = "\(brand) \(productName)"
        }
        if let mappedCategory = ProductLookupService.shared.mapToHomeNestCategory(info.category) {
            category = mappedCategory
        } else if let hint = barcodeInfo.categoryHint {
            category = hint
        }
        print("🔍 自动填入: 名称=\(name), 分类=\(category), 产地=\(barcodeInfo.country)")
    }
}

// 扫描条形码的全屏 Sheet
struct BarcodeScanSheetView: View {
    let onScanResult: (String) -> Void
    let onCancel: () -> Void

    @State private var isScanning = true

    var body: some View {
        ZStack {
            BarcodeScannerView(onScan: { code in
                isScanning = false
                onScanResult(code)
            }, isScanning: $isScanning)
            .ignoresSafeArea()

            VStack {
                HStack {
                    Button(action: {
                        isScanning = false
                        onCancel()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 60)

                    Spacer()
                }
                Spacer()

                Text("将条形码对准扫描框")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                    .padding(.bottom, 40)
            }
        }
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