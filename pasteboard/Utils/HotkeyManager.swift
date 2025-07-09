// file: Utils/HotkeyManager.swift

import Foundation
import Carbon.HIToolbox
import AppKit

// 定义一个代理协议，用于通知 App hotkey 被按下
protocol HotkeyManagerDelegate: AnyObject {
    func hotkeyManagerDidReceiveMainHotkey()
    func hotkeyManagerDidReceiveQuickSelectHotkey() // 新增的代理方法
}

// C-Style callback function
private func eventHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData = userData else { return noErr }
    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()

    // 获取按下的热键ID
    var hotKeyID = EventHotKeyID()
    GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)

    // Dispatch to main thread (ALWAYS dispatch UI/MainActor related work to main thread)
    DispatchQueue.main.async {
        if hotKeyID.signature == "pbmh".fourCharCode && hotKeyID.id == 1 { // 主窗口热键
            manager.delegate?.hotkeyManagerDidReceiveMainHotkey()
        } else if hotKeyID.signature == "pbmh".fourCharCode && hotKeyID.id == 2 { // 快速选择热键
            manager.delegate?.hotkeyManagerDidReceiveQuickSelectHotkey()
        }
    }

    return noErr
}

@MainActor
class HotkeyManager {
    weak var delegate: HotkeyManagerDelegate? // 声明代理

    private var mainHotKeyRef: EventHotKeyRef? // 原Cmd+Option+V 的引用
    private var quickSelectHotKeyRef: EventHotKeyRef? // 新Cmd+Shift+V 的引用

    /// Registers the global hotkeys
    func register() {
        // Main App Hotkey: Command + Option + V (ID: 1)
        var mainHotKeyID = EventHotKeyID(signature: "pbmh".fourCharCode, id: 1) // Unique ID 1
        let mainStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(cmdKey + optionKey),
            mainHotKeyID,
            GetApplicationEventTarget(),
            0,
            &mainHotKeyRef
        )
        guard mainStatus == noErr else {
            print("Error: Unable to register main hotkey (Cmd+Option+V). Status: \(mainStatus)")
            // 考虑在此处向用户展示错误
            return
        }
        print("✅ Global hotkey (Cmd+Option+V) registered successfully.")

        // Quick Select Hotkey: Command + Shift + V (ID: 2)
        var quickSelectHotKeyID = EventHotKeyID(signature: "pbmh".fourCharCode, id: 2) // Unique ID 2
        let quickSelectStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(cmdKey + shiftKey),
            quickSelectHotKeyID,
            GetApplicationEventTarget(),
            0,
            &quickSelectHotKeyRef
        )
        guard quickSelectStatus == noErr else {
            print("Error: Unable to register quick select hotkey (Cmd+Shift+V). Status: \(quickSelectStatus)")
            // 如果注册失败，不阻止应用启动，但用户会收到功能不完整的提示
            return
        }
        print("✅ Global hotkey (Cmd+Shift+V) for Quick Select registered successfully.")
        
        // Install Event Handler for both hotkeys (only once is needed for the target)
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            eventHandler, // The C-style callback function for all hotkeys
            1, // Number of event types
            &eventType, // Array of event types (just one in this case)
            selfPtr, // User data to pass to the handler (our HotkeyManager instance)
            nil // Out parameter for the event handler reference (not needed here)
        )

        guard installStatus == noErr else {
            print("Error: Unable to install hotkey event handler. Status: \(installStatus)")
            return
        }
    }

    /// Unregisters all hotkeys to clean up resources.
    func unregister() {
        if let ref = mainHotKeyRef {
            UnregisterEventHotKey(ref)
            mainHotKeyRef = nil
        }
        if let ref = quickSelectHotKeyRef {
            UnregisterEventHotKey(ref)
            quickSelectHotKeyRef = nil
        }
        // No need to uninstall event handler explicitly unless you want to remove *all* handlers
        // for this target, which is generally not necessary on app termination.
    }
}

// Helper to convert a string to a four-character code (OSType).
extension String {
    var fourCharCode: FourCharCode {
        return self.utf16.reduce(0, {$0 << 8 + FourCharCode($1)})
    }
}
