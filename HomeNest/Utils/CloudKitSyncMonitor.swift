//
//  CloudKitSyncMonitor.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/7/23.
//

import Foundation
import SwiftData
import CoreData
import CloudKit
import Combine

/// 监控 iCloud CloudKit 同步状态的工具类
@MainActor
final class CloudKitSyncMonitor: ObservableObject {
    static let shared = CloudKitSyncMonitor()

    enum SyncStatus: Equatable {
        case notAvailable
        case initializing
        case syncing
        case synced
        case error(String)
        case unknown
    }

    @Published var syncStatus: SyncStatus = .unknown
    @Published var lastSyncDate: Date?
    @Published var isiCloudAvailable: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var syncTimeoutTask: Task<Void, Never>?

    private init() {
        checkiCloudStatus()
        setupObservers()
    }

    func checkiCloudStatus() {
        CKContainer.default().accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    self.syncStatus = .error(error.localizedDescription)
                    self.isiCloudAvailable = false
                    return
                }
                switch status {
                case .available:
                    self.isiCloudAvailable = true
                    if self.syncStatus == .unknown || self.syncStatus == .notAvailable {
                        self.syncStatus = .initializing
                    }
                case .noAccount, .restricted:
                    self.isiCloudAvailable = false
                    self.syncStatus = .notAvailable
                case .couldNotDetermine:
                    self.isiCloudAvailable = false
                    self.syncStatus = .unknown
                case .temporarilyUnavailable:
                    self.isiCloudAvailable = true
                    self.syncStatus = .error("iCloud 暂时不可用")
                @unknown default:
                    self.isiCloudAvailable = false
                    self.syncStatus = .unknown
                }
            }
        }
    }

    private func setupObservers() {
        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .sink { [weak self] notification in
                DispatchQueue.main.async {
                    self?.handleSyncEvent(notification)
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.checkiCloudStatus()
            }
            .store(in: &cancellables)
    }

    private func handleSyncEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else { return }

        syncTimeoutTask?.cancel()

        if event.succeeded {
            syncStatus = .synced
            lastSyncDate = event.endDate
        } else if let error = event.error {
            syncStatus = .error(error.localizedDescription)
        } else {
            switch event.type {
            case .setup: syncStatus = .initializing
            case .import, .export: syncStatus = .syncing
            default: break
            }

            syncTimeoutTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { return }
                if self?.syncStatus == .initializing || self?.syncStatus == .syncing {
                    await MainActor.run {
                        self?.syncStatus = .synced
                    }
                }
            }
        }
    }

    func requestSync() {
        checkiCloudStatus()
    }

    var statusDescription: String {
        switch syncStatus {
        case .notAvailable: return "iCloud 不可用"
        case .initializing: return "正在初始化云同步..."
        case .syncing:      return "正在同步..."
        case .synced:       return "已同步"
        case .error:        return "同步出错"
        case .unknown:      return "检查中..."
        }
    }

    var statusIcon: String {
        switch syncStatus {
        case .notAvailable: return "icloud.slash"
        case .initializing: return "icloud.and.arrow.down"
        case .syncing:      return "arrow.triangle.2.circlepath.icloud"
        case .synced:       return "icloud.fill"
        case .error:        return "icloud.slash"
        case .unknown:      return "questionmark.icloud"
        }
    }

    var lastSyncDescription: String? {
        guard let date = lastSyncDate else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .short
        return "上次同步: \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}
