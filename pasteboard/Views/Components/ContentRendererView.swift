//
//  ContentRendererView.swift
//  pasteboard
//
//  Created by jiun Lee on 6/21/25.
//

import SwiftUI
import MarkdownUI

struct ContentRendererView: View {
    let item: ClipboardItem
    
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // 使用 detailViewText 提供完整内容，previewText 作为备选
        let textToRender = item.content.detailViewText ?? item.content.previewText
        
        // 决定最终要使用的显示模式
        let effectiveMode = item.displayMode == .auto ? detectContentType(from: textToRender) : item.displayMode

        switch effectiveMode {
        case .markdown:
            ScrollView {
                Markdown(textToRender)
                    .markdownTheme(.gitHub)
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(nsColor: .textBackgroundColor))
        case .code:
            SyntaxHighlightingView(text: textToRender, theme: colorScheme == .dark ? "xcode-dusk" : "xcode")
        case .plain, .auto:
            PerformantTextView(text: textToRender)
        }
    }
}
