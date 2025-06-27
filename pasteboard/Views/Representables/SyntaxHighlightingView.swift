// file: SyntaxHighlightingView.swift
import SwiftUI
import Highlightr

struct SyntaxHighlightingView: NSViewRepresentable {
  // The text to display
  let text: String
  // The theme name (e.g., "xcode", "xcode-dusk")
  let theme: String
  
  // Create the AppKit view
  func makeNSView(context: Context) -> NSScrollView {
    // 1. Initialize Highlightr
    // Using `nil` for the highlightView will make it use a default NSTextStorage.
    guard let highlightr = Highlightr() else {
      // If Highlightr fails to initialize, return a plain text view as a fallback.
      return createFallbackScrollView(with: text)
    }
    
    // 2. Configure Highlightr
    highlightr.setTheme(to: theme)
    
    // 3. Highlight the code.
    // `fastRender` is true, `as` is nil for auto-detection of language.
    let highlightedCode = highlightr.highlight(text, as: nil, fastRender: true)
    
    // 4. Create and configure the NSTextView
    let textView = NSTextView()
    textView.isEditable = false
    textView.isSelectable = true
    // Use the attributed string from Highlightr
    textView.textStorage?.setAttributedString(highlightedCode ?? NSAttributedString(string: text))
    textView.backgroundColor = highlightr.theme.themeBackgroundColor
    textView.textContainerInset = NSSize(width: 10, height: 10)
    textView.autoresizingMask = [.width]
    textView.isVerticallyResizable = true
    
    // 5. Create a scroll view to contain the text view
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.documentView = textView
    scrollView.drawsBackground = true
    scrollView.backgroundColor = highlightr.theme.themeBackgroundColor
    
    // Store highlightr instance and theme name in the coordinator
    context.coordinator.highlightr = highlightr
    context.coordinator.currentTheme = theme
    
    return scrollView
  }
  
  // Update the AppKit view when SwiftUI state changes
  func updateNSView(_ nsView: NSScrollView, context: Context) {
    guard let textView = nsView.documentView as? NSTextView,
          let highlightr = context.coordinator.highlightr else {
      return
    }
    
    // Only update if text or theme has changed
    if textView.string != text || context.coordinator.currentTheme != theme {
      highlightr.setTheme(to: theme)
      let highlightedCode = highlightr.highlight(text, as: nil, fastRender: true)
      
      textView.textStorage?.setAttributedString(highlightedCode ?? NSAttributedString(string: text))
      textView.backgroundColor = highlightr.theme.themeBackgroundColor
      nsView.backgroundColor = highlightr.theme.themeBackgroundColor
      
      // Update the stored theme name
      context.coordinator.currentTheme = theme
    }
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator()
  }
  
  // Coordinator to hold references and state
  class Coordinator {
    var highlightr: Highlightr?
    var currentTheme: String?
  }
  
  // A helper to create a non-highlighted view if Highlightr fails
  private func createFallbackScrollView(with text: String) -> NSScrollView {
    let textView = NSTextView()
    textView.string = text
    textView.isEditable = false
    textView.isSelectable = true
    textView.backgroundColor = .clear
    textView.textContainerInset = NSSize(width: 5, height: 10)
    
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true
    scrollView.documentView = textView
    scrollView.drawsBackground = false
    return scrollView
  }
}
