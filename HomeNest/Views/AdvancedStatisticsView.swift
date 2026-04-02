//
//  AdvancedStatisticsView.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/4/2.
//

import SwiftUI
import SwiftData
import Charts

struct AdvancedStatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTab: StatisticsTab = .distribution
    @State private var categoryDistribution: [CategoryDistribution] = []
    @State private var homeDistribution: [HomeDistribution] = []
    @State private var timeDistribution: [TimeDistribution] = []
    @State private var storageAnalysis: [StorageAnalysis] = []
    @State private var itemHistory: [ItemHistory] = []
    
    enum StatisticsTab: String, CaseIterable {
        case distribution = "物品分布"
        case storage = "存储分析"
        case history = "历史记录"
        
        var displayName: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // 分段控件
                Picker("统计类型", selection: $selectedTab) {
                    ForEach(StatisticsTab.allCases, id: \.self) { tab in
                        Text(tab.displayName).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // 根据选择显示不同内容
                switch selectedTab {
                case .distribution:
                    DistributionView(
                        categoryDistribution: categoryDistribution,
                        homeDistribution: homeDistribution,
                        timeDistribution: timeDistribution
                    )
                case .storage:
                    StorageAnalysisView(storageAnalysis: storageAnalysis)
                case .history:
                    HistoryView(itemHistory: itemHistory)
                }
            }
            .navigationTitle("高级统计")
            .onAppear {
                loadAllStatistics()
            }
        }
    }
    
    private func loadAllStatistics() {
        categoryDistribution = AdvancedStatisticsManager.shared.getCategoryDistribution(context: modelContext)
        homeDistribution = AdvancedStatisticsManager.shared.getHomeDistribution(context: modelContext)
        timeDistribution = AdvancedStatisticsManager.shared.getTimeDistribution(context: modelContext)
        storageAnalysis = AdvancedStatisticsManager.shared.getStorageAnalysis(context: modelContext)
        itemHistory = AdvancedStatisticsManager.shared.getItemHistory(context: modelContext)
    }
}

// 物品分布视图
struct DistributionView: View {
    let categoryDistribution: [CategoryDistribution]
    let homeDistribution: [HomeDistribution]
    let timeDistribution: [TimeDistribution]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 分类分布
                if !categoryDistribution.isEmpty {
                    SectionHeaderView(title: "按分类分布")
                    CategoryChartView(distribution: categoryDistribution)
                }
                
                // 场所分布
                if !homeDistribution.isEmpty {
                    SectionHeaderView(title: "按场所分布")
                    HomeChartView(distribution: homeDistribution)
                }
                
                // 时间分布
                if !timeDistribution.isEmpty {
                    SectionHeaderView(title: "按时间分布")
                    TimeChartView(distribution: timeDistribution)
                }
            }
            .padding()
        }
    }
}

// 存储分析视图
struct StorageAnalysisView: View {
    let storageAnalysis: [StorageAnalysis]
    
    var body: some View {
        List {
            ForEach(storageAnalysis) { analysis in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(analysis.homeName)
                            .font(.headline)
                        Spacer()
                        Text("\(analysis.totalItems) 件物品")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // 容量使用进度条
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("容量使用率")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(analysis.capacityPercentage))%")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        ProgressView(value: analysis.capacityPercentage / 100)
                            .progressViewStyle(.linear)
                            .tint(.blue)
                    }
                    
                    // 位置统计
                    HStack {
                        Text("\(analysis.usedLocations)/\(analysis.totalLocations) 个位置已使用")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("存储分析")
    }
}

// 历史记录视图
struct HistoryView: View {
    let itemHistory: [ItemHistory]
    
    var body: some View {
        List {
            ForEach(itemHistory) { record in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.itemName)
                            .font(.body)
                        
                        if let location = record.locationName {
                            Text("位置: \(location)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(record.action)
                            .font(.caption)
                            .foregroundColor(record.action == "添加" ? .green : .orange)
                        
                        Text(record.timestamp.formatted(.dateTime.hour().minute().day().month()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("操作历史")
    }
}

// 图表视图组件
struct CategoryChartView: View {
    let distribution: [CategoryDistribution]
    
    var body: some View {
        Chart(distribution.prefix(10)) { item in
            BarMark(
                x: .value("数量", item.itemCount),
                y: .value("分类", item.category)
            )
            .foregroundStyle(.blue)
        }
        .frame(height: CGFloat(min(distribution.count * 30, 300)))

    }
}

struct HomeChartView: View {
    let distribution: [HomeDistribution]
    
    var body: some View {
        Chart(distribution.prefix(5)) { item in
            BarMark(
                x: .value("数量", item.itemCount),
                y: .value("场所", item.homeName)
            )
            .foregroundStyle(.green)
        }
        .frame(height: CGFloat(min(distribution.count * 30, 200)))

    }
}

struct TimeChartView: View {
    let distribution: [TimeDistribution]
    
    var body: some View {
        Chart(distribution) { item in
            BarMark(
                x: .value("时间段", item.period),
                y: .value("数量", item.itemCount)
            )
            .foregroundStyle(.orange)
        }
        .frame(height: 150)
    }
}

// 部分标题视图
struct SectionHeaderView: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
            Spacer()
        }
        .padding(.top)
    }
}

#Preview {
    AdvancedStatisticsView()
        .modelContainer(for: [Item.self, StorageLocation.self, Home.self, UserProfile.self], inMemory: true)
}