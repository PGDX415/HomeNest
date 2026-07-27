//
//  InsuranceReportGenerator.swift
//  HomeNest
//

import SwiftUI
import SwiftData

/// 保险清单报告生成器
struct InsuranceReportGenerator {

    struct ReportItem: Identifiable {
        let id: String
        let name: String
        let quantity: Int
        let value: Double
        let category: String
        let location: String
        let purchaseDate: String
        let photoData: Data?
        let hasWarranty: Bool
    }

    static func collectItems(from context: ModelContext, minValue: Double = 0) -> [ReportItem] {
        let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.value, order: .reverse)])
        guard let allItems = try? context.fetch(descriptor) else { return [] }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return allItems
            .filter { ($0.value ?? 0) >= max(minValue, 0) }
            .map { item in
                ReportItem(
                    id: item.persistentModelID.hashValue.description,
                    name: item.name,
                    quantity: item.quantity,
                    value: item.value ?? 0,
                    category: item.category ?? "未分类",
                    location: item.location?.name ?? "未知",
                    purchaseDate: item.purchaseDate.map { dateFormatter.string(from: $0) } ?? "-",
                    photoData: item.photoData,
                    hasWarranty: item.warrantyEndDate != nil
                )
            }
    }

    static func totalValue(_ items: [ReportItem]) -> Double {
        items.reduce(0) { $0 + $1.value * Double($1.quantity) }
    }

    static func generateHTML(items: [ReportItem], title: String = "家庭物品保险清单") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .none
        let reportDate = dateFormatter.string(from: Date())
        let totalVal = totalValue(items)

        var rows = ""
        for (index, item) in items.enumerated() {
            let rowBg = index % 2 == 0 ? "#ffffff" : "#f8f9fa"
            let warrantyBadge = item.hasWarranty ? "<span style='color:#198754;font-size:12px;'>🛡️</span>" : ""
            rows += """
            <tr style="background-color:\(rowBg);">
                <td style="padding:6px 10px;border-bottom:1px solid #dee2e6;">\(index + 1)</td>
                <td style="padding:6px 10px;border-bottom:1px solid #dee2e6;font-weight:500;">\(escapeHTML(item.name))</td>
                <td style="padding:6px 10px;border-bottom:1px solid #dee2e6;text-align:center;">\(item.quantity)</td>
                <td style="padding:6px 10px;border-bottom:1px solid #dee2e6;">\(item.category)</td>
                <td style="padding:6px 10px;border-bottom:1px solid #dee2e6;">\(item.location)</td>
                <td style="padding:6px 10px;border-bottom:1px solid #dee2e6;white-space:nowrap;">\(item.purchaseDate)</td>
                <td style="padding:6px 10px;border-bottom:1px solid #dee2e6;text-align:right;font-family:monospace;">¥\(String(format: "%.0f", item.value))</td>
                <td style="padding:6px 10px;border-bottom:1px solid #dee2e6;text-align:center;">\(warrantyBadge)</td>
            </tr>
            """
        }

        return """
        <!DOCTYPE html>
        <html lang="zh-CN">
        <head><meta charset="UTF-8">
        <style>
            body { font-family: -apple-system, "PingFang SC", sans-serif; margin: 16px; color: #212529; }
            .header { text-align: center; padding: 16px 0 10px 0; border-bottom: 2px solid #0d6efd; margin-bottom: 16px; }
            .header h1 { color: #0d6efd; margin: 0; font-size: 22px; }
            .header p { color: #6c757d; margin: 4px 0 0 0; font-size: 12px; }
            table { width: 100%; border-collapse: collapse; font-size: 12px; }
            th { background-color: #0d6efd; color: white; padding: 8px 10px; text-align: left; font-size: 11px; }
            .footer { text-align: center; color: #adb5bd; font-size: 10px; padding: 16px 0; border-top: 1px solid #dee2e6; margin-top: 24px; }
        </style></head>
        <body>
        <div class="header"><h1>🏠 \(title)</h1>
        <p>生成日期: \(reportDate) | 共 \(items.count) 件物品</p></div>
        <table>
        <thead><tr>
        <th style="width:5%;">#</th><th style="width:25%;">名称</th>
        <th style="width:7%;text-align:center;">数量</th><th style="width:12%;">分类</th>
        <th style="width:12%;">位置</th><th style="width:12%;">购买日</th>
        <th style="width:12%;text-align:right;">单价 ¥</th><th style="width:7%;text-align:center;">保修</th>
        </tr></thead><tbody>\(rows)</tbody>
        <tfoot><tr style="background-color:#e9ecef;font-weight:bold;">
        <td colspan="6" style="padding:8px 10px;text-align:right;border-top:2px solid #adb5bd;">总价值</td>
        <td style="padding:8px 10px;text-align:right;font-family:monospace;border-top:2px solid #adb5bd;">¥\(String(format: "%.0f", totalVal))</td>
        <td style="padding:8px 10px;border-top:2px solid #adb5bd;"></td>
        </tr></tfoot></table>
        <div class="footer">HomeNest 家物管 · 仅供保险理赔参考</div>
        </body></html>
        """
    }

    private static func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
