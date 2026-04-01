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
                        // Safe icon handling - ensure non-empty valid SF Symbol
                        if let icon = place.icon, !icon.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Image(systemName: icon.trimmingCharacters(in: .whitespacesAndNewlines))
                                .foregroundColor(.primary)
                        } else {
                            Image(systemName: "house.fill")
                                .foregroundColor(.primary)
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
        .alert("确认删除场所", isPresented: $showingDeleteConfirmation) {
            Button("删除", role: .destructive) {
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
            return Text("确定要删除此场所吗？此操作无法撤销。")
        }
        
        let locationCount = place.locations.count
        var message = "确定要删除场所\"\(place.name)\"吗？"
        
        if locationCount > 0 {
            message += "\n\n此操作将同时删除："
            message += "\n• \(locationCount) 个位置"
            message += "\n• 所有相关物品"
            message += "\n\n此操作无法撤销。"
        }
        
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