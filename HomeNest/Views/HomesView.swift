//
//  HomesView.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/1.
//

import SwiftUI
import SwiftData

struct HomesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allHomes: [Home]
    
    @State private var showingAddHomeSheet = false
    
    var body: some View {
        List {
            ForEach(allHomes, id: \.persistentModelID) { home in
                NavigationLink(destination: LocationsView(home: home)) {
                    HStack {
                        if let icon = home.icon, !icon.isEmpty {
                            Image(systemName: icon)
                                .foregroundColor(.primary)
                        } else {
                            Image(systemName: "house.fill")
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(home.name)
                                .font(.headline)
                            if let address = home.address {
                                Text(address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if home.isPrimary {
                            Text("主")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            .onDelete(perform: deleteHomes)
        }
        .navigationTitle("家庭")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddHomeSheet = true
                }) {
                    Label("添加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddHomeSheet) {
            AddHomeSheet { newHome in
                // Set as primary if this is the first home
                if allHomes.isEmpty {
                    newHome.isPrimary = true
                }
                modelContext.insert(newHome)
            }
        }
        .alert("确认删除家庭", isPresented: $showingDeleteConfirmation) {
            Button("删除", role: .destructive) {
                if let home = homeToDelete {
                    deleteHome(home)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            deleteConfirmationMessage()
        }
    }
    
    @State private var showingDeleteConfirmation = false
    @State private var homeToDelete: Home?
    
    // Helper function to generate delete confirmation message
    private func deleteConfirmationMessage() -> Text {
        guard let home = homeToDelete else {
            return Text("确定要删除此家庭吗？此操作无法撤销。")
        }
        
        let locationCount = home.locations.count
        var message = "确定要删除家庭\"\(home.name)\"吗？"
        
        if locationCount > 0 {
            message += "\n\n此操作将同时删除："
            message += "\n• \(locationCount) 个位置"
            message += "\n• 所有相关物品"
            message += "\n\n此操作无法撤销。"
        }
        
        return Text(message)
    }
    
    private func deleteHomes(offsets: IndexSet) {
        guard let index = offsets.first, index < allHomes.count else { return }
        let home = allHomes[index]
        homeToDelete = home
        showingDeleteConfirmation = true
    }
    
    private func deleteHome(_ home: Home) {
        withAnimation {
            modelContext.delete(home)
        }
        homeToDelete = nil
    }
}

#Preview {
    HomesView()
        .modelContainer(for: [Item.self, StorageLocation.self, Home.self], inMemory: true)
}