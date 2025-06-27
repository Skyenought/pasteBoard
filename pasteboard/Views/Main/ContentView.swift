// file: ContentView.swift
import SwiftUI
import AppKit
import MarkdownUI

// ==========================================================
// Main Entry View
// ==========================================================

struct ContentView: View {
  @EnvironmentObject private var viewModel: ClipboardViewModel
  @EnvironmentObject private var colorSchemeManager: ColorSchemeManager
  
  var body: some View {
    VStack(spacing: 0) {
      if let itemToEdit = viewModel.selectedItemForEditing {
        ItemEditView(item: itemToEdit)
      } else {
        MainListView()
      }
    }
    .onAppear { viewModel.activate() }
    .preferredColorScheme(colorSchemeManager.colorScheme.swiftUIScheme)
    .animation(.default, value: viewModel.selectedItemForEditing?.id)
  }
}

// ==========================================================
// Main List View
// ==========================================================

struct MainListView: View {
  @EnvironmentObject private var viewModel: ClipboardViewModel
  @EnvironmentObject private var colorSchemeManager: ColorSchemeManager
  @Environment(\.openWindow) private var openWindow
  @State private var showingClearAllConfirmation = false
  
  private var searchBar: some View {
    HStack {
      Image(systemName: "magnifyingglass").foregroundColor(.secondary)
      TextField("搜索标题、内容或标签...", text: $viewModel.searchText)
        .textFieldStyle(.plain)
      if !viewModel.searchText.isEmpty {
        Button(action: { viewModel.searchText = "" }) {
          Image(systemName: "xmark.circle.fill")
        }
        .buttonStyle(.borderless)
        .foregroundColor(.secondary)
      }
    }
    .padding(.horizontal, 8).padding(.vertical, 5)
    .background(Color(nsColor: .windowBackgroundColor))
    .cornerRadius(8)
    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
  }
  
  private var tagFilteringBar: some View {
    HStack(spacing: 12) {
      Button {
        viewModel.isShowingTagManagement = true
      } label: {
        Image(systemName: "gearshape")
      }
      .help("管理所有标签")
      .buttonStyle(.plain)
      
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 6) {
          if viewModel.selectedTag != nil {
            Button {
              viewModel.toggleTagSelection(nil)
            } label: {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .help("清除标签筛选")
          }
          ForEach(viewModel.allTags) { tag in
            TagFilterPillView(
              tag: tag,
              isSelected: viewModel.selectedTag == tag
            )
            .onTapGesture {
              viewModel.toggleTagSelection(tag)
            }
          }
        }
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .animation(.easeInOut, value: viewModel.selectedTag)
  }
  
  var body: some View {
    VStack(spacing: 0) {
      // Header Area
      VStack(spacing: 0) {
        searchBar.padding([.horizontal, .top])
        
        if !viewModel.allTags.isEmpty {
          tagFilteringBar
        } else {
          Spacer().frame(height: 38)
        }
      }
      
      Divider()
      
      // Main Content List
      List {
        ForEach(viewModel.clipboardHistory) { item in
          ClipboardRowView(item: item)
            .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
            .contentShape(Rectangle())
            .onTapGesture {
              openWindow(id: "preview-item", value: item.id)
            }
        }
      }
      .listStyle(.plain)
      
      // Footer Toolbar
      HStack {
        if viewModel.filterMode == .all && viewModel.searchText.isEmpty && viewModel.selectedTag == nil {
          Button(role: .destructive) { showingClearAllConfirmation = true }
          label: { Label("清空", systemImage: "trash.circle") }
            .help("清空所有非收藏条目")
            .alert("确认清空？", isPresented: $showingClearAllConfirmation) {
              Button("清空", role: .destructive) { viewModel.deleteAllNonFavorites() }
              Button("取消", role: .cancel) {}
            } message: { Text("此操作将删除所有未收藏的历史记录，且无法撤销。") }
        }
        
        // <<-- NEW: Date Filter Button View is added here
        DateFilterView()
        
        Spacer()
        
        HStack(spacing: 24) {
          Picker("筛选", selection: $viewModel.filterMode) {
            ForEach(FilterMode.allCases) { mode in
              Text(mode.rawValue).tag(mode)
            }
          }
          .pickerStyle(.segmented)
          .frame(width: 150)
          
          Picker("", selection: $colorSchemeManager.colorScheme) {
            ForEach(AppColorScheme.allCases) { scheme in
              Image(systemName: scheme.iconName)
                .help(scheme.rawValue)
                .tag(scheme)
            }
          }
          .pickerStyle(.segmented)
          .frame(width: 120)
        }
      }
      .padding(.horizontal).padding(.vertical, 10).background(.thinMaterial)
    }
    .sheet(isPresented: $viewModel.isShowingTagManagement) {
      TagManagementView()
        .environmentObject(viewModel)
        .frame(minWidth: 400, minHeight: 500)
    }
  }
}



