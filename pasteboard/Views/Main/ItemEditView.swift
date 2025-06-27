//
//  ItemEditView.swift
//  pasteboard
//
//  Created by jiun Lee on 6/21/25.
//

import SwiftUI

// ==========================================================
// Item Editing View
// ==========================================================

struct ItemEditView: View {
  @State var item: ClipboardItem
  
  @EnvironmentObject private var viewModel: ClipboardViewModel
  @Environment(\.colorScheme) private var colorScheme
  @State private var customTitle: String
  @State private var tags: [Tag]
  
  init(item: ClipboardItem) {
    _item = State(initialValue: item)
    _customTitle = State(initialValue: item.customTitle ?? "")
    _tags = State(initialValue: item.tags)
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Button(action: { saveChanges(); viewModel.exitEditingMode() }) {
          Label { Text("完成") } icon: { Image(systemName: "chevron.left") }
        }
        Spacer()
        Text("编辑条目").font(.headline)
        Spacer()
        Button(action: { item.isFavorite.toggle() }) {
          Image(systemName: item.isFavorite ? "star.fill" : "star").font(.title2).foregroundColor(item.isFavorite ? .yellow : .secondary)
        }.buttonStyle(BorderlessButtonStyle())
      }
      .padding(.bottom, 8)
      .padding(.bottom, 8)
      
      Group {
          ContentRendererView(item: item)
      }
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
      .frame(maxHeight: .infinity)
      
      VStack(alignment: .leading, spacing: 10) {
        TextField("自定义标题 (可选)", text: $customTitle).textFieldStyle(RoundedBorderTextFieldStyle()).font(.title2)
        
        Picker("显示模式", selection: $item.displayMode) {
          ForEach(DisplayMode.allCases) { mode in Text(mode.name).tag(mode) }
        }
        .pickerStyle(.segmented)
        
        VStack(alignment: .leading) {
          Text("标签:").font(.subheadline).foregroundColor(.secondary)
          TagEditorView(tags: $tags, allTags: viewModel.allTags)
        }
      }.padding(.top)
    }
    .padding().onDisappear(perform: saveChanges)
  }
  
  private func saveChanges() {
    viewModel.updateDisplayMode(for: item, to: item.displayMode)
    viewModel.toggleFavorite(for: item)
    viewModel.updateCustomTitle(for: item, title: customTitle)
    viewModel.updateTags(for: item, tags: tags)
  }
}
