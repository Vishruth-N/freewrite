import SwiftUI
import AppKit
import LiveKit

@MainActor
class VoiceAgentWindowManager: ObservableObject {
    static let shared = VoiceAgentWindowManager()
    
    private var voiceAgentWindow: NSWindow?
    private var appViewModel: AppViewModel?
    
    private init() {}
    
    func openVoiceAgent() {
        // Check if window is already open
        if let existingWindow = voiceAgentWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create the AppViewModel for VoiceAgent
        let viewModel = AppViewModel()
        self.appViewModel = viewModel
        
        // Create the VoiceAgent view
        let voiceAgentView = AppView()
            .environment(viewModel)
            .frame(minWidth: 800, minHeight: 600)
        
        // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Voice Agent - Reflect"
        window.contentView = NSHostingView(rootView: voiceAgentView)
        window.center()
        window.setFrameAutosaveName("VoiceAgentWindow")
        
        // Set up window delegate to clean up when closed
        let delegate = VoiceAgentWindowDelegate { [weak self] in
            Task { @MainActor in
                // Properly disconnect before cleaning up
                await self?.appViewModel?.disconnect()
                self?.appViewModel = nil
                self?.voiceAgentWindow = nil
            }
        }
        window.delegate = delegate
        
        self.voiceAgentWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func closeVoiceAgent() {
        Task { @MainActor in
            // Ensure proper disconnect before closing
            await appViewModel?.disconnect()
            voiceAgentWindow?.close()
            appViewModel = nil
            voiceAgentWindow = nil
        }
    }
    
    var isVoiceAgentOpen: Bool {
        voiceAgentWindow != nil
    }
}

// Window delegate to handle cleanup
private class VoiceAgentWindowDelegate: NSObject, NSWindowDelegate {
    let onClose: () -> Void
    
    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    func windowWillClose(_ notification: Notification) {
        onClose()
    }
} 