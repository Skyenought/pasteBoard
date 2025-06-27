// file: PerformantTextView.swift
import SwiftUI

struct PerformantTextView: NSViewRepresentable {
  // 将要显示的文本内容
  let text: String
  
  // 创建底层的 AppKit 视图
  func makeNSView(context: Context) -> NSScrollView {
    // 1. 创建文本视图本身
    let textView = NSTextView()
    textView.string = text
    textView.isEditable = false // 只读
    textView.isSelectable = true // 允许用户选择和复制
    textView.backgroundColor = .clear // 背景透明，以适应浅色/深色模式
    textView.textContainerInset = NSSize(width: 5, height: 10) // 设置内边距
    textView.autoresizingMask = [.width] // 宽度自动适应父视图
    textView.isVerticallyResizable = true // 高度可变
    
    // 2. 创建一个滚动视图来容纳文本视图
    let scrollView = NSScrollView()
    scrollView.hasVerticalScroller = true // 显示垂直滚动条
    scrollView.documentView = textView // 将文本视图放入滚动视图
    scrollView.drawsBackground = false // 滚动视图本身不绘制背景
    
    return scrollView
  }
  
  // 当 SwiftUI 的状态变化时，更新 AppKit 视图
  func updateNSView(_ nsView: NSScrollView, context: Context) {
    // 确保 documentView 是 NSTextView 类型
    guard let textView = nsView.documentView as? NSTextView else {
      return
    }
    
    // 如果外部传入的文本与当前显示的文本不同，则更新
    if textView.string != text {
      textView.string = text
    }
  }
}

