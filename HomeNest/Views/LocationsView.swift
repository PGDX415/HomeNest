import SwiftUI
import SwiftData

struct LocationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allLocations: [StorageLocation]
    
    let home: Home? // Added to support filtering by home
    
    @State private var showingAddLocationSheet = false
    @State private var showingEditLocationSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var locationToDelete: StorageLocation?
    @State private var locationToEdit: StorageLocation?
    
    // Get locations filtered by home and sorted by name
    var filteredLocations: [StorageLocation] {
        if let home = home {
            return allLocations.filter { $0.home?.persistentModelID == home.persistentModelID }
        } else {
            // For backward compatibility or when no home is selected
            return allLocations.filter { $0.home == nil }
        }
    }
    
    var sortedLocations: [StorageLocation] {
        filteredLocations.sorted { $0.name < $1.name }
    }
    
    // Helper function to get full location path - with nil safety
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
    
    // Helper function to generate delete confirmation message
    private func deleteConfirmationMessage(for location: StorageLocation) -> String {
        let itemCount = location.items.count
        let subLocationCount = location.subLocations.count
        var message = "确定要删除位置\"\(location.name)\"吗？"
        
        if itemCount > 0 || subLocationCount > 0 {
            message += "\n\n此操作将同时删除："
            if itemCount > 0 {
                message += "\n• \(itemCount) 个物品"
            }
            if subLocationCount > 0 {
                message += "\n• \(subLocationCount) 个子位置"
            }
            message += "\n\n此操作无法撤销。"
        }
        
        return message
    }
    
    var body: some View {
        List {
            ForEach(sortedLocations, id: \.persistentModelID) { location in
                NavigationLink(destination: LocationDetailView(location: location)) {
                    HStack {
                        // Safe icon handling - ensure non-empty valid SF Symbol
                        if let icon = location.icon, !icon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Image(systemName: icon.trimmingCharacters(in: .whitespacesAndNewlines))
                                .foregroundColor(.primary)
                        } else {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(location.name)
                                .font(.headline)
                            Text(locationPath(for: location))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            
                            // 显示物品数量（包括子位置的物品）
                            let totalCount = location.totalItemCount()
                            if totalCount > 0 {
                                Text("\(totalCount) 个物品")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if location.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                        
                        Text(location.type.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    // Edit action
                    Button(role: .none) {
                        locationToEdit = location
                        showingEditLocationSheet = true
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    .tint(.blue)
                    
                    // Delete action
                    Button(role: .destructive) {
                        locationToDelete = location
                        showingDeleteConfirmation = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    // Favorite toggle action
                    Button(role: .none) {
                        toggleFavorite(for: location)
                    } label: {
                        if location.isFavorite {
                            Label("取消收藏", systemImage: "star.slash")
                        } else {
                            Label("收藏", systemImage: "star")
                        }
                    }
                    .tint(location.isFavorite ? .gray : .orange)
                }
            }
        }
        .navigationTitle(home?.name ?? "位置")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddLocationSheet = true
                }) {
                    Label("添加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddLocationSheet) {
            AddLocationSheet(parentLocation: nil, home: home) { newLocation in
                modelContext.insert(newLocation)
            }
        }
        .sheet(isPresented: $showingEditLocationSheet) {
            if let location = locationToEdit {
                AddLocationSheet(parentLocation: location.parent, home: location.home, existingLocation: location) { _ in
                    // No need to manually save - the sheet updates the existing location directly
                }
            }
        }
        .alert("确认删除位置", isPresented: $showingDeleteConfirmation) {
            Button("删除", role: .destructive) {
                if let location = locationToDelete {
                    deleteLocation(location)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            if let location = locationToDelete {
                Text(deleteConfirmationMessage(for: location))
            } else {
                Text("确定要删除此位置吗？此操作无法撤销。")
            }
        }
    }
    
    private func toggleFavorite(for location: StorageLocation) {
        withAnimation {
            location.isFavorite.toggle()
        }
    }
    
    private func confirmDeleteLocations(offsets: IndexSet) {
        // Only handle single deletion for now (swipe-to-delete typically deletes one item)
        guard let index = offsets.first, index < sortedLocations.count else { return }
        let location = sortedLocations[index]
        locationToDelete = location
        showingDeleteConfirmation = true
    }
    
    private func deleteLocation(_ location: StorageLocation) {
        withAnimation {
            modelContext.delete(location)
        }
        locationToDelete = nil
    }
}

#Preview {
    LocationsView(home: nil)
        .modelContainer(for: [Item.self, StorageLocation.self, Home.self], inMemory: true)
}