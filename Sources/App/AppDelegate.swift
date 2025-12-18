import Cocoa
import SwiftUI
import SystemMonitorCore

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupPopover()
        setupStatusBar()
        setupLaunchAtLogin()
    }
    
    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 850)
        popover.behavior = .transient
        let hostingController = NSHostingController(rootView: ContentView())
        hostingController.view.wantsLayer = true
        popover.contentViewController = hostingController
        self.popover = popover
    }

    private func setupStatusBar() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = self.statusItem.button {
            // Placeholder icon: using a generic system symbol
            button.image = NSImage(systemSymbolName: "cpu", accessibilityDescription: "System Monitor")
            button.action = #selector(togglePopover(_:))
        }
    }
    
    private func setupLaunchAtLogin() {
        // Enable launch at login using our service
        LaunchService.shared.enableLaunchAtLogin()
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = self.statusItem.button {
            if self.popover.isShown {
                self.popover.performClose(sender)
            } else {
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                
                // Bring app to front so the popover is interactive
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
