//
//  DataBackupView.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/2.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataBackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportSuccess = false
    @State private var importSuccess = false
    @State private var exportError: String?
    @State private var importError: String?
    @State private var showFileExporter = false
    @State private var showFileImporter = false
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var importedItemCount = 0
    
    var body: some View {
        List {
            Section("本地备份") {
                Button(action: {
                    exportData()
                }) {
                    Label("导出数据备份", systemImage: "arrow.down.doc")
                        .foregroundColor(.blue)
                }
                .disabled(isExporting || isImporting)
                
                if isExporting {
                    HStack {
                        ProgressView()
                        Text("正在导出...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let errorMessage = exportError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
                
                if exportSuccess, let fileURL = exportedFileURL {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("备份成功！")
                                .font(.subheadline)
                                .foregroundColor(.green)
                            Text(fileURL.lastPathComponent)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onTapGesture {
                        showShareSheet = true
                    }
                }
            }
            
            Section("数据恢复") {
                Button(action: {
                    showFileImporter = true
                }) {
                    Label("从文件恢复数据", systemImage: "arrow.up.doc")
                        .foregroundColor(.green)
                }
                .disabled(isExporting || isImporting)
                
                if isImporting {
                    HStack {
                        ProgressView()
                        Text("正在恢复...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let errorMessage = importError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
                
                if importSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                        Text("成功恢复 \(importedItemCount) 项数据！")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Section("说明") {
                Text("备份文件包含所有场所、位置、物品和个人信息。点击备份成功的文件可以分享或保存到「文件」App中。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("☁️ 本应用已支持 iCloud 云同步，您可以在同一 Apple ID 的不同设备间自动同步数据。若需手动备份或迁移数据到非 Apple 设备，可使用此导出功能。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("⚠️ 恢复数据会覆盖现有数据，请谨慎操作。建议先备份当前数据再进行恢复。")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .navigationTitle("数据备份")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let fileURL = exportedFileURL {
                ShareSheet(items: [fileURL])
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let fileURL = urls.first {
                    importData(from: fileURL)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.importError = "选择文件失败: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        exportSuccess = false
        exportError = nil
        
        DataBackupManager.shared.exportDataAsJSON(context: modelContext) { result in
            DispatchQueue.main.async {
                self.isExporting = false
                
                switch result {
                case .success(let fileURL):
                    self.exportedFileURL = fileURL
                    self.exportSuccess = true
                case .failure(let error):
                    self.exportError = "导出失败: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func importData(from fileURL: URL) {
        isImporting = true
        importSuccess = false
        importError = nil
        
        DataBackupManager.shared.importDataFromJSON(fileURL: fileURL, context: modelContext) { result in
            DispatchQueue.main.async {
                self.isImporting = false
                
                switch result {
                case .success(let itemCount):
                    self.importedItemCount = itemCount
                    self.importSuccess = true
                case .failure(let error):
                    self.importError = "恢复失败: \(error.localizedDescription)"
                }
            }
        }
    }
}

// 简单的分享视图
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        DataBackupView()
    }
    .modelContainer(for: [Item.self, StorageLocation.self, Home.self, UserProfile.self], inMemory: true)
}