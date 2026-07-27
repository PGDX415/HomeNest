import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allHomes: [Home]
    @Query private var allItems: [Item]
    
    var body: some View {
        if allHomes.isEmpty {
            // 没有场所时显示引导页面
            EmptyDashboardView()
        } else {
            // 有场所时显示统计信息
            StatisticsDashboardView()
        }
    }
}

// 空状态引导页面
struct EmptyDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddPlaceSheet = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "house.fill")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
                .padding()
                .background(
                    Circle()
                        .fill(Color.secondary.opacity(0.1))
                )
            
            Text("欢迎使用 HomeNest")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("您还没有添加任何场所。\n开始管理您的家庭物品吧！")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showingAddPlaceSheet = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("添加第一个场所")
                        .font(.headline)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingAddPlaceSheet) {
            AddPlaceSheet { newPlace in
                // Set as primary if this is the first place
                newPlace.isPrimary = true
                modelContext.insert(newPlace)
            }
        }
    }
}

// 统计信息页面
struct StatisticsDashboardView: View {
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

    // Status counts
    var idleCount: Int { allItems.filter { $0.status == .idle }.count }
    var lentCount: Int { allItems.filter { $0.status == .lent }.count }
    var overdueLentCount: Int {
        let today = Date()
        return allItems.filter { $0.status == .lent && ($0.expectedReturnDate.map { $0 < today } ?? false) }.count
    }

    // Shopping list
    var restockCount: Int { allItems.filter { $0.needsRestock }.count }

    // Warranty counts
    var expiringWarrantyCount: Int {
        let today = Date()
        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: today)!
        return allItems.filter { item in
            if let warrantyEnd = item.warrantyEndDate {
                return warrantyEnd >= today && warrantyEnd <= nextMonth
            }
            return false
        }.count
    }

    var expiredWarrantyCount: Int {
        let today = Date()
        return allItems.filter { item in
            if let warrantyEnd = item.warrantyEndDate {
                return warrantyEnd < today
            }
            return false
        }.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 标题
                Text("统计概览")
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // 数据卡片
                VStack(spacing: 15) {
                    NavigationLink(destination: GroupedLocationsView()) {
                        DashboardCard(title: "位置总数", count: allLocations.count, icon: "folder.fill", color: .green)
                    }
                    NavigationLink(destination: ItemsView()) {
                        DashboardCard(title: "物品总数", count: allItems.count, icon: "list.bullet.rectangle", color: .blue)
                    }
                    NavigationLink(destination: ValuableItemsView()) {
                        DashboardCard(title: "总价值", countText: "¥\(String(format: "%.0f", totalValue))", icon: "dollarsign.circle", color: .orange)
                    }

                    if totalValue > 0 {
                        NavigationLink(destination: InsuranceReportView()) {
                            DashboardCard(title: "保险清单", countText: "生成报表", icon: "doc.richtext", color: .purple)
                        }
                    }
                    NavigationLink(destination: ExpiringItemsView()) {
                        DashboardCard(title: "即将过期", count: expiringSoonItems.count, icon: "clock.arrow.circlepath", color: .red)
                    }

                    if restockCount > 0 {
                        NavigationLink(destination: ShoppingListView()) {
                            DashboardCard(title: "购物清单", count: restockCount, icon: "cart.fill", color: .orange)
                        }
                    }

                    if idleCount > 0 {
                        NavigationLink(destination: ItemsView()) {
                            DashboardCard(title: "闲置物品", count: idleCount, icon: "circle.slash", color: .orange)
                        }
                    }

                    if lentCount > 0 {
                        NavigationLink(destination: ItemsView()) {
                            DashboardCard(title: "借出物品", count: lentCount, icon: "arrowshape.turn.up.right", color: .blue)
                        }
                    }

                    if overdueLentCount > 0 {
                        NavigationLink(destination: ItemsView()) {
                            DashboardCard(title: "逾期未归还", count: overdueLentCount, icon: "exclamationmark.arrow.triangle.2.circlepath", color: .red)
                        }
                    }

                    if expiringWarrantyCount > 0 {
                        NavigationLink(destination: ItemsView()) {
                            DashboardCard(title: "保修即将到期", count: expiringWarrantyCount, icon: "checkmark.shield.fill", color: .orange)
                        }
                    } else if expiredWarrantyCount > 0 {
                        DashboardCard(title: "保修已过期", count: expiredWarrantyCount, icon: "xmark.shield.fill", color: .red)
                    }
                }
                .padding(.horizontal)
                
                // 最近添加的物品
                if !recentItems.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("最近添加")
                                .font(.headline)
                            
                            Spacer()
                            
                            NavigationLink("查看全部") {
                                ItemsView()
                            }
                            .font(.caption)
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(recentItems, id: \.persistentModelID) { item in
                                    NavigationLink(destination: ItemDetailView(item: item)) {
                                        RecentItemCard(item: item)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
                
                Spacer()
            }
            .padding(.bottom)
        }
        .navigationTitle("统计概览")
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
                    Image(systemName: "plus")
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

// 数据卡片组件
struct DashboardCard: View {
    let title: String
    var count: Int = 0
    var countText: String = ""
    let icon: String
    let color: Color
    
    var displayCount: String {
        if !countText.isEmpty {
            return countText
        }
        return "\(count)"
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.1))
                )
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(displayCount)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// 最近物品卡片
struct RecentItemCard: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let photoData = item.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(systemName: "photo")
                    .frame(width: 100, height: 100)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Text(item.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .foregroundColor(.primary)
            
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
                
                Text("x\(item.quantity)")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
        .frame(width: 120)
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(for: [Item.self, StorageLocation.self], inMemory: true)
}
