//
//  ProductLookupService.swift
//  HomeNest
//
//  Created by Paul Dexin Gong on 2026/7/27.
//

import Foundation

/// 产品查询结果
struct ProductInfo: Decodable {
    let name: String?
    let category: String?
    let brand: String?

    enum CodingKeys: String, CodingKey {
        case name = "product_name"
        case category = "categories_tags"
        case brand = "brands"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)

        // categories_tags 是数组，取第一个
        if let tags = try container.decodeIfPresent([String].self, forKey: .category) {
            category = tags.first?
                .replacingOccurrences(of: "en:", with: "")
                .replacingOccurrences(of: "zh:", with: "")
                .capitalized
        } else {
            category = nil
        }

        brand = try container.decodeIfPresent(String.self, forKey: .brand)
    }
}

/// Open Food Facts API 响应
private struct OFFResponse: Decodable {
    let product: ProductInfo?
}

/// 条形码产品查询服务
final class ProductLookupService {
    static let shared = ProductLookupService()

    /// 根据条形码查询产品信息
    func lookup(barcode: String) async -> ProductInfo? {
        // 先尝试 v3 API
        if let result = await tryLookup(apiVersion: "v3", barcode: barcode) {
            return result
        }
        // 回退到 v2
        return await tryLookup(apiVersion: "v2", barcode: barcode)
    }

