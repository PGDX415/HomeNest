//
//  DataBackupView.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/2.
//

import SwiftUI
import SwiftData

struct DataBackupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isExporting = false
    @State private var exportSuccess = false
    @State private var exportError: String?
    @State private var showShareSheet = false
    @State private var exportedFileURL: URL?
    
    var body: some View {
        List {
            Section("本地备份") {
                Button(action: {
                    exportData()
                }) {
                    Label("导出数据备份", systemImage: "arrow.down.doc")
                        .foregroundColor(.blue)
                }
                .disabled(isExporting)
                
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
            
            Section("说明") {
                Text("备份文件包含所有场所、位置、物品和个人信息。点击备份成功的文件可以分享或保存到「文件」App中。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("⚠️ 注意：目前仅支持导出功能，导入功能将在后续版本中实现。")
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