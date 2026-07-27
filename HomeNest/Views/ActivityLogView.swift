//
//  ActivityLogView.swift
//  HomeNest
//

import SwiftUI
import SwiftData

struct ActivityLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivityLog.timestamp, order: .reverse) private var logs: [ActivityLog]

    private var groupedByDate: [(date: String, logs: [ActivityLog])] {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none

        let grouped = Dictionary(grouping: logs) { df.string(from: $0.timestamp) }
        return grouped.map { (date: $0.key, logs: $0.value) }
            .sorted { $0.logs.first?.timestamp ?? Date() > $1.logs.first?.timestamp ?? Date() }
    }

    var body: some View {
        Group {
            if logs.isEmpty {
                emptyView
            } else {
                List {
                    ForEach(groupedByDate, id: \.date) { group in
                        Section(group.date) {
                            ForEach(group.logs, id: \.persistentModelID) { log in
                                HStack {
                                    Image(systemName: iconForAction(log.action))
                                        .foregroundColor(colorForAction(log.action))
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(log.itemName)
                                            .font(.subheadline)
                                        HStack {
                                            Text(log.action)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            if let detail = log.detail {
                                                Text("• \(detail)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }

                                    Spacer()

                                    Text(log.timestamp, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("操作日志")
        .toolbar {
            if !logs.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("清空") {
                        for log in logs {
                            modelContext.delete(log)
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
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .padding()
                .background(Circle().fill(Color.secondary.opacity(0.1)))
            Text("暂无操作记录")
                .font(.title2)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private func iconForAction(_ action: String) -> String {
        switch action {
        case "添加": return "plus.circle.fill"
        case "编辑": return "pencil.circle.fill"
        case "删除": return "trash.circle.fill"
        case "移动": return "arrow.right.circle.fill"
        case "状态变更": return "arrow.triangle.2.circlepath"
        default: return "circle.fill"
        }
    }

    private func colorForAction(_ action: String) -> Color {
        switch action {
        case "添加": return .green
        case "编辑": return .blue
        case "删除": return .red
        case "移动": return .purple
        case "状态变更": return .orange
        default: return .gray
        }
    }
}

#Preview {
    NavigationStack {
        ActivityLogView()
    }
}
