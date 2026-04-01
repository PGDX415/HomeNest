import SwiftUI
import SwiftData

struct LocationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let locationID: PersistentIdentifier
    @State private var location: StorageLocation?
    
    @Query private var allLocations: [StorageLocation]
    @Query private var allItems: [Item]
    
    @State private var showingAddSubLocationSheet = false
    @State private var showingAddItemSheet = false
    
    init(location: StorageLocation) {
        self.locationID = location.persistentModelID
        self._location = State(initialValue: location)
    }
    
    var subLocations: [StorageLocation] {
        allLocations.filter { $0.parent?.persistentModelID == locationID }
            .sorted { $0.name < $1.name }
    }
    
    var items: [Item] {
        allItems.filter { $0.location?.persistentModelID == locationID }
            .sorted { $0.name < $1.name }
    }
    
    var body: some View {
        Group {
            if let safeLocation = location {
                List {
                    // Location info section
                    Section("位置信息") {
                        HStack {
                            Image(systemName: safeLocation.getSafeIconName())
                                .font(.title2)
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading) {
                                Text(safeLocation.name)
                                    .font(.title2)
                                Text(safeLocation.type.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // Sub-locations section
                    if !subLocations.isEmpty {
                        Section("子位置 (\(subLocations.count))") {
                            ForEach(subLocations, id: \.persistentModelID) { subLocation in
                                NavigationLink(destination: LocationDetailView(location: subLocation)) {
                                    HStack {
                                        Image(systemName: subLocation.getSafeIconName())
                                        Text(subLocation.name)
                                        Spacer()
                                        Text(subLocation.type.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Items section
                    if !items.isEmpty {
                        Section("物品 (\(items.count))") {
                            ForEach(items, id: \.persistentModelID) { item in
                                NavigationLink(destination: ItemDetailView(item: item)) {
                                    HStack {
                                        if let photoData = item.photoData,
                                           let uiImage = UIImage(data: photoData) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 40, height: 40)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        } else {
                                            Image(systemName: "photo")
                                                .frame(width: 40, height: 40)
                                                .background(Color.secondary.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        
                                        VStack(alignment: .leading) {
                                            Text(item.name)
                                                .font(.headline)
                                            if let category = item.category {
                                                Text(category)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Text("\(item.quantity)")
                                            .font(.headline)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle(safeLocation.name)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: {
                                showingAddSubLocationSheet = true
                            }) {
                                Label("添加子位置", systemImage: "folder.badge.plus")
                            }
                            
                            Button(action: {
                                showingAddItemSheet = true
                            }) {
                                Label("添加物品", systemImage: "plus")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                .sheet(isPresented: $showingAddSubLocationSheet) {
                    AddLocationSheet(parentLocation: safeLocation) { newLocation in
                        modelContext.insert(newLocation)
                    }
                }
                .sheet(isPresented: $showingAddItemSheet) {
                    AddItemSheet(location: safeLocation) { newItem in
                        modelContext.insert(newItem)
                    }
                }
            } else {
                // Fallback view if location is invalid
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("位置信息不可用")
                        .font(.title2)
                        .padding()
                    Button("返回") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
                .navigationTitle("错误")
                .onAppear {
                    // Try to find the location by ID
                    if let foundLocation = allLocations.first(where: { $0.persistentModelID == locationID }) {
                        location = foundLocation
                    } else {
                        // Location not found - probably deleted
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            // Validate location exists
            if location == nil || location?.persistentModelID != locationID {
                if let foundLocation = allLocations.first(where: { $0.persistentModelID == locationID }) {
                    location = foundLocation
                } else {
                    // Location doesn't exist - auto-dismiss after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
            }
        }
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
}

#Preview {
    LocationDetailView(location: StorageLocation(name: "客厅", type: .room, icon: "house.fill"))
        .modelContainer(for: [Item.self, StorageLocation.self], inMemory: true)
}