    private func tryLookup(apiVersion: String, barcode: String) async -> ProductInfo? {
        let urlString = "https://world.openfoodfacts.org/api/\(apiVersion)/product/\(barcode).json"
        guard let url = URL(string: urlString) else { return nil }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        let session = URLSession(configuration: config)

        do {
            let (data, response) = try await session.data(from: url)

            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 \(apiVersion) API 状态码: \(httpResponse.statusCode)")
            }

            // 打印原始 JSON 用于调试
            if let jsonString = String(data: data, encoding: .utf8) {
                let preview = String(jsonString.prefix(500))
                print("🔍 \(apiVersion) 响应: \(preview)")
            }

            let offResponse = try JSONDecoder().decode(OFFResponse.self, from: data)

            if let product = offResponse.product {
                print("🔍 查询成功: \(product.name ?? "nil") | \(product.brand ?? "nil") | \(product.category ?? "nil")")
                return product
            } else {
                print("🔍 该条码未收录于 Open Food Facts")
                return nil
            }
        } catch {
            print("🔍 \(apiVersion) 查询失败: \(error.localizedDescription)")
            return nil
        }
    }

    /// 将 Open Food Facts 分类映射到 HomeNest 的分类
    func mapToHomeNestCategory(_ offCategory: String?) -> String? {
        guard let cat = offCategory?.lowercased() else { return nil }

        if cat.contains("food") || cat.contains("beverage") || cat.contains("snack") ||
           cat.contains("dairy") || cat.contains("meat") || cat.contains("fruit") ||
           cat.contains("vegetable") || cat.contains("drink") {
            return "食品"
        }
        if cat.contains("cleaning") || cat.contains("household") || cat.contains("detergent") {
            return "厨房"
        }
        if cat.contains("electronic") || cat.contains("appliance") {
            return "家电"
        }
        if cat.contains("book") || cat.contains("magazine") {
            return "书籍"
        }
        if cat.contains("clothing") || cat.contains("apparel") || cat.contains("shoe") {
            return "衣物"
        }
        if cat.contains("tool") || cat.contains("hardware") {
            return "工具"
        }
        if cat.contains("decoration") || cat.contains("furniture") {
            return "装饰"
        }
        return "其他"
    }

    /// 根据条形码前缀推断产地和国家
    struct BarcodeInfo {
        let country: String
        let isLocal: Bool   // 是否国产
        let categoryHint: String?
    }

    func decodeBarcode(_ code: String) -> BarcodeInfo {
        guard code.count >= 3 else {
            return BarcodeInfo(country: "未知", isLocal: false, categoryHint: nil)
        }
        let prefix = String(code.prefix(3))

        // GS1 前缀 → 国家/地区
        switch prefix {
        case "690", "691", "692", "693", "694", "695", "696", "697":
            return BarcodeInfo(country: "中国", isLocal: true, categoryHint: nil)
        case "300"..."379":  return BarcodeInfo(country: "法国", isLocal: false, categoryHint: "食品")
        case "400"..."440":  return BarcodeInfo(country: "德国", isLocal: false, categoryHint: "食品")
        case "450"..."459", "490"..."499":
            return BarcodeInfo(country: "日本", isLocal: false, categoryHint: "食品")
        case "460"..."469":  return BarcodeInfo(country: "俄罗斯", isLocal: false, categoryHint: "食品")
        case "471":          return BarcodeInfo(country: "台湾", isLocal: true, categoryHint: "食品")
        case "480":          return BarcodeInfo(country: "菲律宾", isLocal: false, categoryHint: "食品")
        case "481"..."499":  return BarcodeInfo(country: "香港", isLocal: true, categoryHint: nil)
        case "500"..."509":  return BarcodeInfo(country: "英国", isLocal: false, categoryHint: "食品")
        case "539":          return BarcodeInfo(country: "爱尔兰", isLocal: false, categoryHint: "食品")
        case "560":          return BarcodeInfo(country: "葡萄牙", isLocal: false, categoryHint: "食品")
        case "569":          return BarcodeInfo(country: "冰岛", isLocal: false, categoryHint: "食品")
        case "570"..."579":  return BarcodeInfo(country: "丹麦", isLocal: false, categoryHint: "食品")
        case "590":          return BarcodeInfo(country: "波兰", isLocal: false, categoryHint: "食品")
        case "600"..."601":  return BarcodeInfo(country: "南非", isLocal: false, categoryHint: "食品")
        case "609":          return BarcodeInfo(country: "毛里求斯", isLocal: false, categoryHint: "食品")
        case "611":          return BarcodeInfo(country: "摩洛哥", isLocal: false, categoryHint: "食品")
        case "613":          return BarcodeInfo(country: "阿尔及利亚", isLocal: false, categoryHint: "食品")
        case "619":          return BarcodeInfo(country: "突尼斯", isLocal: false, categoryHint: "食品")
        case "621":          return BarcodeInfo(country: "叙利亚", isLocal: false, categoryHint: "食品")
        case "622":          return BarcodeInfo(country: "埃及", isLocal: false, categoryHint: "食品")
        case "625":          return BarcodeInfo(country: "约旦", isLocal: false, categoryHint: "食品")
        case "626":          return BarcodeInfo(country: "伊朗", isLocal: false, categoryHint: "食品")
        case "640"..."649":  return BarcodeInfo(country: "芬兰", isLocal: false, categoryHint: "食品")
        case "690"..."699":  return BarcodeInfo(country: "中国", isLocal: true, categoryHint: nil)
        case "700"..."709":  return BarcodeInfo(country: "挪威", isLocal: false, categoryHint: "食品")
        case "729":          return BarcodeInfo(country: "以色列", isLocal: false, categoryHint: "食品")
        case "730"..."739":  return BarcodeInfo(country: "瑞典", isLocal: false, categoryHint: "食品")
        case "740"..."745":  return BarcodeInfo(country: "中南美洲", isLocal: false, categoryHint: "食品")
        case "750":          return BarcodeInfo(country: "墨西哥", isLocal: false, categoryHint: "食品")
        case "754"..."755":  return BarcodeInfo(country: "加拿大", isLocal: false, categoryHint: "食品")
        case "759":          return BarcodeInfo(country: "委内瑞拉", isLocal: false, categoryHint: "食品")
        case "760"..."769":  return BarcodeInfo(country: "瑞士", isLocal: false, categoryHint: "食品")
        case "770"..."771":  return BarcodeInfo(country: "哥伦比亚", isLocal: false, categoryHint: "食品")
        case "773":          return BarcodeInfo(country: "乌拉圭", isLocal: false, categoryHint: "食品")
        case "775":          return BarcodeInfo(country: "秘鲁", isLocal: false, categoryHint: "食品")
        case "777":          return BarcodeInfo(country: "玻利维亚", isLocal: false, categoryHint: "食品")
        case "779":          return BarcodeInfo(country: "阿根廷", isLocal: false, categoryHint: "食品")
        case "780":          return BarcodeInfo(country: "智利", isLocal: false, categoryHint: "食品")
        case "784":          return BarcodeInfo(country: "巴拉圭", isLocal: false, categoryHint: "食品")
        case "786":          return BarcodeInfo(country: "厄瓜多尔", isLocal: false, categoryHint: "食品")
        case "789"..."790":  return BarcodeInfo(country: "巴西", isLocal: false, categoryHint: "食品")
        case "800"..."839":  return BarcodeInfo(country: "意大利", isLocal: false, categoryHint: "食品")
        case "840"..."849":  return BarcodeInfo(country: "西班牙", isLocal: false, categoryHint: "食品")
        case "850":          return BarcodeInfo(country: "古巴", isLocal: false, categoryHint: "食品")
        case "858":          return BarcodeInfo(country: "斯洛伐克", isLocal: false, categoryHint: "食品")
        case "859":          return BarcodeInfo(country: "捷克", isLocal: false, categoryHint: "食品")
        case "860":          return BarcodeInfo(country: "南斯拉夫", isLocal: false, categoryHint: "食品")
        case "867":          return BarcodeInfo(country: "朝鲜", isLocal: false, categoryHint: "食品")
        case "869":          return BarcodeInfo(country: "土耳其", isLocal: false, categoryHint: "食品")
        case "870"..."879":  return BarcodeInfo(country: "荷兰", isLocal: false, categoryHint: "食品")
        case "880":          return BarcodeInfo(country: "韩国", isLocal: false, categoryHint: "食品")
        case "884":          return BarcodeInfo(country: "柬埔寨", isLocal: false, categoryHint: "食品")
        case "885":          return BarcodeInfo(country: "泰国", isLocal: false, categoryHint: "食品")
        case "888":          return BarcodeInfo(country: "新加坡", isLocal: false, categoryHint: "食品")
        case "890":          return BarcodeInfo(country: "印度", isLocal: false, categoryHint: "食品")
        case "893":          return BarcodeInfo(country: "越南", isLocal: false, categoryHint: "食品")
        case "899":          return BarcodeInfo(country: "印度尼西亚", isLocal: false, categoryHint: "食品")
        case "900"..."919":  return BarcodeInfo(country: "奥地利", isLocal: false, categoryHint: "食品")
        case "930"..."939":  return BarcodeInfo(country: "澳大利亚", isLocal: false, categoryHint: "食品")
        case "940"..."949":  return BarcodeInfo(country: "新西兰", isLocal: false, categoryHint: "食品")
        case "955":          return BarcodeInfo(country: "马来西亚", isLocal: false, categoryHint: "食品")
        case "958":          return BarcodeInfo(country: "澳门", isLocal: true, categoryHint: "食品")
        default:
            return BarcodeInfo(country: "国际通用", isLocal: false, categoryHint: nil)
        }
    }
}
