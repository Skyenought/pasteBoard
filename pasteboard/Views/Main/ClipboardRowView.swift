//
//  ClipboardRowView.swift
//  pasteboard
//
//  Created by jiun Lee on 6/21/25.
//

import SwiftUI

// ==========================================================
// Individual List Row
// ==========================================================

struct ClipboardRowView: View {
  let item: ClipboardItem
  
  @EnvironmentObject private var viewModel: ClipboardViewModel
  @State private var showingDeleteConfirmation = false
  @State private var isHovering = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      if let customTitle = item.customTitle, !customTitle.isEmpty {
        Text(customTitle).font(.headline).lineLimit(1).foregroundColor(.accentColor)
        Text(item.content.previewText).font(.subheadline).foregroundColor(.secondary).lineLimit(2)
      } else {
        Text(item.content.previewText).font(.body).lineLimit(3)
      }
      
      if !item.tags.isEmpty {
        HStack {
          ForEach(item.tags.prefix(5)) { tag in
            Text(tag.name).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
              .background(Color.secondary.opacity(0.2)).cornerRadius(5).lineLimit(1)
          }
        }.padding(.top, 2)
      }
      
      Spacer(minLength: 0)
      
      HStack {
        Text(viewModel.formattedDate(from: item.date)).font(.caption2).foregroundColor(.secondary)
        Spacer()
        Button(action: { viewModel.toggleFavorite(for: item) }) {
          Image(systemName: item.isFavorite ? "star.fill" : "star")
            .foregroundColor(item.isFavorite ? .yellow : .secondary)
        }.buttonStyle(BorderlessButtonStyle()).help("收藏")
        Button(action: { viewModel.copyToClipboard(item: item) }) {
          Image(systemName: "doc.on.doc").imageScale(.small)
        }.buttonStyle(BorderlessButtonStyle()).help("复制")
        Button(action: {
          if NSEvent.modifierFlags.contains(.option) { viewModel.deleteItem(with: item.id) }
          else { showingDeleteConfirmation = true }
        }) {
          Image(systemName: "trash").imageScale(.small).foregroundColor(.red)
        }.buttonStyle(BorderlessButtonStyle()).help("删除（按住⌥键可直接删除）")
          .alert("确认删除?", isPresented: $showingDeleteConfirmation) {
            Button("删除", role: .destructive) { viewModel.deleteItem(with: item.id) }
            Button("取消", role: .cancel) {}
          } message: { Text("你确定要删除这条历史吗？") }
      }
    }
    .padding(8)
    .frame(minHeight: 90)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(isHovering ? Color.primary.opacity(0.1) : Color.clear)
    )
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.1)) {
        self.isHovering = hovering
      }
    }
  }
}
