// file: Utils/HotkeyManager.swift

import Foundation
import Carbon.HIToolbox
import AppKit

// C-Style callback function
private func eventHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let userData = userData else { return noErr }
    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()

    // *** THIS IS THE FIX ***
    // We are on a background thread here.
    // Dispatch the work to the main thread before calling the @MainActor method.
    DispatchQueue.main.async {
        manager.handleHotkey()
    }

    return noErr
}

@MainActor
class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    
    /// Registers the global hotkey: Command + Option + V
    func register() {
        // 1. Define a unique ID for the hotkey.
        var hotKeyID = EventHotKeyID(signature: "pbmh".fourCharCode, id: 1)
        
        // 2. Define the event type we want to listen for.
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        // 3. Get a pointer to this instance to pass to the C callback.
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        // 4. Register the hotkey with the system.
        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(cmdKey + optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr else {
            print("Error: Unable to register global hotkey (Cmd+Option+V). Status: \(status)")
            return
        }
        
        // 5. Install an event handler to link the hotkey to our callback function.
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            eventHandler, // The C-style callback
            1,
            &eventType,
            selfPtr,
            nil
        )

        guard installStatus == noErr else {
            print("Error: Unable to install hotkey event handler. Status: \(installStatus)")
            return
        }

        print("✅ Global hotkey (Cmd+Option+V) registered successfully.")
    }

    /// Unregisters the hotkey to clean up resources.
    func unregister() {
        if let hotKeyRef = self.hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
    
    /// This is the action that will be performed when the hotkey is pressed.
    /// This method is already on the Main Actor, so it can safely manipulate UI.
    fileprivate func handleHotkey() {
        print("Hotkey Cmd+Option+V pressed!")

        NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
        
        if let window = NSApplication.shared.windows.first {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.makeKeyAndOrderFront(nil)
        }
    }
}

// Helper to convert a string to a four-character code (OSType).
extension String {
    var fourCharCode: FourCharCode {
        return self.utf16.reduce(0, {$0 << 8 + FourCharCode($1)})
    }
}
