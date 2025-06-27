// file: AppDelegate.swift

import SwiftUI

// Add @MainActor here
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    // Now this initialization is valid because the entire class is on the Main Actor.
    private let hotkeyManager = HotkeyManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // When the app has finished launching, register the hotkey.
        hotkeyManager.register()
        
        // Also, check for Accessibility permissions.
        checkAccessibilityPermissions()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // When the app is about to quit, unregister the hotkey.
        hotkeyManager.unregister()
    }
    
    private func checkAccessibilityPermissions() {
        // The API for hotkeys requires accessibility permissions.
        // We can check and prompt the user if they haven't granted them.
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let isTrusted = AXIsProcessTrustedWithOptions(options)

        if !isTrusted {
            print("⚠️ Accessibility permissions are not granted. The global hotkey will not work until the user grants them in System Settings.")
        }
    }
}
