import Foundation
import ServiceManagement

class LaunchService {
    static let shared = LaunchService()
    
    func enableLaunchAtLogin() {
        // macOS 13+ API
        if #available(macOS 13.0, *) {
            do {
                let service = SMAppService.mainApp
                try service.register()
                print("Registered for launch at login")
            } catch {
                print("Failed to register launch at login: \(error)")
            }
        } else {
            // Fallback for older macOS versions not implemented in this foundational setup
            print("Launch at login requires macOS 13.0+ for this implementation")
        }
    }
    
    func disableLaunchAtLogin() {
         if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                try service.unregister()
                 print("Unregistered for launch at login")
            } catch {
                 print("Failed to unregister launch at login: \(error)")
            }
        }
    }
}
