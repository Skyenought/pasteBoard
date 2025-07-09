// file: Windows/QuickSelectWindowController.swift

import SwiftUI
import AppKit
import Carbon.HIToolbox // For virtual key codes
import OSLog // For logging

@MainActor
class QuickSelectWindowController: NSObject {
    private var panel: NSPanel! // 使用 NSPanel 作为浮动窗口
    private var hostingView: NSHostingView<AnyView>?
    private var pasteTargetApplication: NSRunningApplication? // 存储粘贴的目标应用

    // NEW: 存储 ClipboardViewModel 的引用
    private weak var clipboardViewModel: ClipboardViewModel?

    override init() {
        super.init()
        setupPanel()
    }

    private func setupPanel() {
        // 创建一个无标题栏、浮动、并可以作为 KeyWindow 的面板
        // .nonactivatingPanel 意味着它不会激活自己的应用，从而可以保持焦点在之前的应用
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 300), // 初始大小，会被内容调整
            styleMask: [.borderless, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.level = .floating // 使其始终浮动在其他窗口之上
        panel.hidesOnDeactivate = true // 当失去焦点时自动隐藏
        panel.isFloatingPanel = true // 明确声明为浮动面板
        panel.hasShadow = true
        panel.backgroundColor = NSColor.clear // 背景透明，由 SwiftUI 视图控制
        panel.isOpaque = false // 允许透明效果
        panel.isMovableByWindowBackground = true // 允许通过背景拖动
        
        // canBecomeKey 和 canBecomeMain 是只读属性，它们的值由 styleMask 和面板的用途决定。
        // 对于 .nonactivatingPanel，通常它不会成为主窗口，但可以成为键窗口来接收键盘输入。
        // 无需手动设置这些属性，它们的默认行为对于浮动面板是合适的。
    }

    func showPanel(with viewModel: ClipboardViewModel, colorSchemeManager: ColorSchemeManager) {
        // NEW: 存储 ViewModel 引用
        self.clipboardViewModel = viewModel
        
        // 记录当前最前端的应用，以便后续粘贴后重新激活
        pasteTargetApplication = NSWorkspace.shared.frontmostApplication

        // 重新加载最新数据 (为了确保快速选择显示的是最新内容)
        Task { await viewModel.loadHistory(isLoadMore: false) }
        
        // 创建 SwiftUI 视图并设置到面板内容
        let rootView = QuickSelectView(
            onSelectAndPaste: { [weak self] item in
                self?.performPaste(item: item)
                self?.hidePanel()
            },
            onDismiss: { [weak self] in
                self?.hidePanel()
            }
        )
        .environmentObject(viewModel)
        .environmentObject(colorSchemeManager)
        .preferredColorScheme(colorSchemeManager.colorScheme.swiftUIScheme) // 应用全局颜色模式

        hostingView = NSHostingView(rootView: AnyView(rootView))
        hostingView?.translatesAutoresizingMaskIntoConstraints = false

        panel.contentView = hostingView
        
        // 设置 Auto Layout 约束
        if let hostedView = hostingView {
            NSLayoutConstraint.activate([
                hostedView.leadingAnchor.constraint(equalTo: panel.contentView!.leadingAnchor),
                hostedView.trailingAnchor.constraint(equalTo: panel.contentView!.trailingAnchor),
                hostedView.topAnchor.constraint(equalTo: panel.contentView!.topAnchor),
                hostedView.bottomAnchor.constraint(equalTo: panel.contentView!.bottomAnchor)
            ])
        }

        // 定位面板 (例如，居中显示)
        if let screenFrame = NSScreen.main?.visibleFrame {
            let panelWidth: CGFloat = 450 // 设定面板的宽度
            let panelHeight: CGFloat = min(screenFrame.height * 0.7, 600) // 限制最大高度
            panel.setFrame(NSRect(x: screenFrame.midX - panelWidth / 2,
                                   y: screenFrame.midY - panelHeight / 2,
                                   width: panelWidth,
                                   height: panelHeight),
                           display: true)
        }
        
        panel.makeKeyAndOrderFront(nil) // 显示面板并使其成为键窗口以接收输入
    }

    @objc func hidePanel() {
        panel.orderOut(nil) // 隐藏面板
        hostingView = nil // 释放 hostingView 及其 SwiftUI 视图层级，避免内存泄露
        pasteTargetApplication = nil // 清空目标应用
        // NEW: 清除 ViewModel 引用
        self.clipboardViewModel = nil
    }

    // 模拟粘贴动作
    private func performPaste(item: ClipboardItem) {
        // NEW: 在执行粘贴操作前，设置 skipNextClipboard 标志为 true
        // 这将阻止 ClipboardViewModel 再次将此粘贴内容记录到历史中。
        clipboardViewModel?.skipNextClipboard = true

        // 1. 将选中的内容放到系统剪贴板
        let pb = NSPasteboard.general
        pb.clearContents()
        var success = false
        switch item.content {
        case .text(let string, _):
            success = pb.setString(string, forType: .string)
        case .image(let image, _):
            success = pb.writeObjects([image])
        case .filePaths(let urls):
            success = pb.writeObjects(urls as [NSPasteboardWriting])
        }

        guard success else {
            os_log("Failed to copy item to pasteboard for quick paste.", type: .error)
            return
        }

        // 2. 尝试将焦点切换回原始应用
        if let targetApp = pasteTargetApplication {
            // 直接在 NSRunningApplication 实例上调用 activate
            targetApp.activate(options: .activateIgnoringOtherApps)
        } else {
            // 如果原始应用不再活跃或无法激活，激活主应用（作为后备）
            // FIX: 使用旧版 `activate(ignoringOtherApps:)` 方法，以兼容可能存在的旧部署目标
            NSApp.activate(ignoringOtherApps: true)
        }

        // 3. 模拟 Cmd+V 粘贴快捷键
        // 需要在 Info.plist 中添加 NSAppleEventsUsageDescription 键值对，
        // 并在 macOS 系统设置中授予本应用“辅助功能”权限。
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // 给予一点时间让应用激活
            let source = CGEventSource(stateID: .combinedSessionState)
            
            // 模拟 Command (kVK_Command) 键按下
            let keyDownCommand = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Command), keyDown: true)
            keyDownCommand?.flags = .maskCommand
            keyDownCommand?.post(tap: .cgSessionEventTap)

            // 模拟 V (kVK_ANSI_V) 键按下
            let keyDownV = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
            keyDownV?.flags = .maskCommand
            keyDownV?.post(tap: .cgSessionEventTap)

            // 模拟 V (kVK_ANSI_V) 键抬起
            let keyUpV = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
            keyUpV?.flags = .maskCommand
            keyUpV?.post(tap: .cgSessionEventTap)

            // 模拟 Command (kVK_Command) 键抬起
            let keyUpCommand = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_Command), keyDown: false)
            keyUpCommand?.flags = .maskCommand
            keyUpCommand?.post(tap: .cgSessionEventTap)
        }
    }
}
