// file: TagManagementView.swift

import SwiftUI

struct TagManagementView: View {
    @EnvironmentObject private var viewModel: ClipboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isShowingAddAlert = false
    @State private var newTagName: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. Header with Add button
            HStack {
                Text("标签管理")
                    .font(.title2).bold()
                
                Spacer()
                
                Button {
                    newTagName = ""
                    isShowingAddAlert = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .imageScale(.large)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .help("添加新标签")
                
                Button("完成") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction) // Allows Enter key to dismiss
            }
            .padding()
            .background(.regularMaterial)
            
            Divider()
            
            // 2. Custom scrollable list of tags
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.allTags) { tag in
                        TagManagementRow(tag: tag)
                    }
                }
                .padding()
            }
            .onAppear {
                Task { await viewModel.loadAllTags() }
            }
        }
        .alert("删除失败", isPresented: $viewModel.isShowingTagDeletionErrorAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(viewModel.tagDeletionError ?? "无法删除标签。")
        }
        .alert("添加新标签", isPresented: $isShowingAddAlert) {
            TextField("标签名", text: $newTagName)
            Button("添加") {
                Task { await viewModel.addTag(name: newTagName) }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("请输入新标签的名称。")
        }
    }
}

// ==========================================================
// Beautified Tag Management Row
// ==========================================================
struct TagManagementRow: View {
    let tag: Tag
    @EnvironmentObject private var viewModel: ClipboardViewModel
    
    @State private var isHovering = false
    @State private var isShowingRenameAlert = false
    @State private var isShowingDeleteConfirm = false
    @State private var tagNameForRename: String = ""
    
    var body: some View {
        HStack {
            Image(systemName: "tag.fill")
                .font(.title3)
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            Text(tag.name)
                .font(.body)
                .lineLimit(1)
            
            Spacer()
            
            // Action buttons appear on hover
            if isHovering {
                HStack(spacing: 12) {
                    Button {
                        tagNameForRename = tag.name
                        isShowingRenameAlert = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("重命名")
                    
                    // <<-- CHANGED: Delete button now checks for Option key
                    Button {
                        // Check for the Option key modifier
                        if NSEvent.modifierFlags.contains(.option) {
                            // Force delete without confirmation
                            Task { await viewModel.deleteTag(tag) }
                        } else {
                            // Show confirmation alert
                            isShowingDeleteConfirm = true
                        }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("删除 (按住 ⌥ 键可直接删除)")
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHovering ? Color.secondary.opacity(0.15) : Color.secondary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                self.isHovering = hovering
            }
        }
        .alert("确认删除标签 \"\(tag.name)\"?", isPresented: $isShowingDeleteConfirm) {
            Button("删除", role: .destructive) {
                Task { await viewModel.deleteTag(tag) }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作无法撤销。")
        }
        .alert("重命名标签", isPresented: $isShowingRenameAlert) {
            TextField("新标签名", text: $tagNameForRename)
            Button("保存") {
                Task { await viewModel.renameTag(tag, to: tagNameForRename) }
            }
            Button("取消", role: .cancel) {}
        }
    }
}

#Preview {
    // This allows you to preview the sheet in isolation
    let vm = ClipboardViewModel()
    // Add some dummy data for preview
    vm.allTags = [Tag(id: 1, name: "swiftui"), Tag(id: 2, name: "bug-report"), Tag(id: 3, name: "feature-request-long-name-to-test-truncation")]
    
    return TagManagementView()
        .environmentObject(vm)
        .frame(width: 450, height: 500)
}
