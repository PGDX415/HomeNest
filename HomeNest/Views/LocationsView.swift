import SwiftUI
import SwiftData

struct LocationsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allLocations: [StorageLocation]
    
    @State private var showingAddLocationSheet = false
    
    // Get all locations sorted by name
    var sortedLocations: [StorageLocation] {
        allLocations.sorted { $0.name < $1.name }
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
    
    var body: some View {
        List {
            ForEach(sortedLocations, id: \.persistentModelID) { location in
                NavigationLink(destination: LocationDetailView(location: location)) {
                    HStack {
                        if let icon = location.icon, !icon.isEmpty {
                            Image(systemName: icon)
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
                        }
                        
                        Spacer()
                        
                        Text(location.type.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onDelete(perform: deleteLocations)
        }
        .navigationTitle("位置")
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
            AddLocationSheet(parentLocation: nil) { newLocation in
                modelContext.insert(newLocation)
            }
        }
    }
    
    private func deleteLocations(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                guard index < sortedLocations.count else { continue }
                modelContext.delete(sortedLocations[index])
            }
        }
    }
}

#Preview {
    LocationsView()
        .modelContainer(for: [Item.self, StorageLocation.self], inMemory: true)
}