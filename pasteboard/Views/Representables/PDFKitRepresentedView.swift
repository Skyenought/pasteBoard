//
//  PDFKitRepresentedView.swift
//  pasteboard
//
//  Created by jiun Lee on 6/22/25.
//

import SwiftUI
import PDFKit

struct PDFKitRepresentedView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> PDFView {
        // 1. 创建 PDFView 实例
        let pdfView = PDFView()
        
        // 2. 尝试访问安全范围资源并加载 PDF 文档
        if context.coordinator.startAccessing(url) {
            pdfView.document = PDFDocument(url: url)
        }
        
        // 3. 配置 PDFView 的外观和行为
        pdfView.autoScales = true // 自动缩放以适应视图宽度
        pdfView.displayMode = .singlePageContinuous // 连续单页滚动模式，最适合此场景
        pdfView.backgroundColor = NSColor.textBackgroundColor // 确保背景色与主题匹配
        pdfView.displaysPageBreaks = true // 显示页面间的分隔符

        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        // 当 URL 发生变化时，更新文档
        guard nsView.document?.documentURL != url else {
            return
        }
        
        context.coordinator.stopAccessing()
        if context.coordinator.startAccessing(url) {
            nsView.document = PDFDocument(url: url)
        }
    }
    
    static func dismantleNSView(_ nsView: PDFView, coordinator: Coordinator) {
        // 视图被销毁时，停止访问资源
        coordinator.stopAccessing()
    }

    func makeCoordinator() -> Coordinator {
        // 复用处理安全范围资源的 Coordinator
        return Coordinator()
    }
    
    // Coordinator 的实现与 EmbeddedQuickLookView 中的完全相同
    class Coordinator {
        private var isAccessing: Bool = false
        private var currentURL: URL?

        func startAccessing(_ url: URL) -> Bool {
            stopAccessing()
            isAccessing = url.startAccessingSecurityScopedResource()
            if isAccessing {
                currentURL = url
            }
            return isAccessing
        }

        func stopAccessing() {
            if isAccessing {
                currentURL?.stopAccessingSecurityScopedResource()
                isAccessing = false
                currentURL = nil
            }
        }
    }
}
