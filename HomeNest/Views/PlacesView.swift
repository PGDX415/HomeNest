//
//  PlacesView.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/1.
//

import SwiftUI
import SwiftData

struct PlacesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allPlaces: [Home]
    
    @State private var showingAddPlaceSheet = false
    
    var body: some View {
        List {
            ForEach(allPlaces, id: \.persistentModelID) { place in
                NavigationLink(destination: LocationsView(home: place)) {
                    HStack {
                        // Safe icon handling - ensure non-empty valid SF Symbol with custom color
                        if let icon = place.icon, !icon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Image(systemName: icon.trimmingCharacters(in: .whitespacesAndNewlines))
                                .foregroundColor(place.getIconColor())
                        } else {
                            Image(systemName: "house.fill")
                                .foregroundColor(place.getIconColor())
                        }
                        
                        VStack(alignment: .leading) {
                            Text(place.name)
                                .font(.headline)
                            if let address = place.address {
                                Text(address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // 显示物品数量
                            let itemCount = place.totalItemCount()
                            if itemCount > 0 {
                                Text("\(itemCount) 个物品")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if place.isPrimary {
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
            .onDelete(perform: deletePlaces)
        }
        .navigationTitle("场所")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddPlaceSheet = true
                }) {
                    Label("添加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPlaceSheet) {
            AddPlaceSheet { newPlace in
                // Set as primary if this is the first place
                if allPlaces.isEmpty {
                    newPlace.isPrimary = true
                }
                modelContext.insert(newPlace)
            }
        }
        .alert("⚠️ 警告：永久删除场所", isPresented: $showingDeleteConfirmation) {
            Button("永久删除", role: .destructive) {
                if let place = placeToDelete {
                    deletePlace(place)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            deleteConfirmationMessage()
        }
    }
    
    @State private var showingDeleteConfirmation = false
    @State private var placeToDelete: Home?
    
    // Helper function to generate delete confirmation message
    private func deleteConfirmationMessage() -> Text {
        guard let place = placeToDelete else {
            return Text("确定要删除此场所吗？\n\n⚠️ 此操作将永久删除所有相关数据，无法恢复！")
        }
        
        let locationCount = place.locations.count
        let totalItemCount = place.totalItemCount()
        var message = "⚠️ **严重警告**\n\n"
        message += "您即将永久删除场所\"\(place.name)\"及其所有数据！\n\n"
        
        if locationCount > 0 || totalItemCount > 0 {
            message += "**将被永久删除的数据包括：**\n"
            if locationCount > 0 {
                message += "• \(locationCount) 个位置\n"
            }
            if totalItemCount > 0 {
                message += "• \(totalItemCount) 个物品\n"
            }
            message += "\n"
        }
        
        message += "**重要提醒：**\n"
        message += "• 此操作**无法撤销**\n"
        message += "• 所有数据将**永久丢失**\n"
        message += "• 请确保您已备份重要数据\n\n"
        message += "确定要继续吗？"
        
        return Text(message)
    }
    
    private func deletePlaces(offsets: IndexSet) {
        guard let index = offsets.first, index < allPlaces.count else { return }
        let place = allPlaces[index]
        placeToDelete = place
        showingDeleteConfirmation = true
    }
    
    private func deletePlace(_ place: Home) {
        withAnimation {
            modelContext.delete(place)
        }
        placeToDelete = nil
    }
}

#Preview {
    PlacesView()
        .modelContainer(for: [Item.self, StorageLocation.self, Home.self], inMemory: true)
}