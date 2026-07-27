//
//  InsuranceReportView.swift
//  HomeNest
//

import SwiftUI
import SwiftData
import UIKit
import WebKit

struct InsuranceReportView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var items: [InsuranceReportGenerator.ReportItem] = []
    @State private var minValue: Double = 0
    @State private var htmlContent = ""
    @State private var isGenerating = false
    @State private var showShareSheet = false
    @State private var pdfData: Data?

    var body: some View {
        VStack(spacing: 0) {
            // 筛选栏
            HStack {
                Text("最低价值:")
                    .font(.subheadline)
                TextField("0", value: $minValue, format: .number)
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
                Text("¥")
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: generateReport) {
                    Label("生成报告", systemImage: "doc.richtext")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating)
            }
            .padding()

            // 预览区
            if isGenerating {
                ProgressView("生成中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !htmlContent.isEmpty {
                WebView(html: htmlContent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("设置最低价值门槛，点击生成报告预览")
                        .foregroundColor(.secondary)
                    Text("将筛选出价值 ≥ \(Int(minValue)) 元的物品")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("保险清单")
        .toolbar {
            if !htmlContent.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: exportPDF) {
                        Label("导出 PDF", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = pdfData {
                ShareSheet(items: [data])
            }
        }
    }

    private func generateReport() {
        isGenerating = true
        items = InsuranceReportGenerator.collectItems(from: modelContext, minValue: minValue)
        if items.isEmpty {
            htmlContent = "<p style='text-align:center;color:#6c757d;padding:40px;'>暂无符合条件的有价值物品</p>"
        } else {
            htmlContent = InsuranceReportGenerator.generateHTML(items: items)
        }
        isGenerating = false
    }

    private func exportPDF() {
        items = InsuranceReportGenerator.collectItems(from: modelContext, minValue: minValue)
        let html = InsuranceReportGenerator.generateHTML(items: items)
        pdfData = generatePDFData(from: html)
        showShareSheet = true
    }

    private func generatePDFData(from html: String) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            let printFormatter = UIMarkupTextPrintFormatter(markupText: html)
            printFormatter.perPageContentInsets = UIEdgeInsets(top: 36, left: 36, bottom: 36, right: 36)
            printFormatter.maximumContentWidth = pageRect.width - 72

            let pageRenderer = UIPrintPageRenderer()
            pageRenderer.addPrintFormatter(printFormatter, startingAtPageAt: 0)

            let printable = CGRect(origin: .zero, size: pageRect.size)
            pageRenderer.setValue(NSValue(cgRect: printable), forKey: "paperRect")
            pageRenderer.setValue(NSValue(cgRect: printable), forKey: "printableRect")

            for i in 0..<pageRenderer.numberOfPages {
                context.beginPage()
                pageRenderer.drawPage(at: i, in: context.pdfContextBounds)
            }
        }
    }
}

// WebView wrapper for HTML preview
struct WebView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}

#Preview {
    NavigationStack {
        InsuranceReportView()
    }
}
