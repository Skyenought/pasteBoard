// file: Views/QuickSelect/QuickSelectView.swift

import SwiftUI

struct QuickSelectView: View {
    @EnvironmentObject private var viewModel: ClipboardViewModel
    @Environment(\.colorScheme) private var colorScheme // 确保颜色模式可用

    // 回调，当用户选择并粘贴时调用
    let onSelectAndPaste: (ClipboardItem) -> Void
    // 回调，当用户取消时调用
    let onDismiss: () -> Void

    @State private var selectedIndex: Int = 0 // 当前选中的索引
    private let displayLimit = 15 // 最多显示多少条记录

    var body: some View {
        VStack(spacing: 0) {
            Text("快速粘贴")
                .font(.headline)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            List {
                // 使用 indices 确保即使 viewModel.clipboardHistory 变为空也不会崩溃
                ForEach(viewModel.clipboardHistory.prefix(displayLimit).indices, id: \.self) { index in
                    let item = viewModel.clipboardHistory[index]
                    VStack(alignment: .leading) {
                        Text(item.listPreviewText)
                            .lineLimit(1)
                            .font(.body)
                            .foregroundColor(index == selectedIndex ? .white : .primary)
                        Text(viewModel.formattedDate(from: item.date))
                            .font(.caption)
                            .foregroundColor(index == selectedIndex ? .white.opacity(0.8) : .secondary)
                    }
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(index == selectedIndex ? Color.accentColor : Color.clear)
                    .cornerRadius(4)
                    .onTapGesture {
                        selectedIndex = index // 允许鼠标点击选择
                        // NEW: 如果点击了有效项，触发选择并粘贴回调
                        if !viewModel.clipboardHistory.isEmpty && selectedIndex < viewModel.clipboardHistory.count {
                            let selectedItem = viewModel.clipboardHistory[selectedIndex]
                            onSelectAndPaste(selectedItem)
                        } else {
                            // 如果列表为空或索引无效，按回车也算作取消
                            onDismiss()
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .background(Color(nsColor: .textBackgroundColor)) // 浮动窗口背景色
        .cornerRadius(10)
        .shadow(radius: 10)
        .onAppear {
            // 在视图出现时，确保选中第一个项目 (如果列表不为空)
            if !viewModel.clipboardHistory.isEmpty {
                selectedIndex = 0
            }
        }
        // 键盘事件处理
        .onMoveCommand { direction in
            handleMove(direction: direction)
        }
        // FIX: 使用隐藏的 Button 来承载 keyboardShortcut，以避免编译错误并确保兼容性
        .background {
            Button("") { // 隐藏的按钮用于处理 ESC 键
                onDismiss()
            }
            .keyboardShortcut(.escape)
            .hidden() // 使按钮不可见
        }
        .background {
            Button("") { // 隐藏的按钮用于处理 Enter 键
                if !viewModel.clipboardHistory.isEmpty && selectedIndex < viewModel.clipboardHistory.count {
                    let selectedItem = viewModel.clipboardHistory[selectedIndex]
                    onSelectAndPaste(selectedItem)
                } else {
                    // 如果列表为空或者索引无效，按回车也算作取消
                    onDismiss()
                }
            }
            .keyboardShortcut(.return)
            .hidden() // 使按钮不可见
        }
    }

    private func handleMove(direction: MoveCommandDirection) {
        guard !viewModel.clipboardHistory.isEmpty else { return }

        switch direction {
        case .up:
            selectedIndex = max(0, selectedIndex - 1)
        case .down:
            // 确保不会超出实际可用项目数量（或 displayLimit 限制）
            selectedIndex = min(min(displayLimit - 1, viewModel.clipboardHistory.count - 1), selectedIndex + 1)
        default:
            break
        }
    }
}
