// file: Views/Preview/PreviewWindowView.swift

import SwiftUI
import MarkdownUI
import UniformTypeIdentifiers // <-- 1. 导入 UniformTypeIdentifiers

@available(macOS 14.0, *)
struct PreviewWindowView: View {
  let itemId: String
  
  @EnvironmentObject private var viewModel: ClipboardViewModel
  @Environment(\.dismiss) private var dismiss
  
  private var item: ClipboardItem? {
    if viewModel.selectedItemForEditing?.id == itemId {
      return viewModel.selectedItemForEditing
    }
    return viewModel.clipboardHistory.first { $0.id == itemId }
  }
  
  @State private var selectedMode: DisplayMode = .auto
  
  var body: some View {
    if let item = item {
      VStack(alignment: .leading, spacing: 12) {
        // --- HEADER ---
        if case .text = item.content {
          HStack(alignment: .center) {
            Picker("显示模式", selection: $selectedMode) {
              ForEach(DisplayMode.allCases) { mode in
                Image(systemName: mode.iconName)
                  .help(mode.name)
                  .tag(mode)
              }
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
            .onChange(of: selectedMode) {
              viewModel.updateDisplayMode(for: item, to: selectedMode)
            }
            Spacer()
          }
        }
        
        // --- CONTENT RENDERER ---
        Group {
          switch item.content {
          case .image(let nsImage, _):
            Image(nsImage: nsImage)
              .resizable()
              .scaledToFit()
              .frame(maxWidth: .infinity, maxHeight: .infinity)

          case .filePaths(let urls):
            // --- 2. 修改文件预览逻辑 ---
            if let firstUrl = urls.first {
                // 检查文件类型
                if let type = try? firstUrl.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier,
                   let utType = UTType(type),
                   utType.conforms(to: .pdf) {
                    // 如果是 PDF，使用我们新的、功能完善的 PDF 视图
                    PDFKitRepresentedView(url: firstUrl)
                } else {
                    // 对于其他所有文件类型，继续使用 QuickLook
                    EmbeddedQuickLookView(url: firstUrl)
                }
            } else {
              Text("无效的文件路径")
            }
            
          case .text:
            ContentRendererView(item: item)
          }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        // --- FOOTER ---
        HStack {
          Button("编辑条目...") {
            viewModel.selectItemForEditing(item)
            dismiss()
          }
          Spacer()
          Button("复制并关闭") {
            viewModel.copyToClipboard(item: item)
            dismiss()
          }.keyboardShortcut(.defaultAction)
        }
      }
      .padding()
      .onAppear {
        self.selectedMode = item.displayMode
      }
      .onChange(of: item) {
        self.selectedMode = item.displayMode
      }
    } else {
      Text("项目已被删除。")
        .font(.title)
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
          DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismiss()
          }
        }
    }
  }
}
