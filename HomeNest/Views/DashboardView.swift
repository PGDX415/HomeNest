import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [Item]
    @Query private var allLocations: [StorageLocation]
    
    @State private var showingAddItemSheet = false
    @State private var showingAddLocationSheet = false
    
    // Get recent items (last 5 added)
    var recentItems: [Item] {
        allItems.sorted { $0.createdAt > $1.createdAt }.prefix(5).map { $0 }
    }
    
    // Calculate total value
    var totalValue: Double {
        allItems.compactMap { $0.value }.reduce(0, +)
    }
    
    // Get expiring soon items (next 30 days)
    var expiringSoonItems: [Item] {
        let today = Date()
        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: today)!
        
        return allItems.filter { item in
            if let expiryDate = item.expiryDate {
                return expiryDate >= today && expiryDate <= nextMonth
            }
            return false
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Statistics cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    // Total Items Card
                    DashboardCard(
                        title: "物品总数",
                        value: "\(allItems.count)",
                        icon: "list.bullet.rectangle",
                        color: .blue
                    )
                    
                    // Total Locations Card
                    DashboardCard(
                        title: "位置总数",
                        value: "\(allLocations.count)",
                        icon: "folder.fill",
                        color: .green
                    )
                    
                    // Total Value Card
                    DashboardCard(
                        title: "总价值",
                        value: "¥\(String(format: "%.0f", totalValue))",
                        icon: "dollarsign.circle",
                        color: .orange
                    )
                    
                    // Expiring Soon Card
                    DashboardCard(
                        title: "即将过期",
                        value: "\(expiringSoonItems.count)",
                        icon: "clock.arrow.circlepath",
                        color: .red
                    )
                }
                .padding(.horizontal)
                
                // Recent Items Section
                if !recentItems.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("最近添加")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            NavigationLink("查看全部") {
                                ItemsView()
                            }
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            ForEach(recentItems, id: \.persistentModelID) { item in
                                NavigationLink(destination: ItemDetailView(item: item)) {
                                    RecentItemCard(item: item)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .navigationTitle("家物管")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showingAddItemSheet = true
                    }) {
                        Label("添加物品", systemImage: "plus")
                    }
                    
                    Button(action: {
                        showingAddLocationSheet = true
                    }) {
                        Label("添加位置", systemImage: "folder.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title)
                }
            }
        }
        .sheet(isPresented: $showingAddItemSheet) {
            AddItemSheet(location: nil) { newItem in
                modelContext.insert(newItem)
            }
        }
        .sheet(isPresented: $showingAddLocationSheet) {
            AddLocationSheet(parentLocation: nil) { newLocation in
                modelContext.insert(newLocation)
            }
        }
    }
}

// Dashboard statistics card
struct DashboardCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// Recent item card for grid display
struct RecentItemCard: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Photo or placeholder
            if let photoData = item.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: 100)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                    }
                    .cornerRadius(12)
            }
            
            // Item name
            Text(item.name)
                .lineLimit(2)
                .font(.subheadline)
                .fontWeight(.medium)
            
            // Location or category
            HStack {
                if let location = item.location {
                    Text(location.name)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else if let category = item.category {
                    Text(category)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Quantity
                Text("x\(item.quantity)")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Item.self, StorageLocation.self], inMemory: true)
}
