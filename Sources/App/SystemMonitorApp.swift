import SwiftUI

@main
struct SystemMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // We use Settings to have a scene, but we don't want a main window.
        // The main UI is handled by the AppDelegate via NSStatusBar.
        Settings {
            EmptyView()
        }
    }
}
