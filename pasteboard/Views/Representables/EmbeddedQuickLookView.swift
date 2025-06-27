// file: Views/Representables/EmbeddedQuickLookView.swift

import SwiftUI
import Quartz

struct EmbeddedQuickLookView: NSViewRepresentable {
    let url: URL
    
    // --- CHANGE 1: The function now returns NSScrollView ---
    func makeNSView(context: Context) -> NSScrollView {
        // 1. Create the QLPreviewView which will render the content
        let previewView = QLPreviewView()
        
        // Let the preview view determine its own size based on the content.
        // This allows it to grow vertically, which the scroll view will handle.
        previewView.autoresizingMask = [.width, .height]
        
        // Attempt to access the security-scoped URL and set it as the preview item
        if context.coordinator.startAccessing(url) {
            previewView.previewItem = url as QLPreviewItem
        }
        
        // 2. Create the ScrollView to contain the QLPreviewView
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false // Horizontal scrolling is rarely needed for documents
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false // Let the QLPreviewView handle its own background
        
        // 3. Place the QLPreviewView inside the ScrollView
        scrollView.documentView = previewView
        
        return scrollView
    }
    
    // --- CHANGE 2: Update logic now needs to access the documentView ---
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        // Get the QLPreviewView from the scroll view's documentView
        guard let previewView = nsView.documentView as? QLPreviewView else {
            return
        }
        
        // If the URL hasn't changed, do nothing
        guard previewView.previewItem?.previewItemURL != url else {
            return
        }
        
        // Stop accessing the old URL and start accessing the new one
        context.coordinator.stopAccessing()
        if context.coordinator.startAccessing(url) {
            previewView.previewItem = url as QLPreviewItem
        }
    }
    
    // --- CHANGE 3: The dismantle function receives an NSScrollView ---
    // No change in logic is needed here as it only uses the coordinator.
    static func dismantleNSView(_ nsView: NSScrollView, coordinator: Coordinator) {
        coordinator.stopAccessing()
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    // The Coordinator class remains unchanged.
    class Coordinator {
        private var isAccessing: Bool = false
        private var currentURL: URL?
        
        func startAccessing(_ url: URL) -> Bool {
            stopAccessing() // Ensure we stop accessing any previous URL
            isAccessing = url.startAccessingSecurityScopedResource()
            if isAccessing {
                currentURL = url
            }
            return isAccessing
        }
        
        func stopAccessing() {
            if isAccessing {
                currentURL?.stopAccessingSecurityScopedResource()
                isAccessing = false
                currentURL = nil
            }
        }
    }
}
