//
//  ShoppingListView.swift
//  HomeNest
//

import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.name) private var allItems: [Item]

    @State private var showRestocked = false

    private var restockItems: [Item] {
        allItems.filter { $0.needsRestock }
    }

    private var groupedByCategory: [(category: String, items: [Item])] {
        let grouped = Dictionary(grouping: restockItems) { $0.category ?? "未分类" }
        return grouped.map { (category: $0.key, items: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.category < $1.category }
    }

    var body: some View {
        Group {
            if restockItems.isEmpty {
                emptyView
            } else {
                List {
                    ForEach(groupedByCategory, id: \.category) { group in
                        Section("\(group.category) (\(group.items.count))") {
                            ForEach(group.items, id: \.persistentModelID) { item in
                                HStack {
                                    Image(systemName: "cart")
                                        .foregroundColor(.orange)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.subheadline)
                                        if let location = item.location {
                                            Text(location.name)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Text("x\(item.quantity)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        markAsRestocked(item)
                                    } label: {
                                        Label("已补货", systemImage: "checkmark.cart.fill")
                                    }
                                    .tint(.green)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        item.needsRestock = false
                                        try? modelContext.save()
                                    } label: {
                                        Label("移除", systemImage: "cart.badge.minus")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("购物清单")
        .toolbar {
            if !restockItems.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("全部补货") {
                        for item in restockItems {
                            item.needsRestock = false
                            item.updatedAt = Date()
                        }
                        try? modelContext.save()
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "cart.fill")
                .font(.system(size: 70))
                .foregroundColor(.secondary)
                .padding()
                .background(Circle().fill(Color.secondary.opacity(0.1)))

            Text("购物清单为空")
                .font(.title2)
                .fontWeight(.medium)

            Text("在物品详情中点击「加入购物清单」\n即可在此汇集需要补货的物品")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
    }

    private func markAsRestocked(_ item: Item) {
        item.needsRestock = false
        item.updatedAt = Date()
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        ShoppingListView()
    }
}
