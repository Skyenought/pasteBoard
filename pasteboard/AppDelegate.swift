// file: AppDelegate.swift

import SwiftUI
import Carbon.HIToolbox // For virtual key codes

// Add @MainActor here
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, HotkeyManagerDelegate { // 遵循 HotkeyManagerDelegate 协议
    
    private let hotkeyManager = HotkeyManager()
    private var quickSelectWindowController: QuickSelectWindowController? // 管理快速选择窗口

    // 将 ViewModel 和 ColorSchemeManager 声明为 lazy var，以便它们在应用启动时被懒加载，
    // 并且在整个 AppDelegate 生命周期中保持引用。
    lazy var clipboardViewModel = ClipboardViewModel()
    lazy var colorSchemeManager = ColorSchemeManager()


    func applicationDidFinishLaunching(_ notification: Notification) {
        hotkeyManager.delegate = self // 设置代理
        hotkeyManager.register()
        
        checkAccessibilityPermissions()
        
        // 初始化 QuickSelectWindowController
        // 这里传入了 ViewModel 和 ColorSchemeManager 的实例，确保其可以被 QuickSelectView 使用
        quickSelectWindowController = QuickSelectWindowController()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregister()
        quickSelectWindowController?.hidePanel() // 确保窗口关闭
    }
    
    private func checkAccessibilityPermissions() {
        // 用于检查并提示用户授予辅助功能权限
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let isTrusted = AXIsProcessTrustedWithOptions(options)

        if !isTrusted {
            print("⚠️ Accessibility permissions are not granted. Global hotkeys and auto-paste will not work until the user grants them in System Settings.")
            // 考虑在此处弹出用户友好的提示，引导他们去系统设置
            // 例如：NSApplication.shared.presentError(NSError(domain: "MyApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Please grant Accessibility permissions to PasteBoard in System Settings -> Privacy & Security -> Accessibility to enable global hotkeys and auto-paste functionality."]))
        }
    }
    
    // MARK: - HotkeyManagerDelegate Methods

    func hotkeyManagerDidReceiveMainHotkey() {
        print("Hotkey Cmd+Option+V pressed! Activating main window.")
        NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
        
        // 确保主窗口被带到前面，如果它被最小化则恢复
        if let window = NSApplication.shared.windows.first {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func hotkeyManagerDidReceiveQuickSelectHotkey() {
        print("Hotkey Cmd+Shift+V pressed! Showing quick select panel.")
        // 显示快速选择面板
        quickSelectWindowController?.showPanel(with: clipboardViewModel, colorSchemeManager: colorSchemeManager)
    }
    
    // 如果应用程序关闭所有窗口，通常会退出。我们希望即使所有窗口关闭，应用仍然运行，以便热键有效。
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // 不在最后一个窗口关闭时终止
    }
}
