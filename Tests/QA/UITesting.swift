import XCTest
import SwiftUI
import AppKit
@testable import SystemMonitor

/// UI testing for production readiness validation
final class UITesting: XCTestCase {
    
    func testPopoverPerformance() throws {
        // Create popover similar to AppDelegate setup
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 380, height: 850)
        popover.behavior = .transient
        
        let contentView = ContentView()
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.wantsLayer = true
        popover.contentViewController = hostingController
        
        // Measure popover creation time
        measure {
            for _ in 0..<10 {
                let testPopover = NSPopover()
                testPopover.contentSize = NSSize(width: 380, height: 850)
                let testController = NSHostingController(rootView: ContentView())
                testController.view.wantsLayer = true
            }
        }
    }
    
    func testSwiftUIViewPerformance() throws {
        // Test view rendering performance
        measure {
            for _ in 0..<100 {
                let view = ContentView()
                let hostingController = NSHostingController(rootView: view)
                _ = hostingController.view
            }
        }
    }
    
    func testMetricsViewModelPerformance() throws {
        let viewModel = MetricsViewModel()
        
        measure {
            for _ in 0..<50 {
                // Simulate view model operations
                let cpu = viewModel.cpuMetrics
                let ram = viewModel.ramMetrics
                let network = viewModel.networkMetrics
                _ = viewModel.topProcesses
                _ = viewModel.isLoading
            }
        }
    }
    
    func testUIUpdatesUnderLoad() async throws {
        let viewModel = MetricsViewModel()
        let updatesPerSecond = 10
        let testDuration: TimeInterval = 2.0
        let updateInterval = 1.0 / Double(updatesPerSecond)
        
        let startTime = Date()
        var updateCount = 0
        
        // Simulate UI updates under load
        while Date().timeIntervalSince(startTime) < testDuration {
            // Trigger view model updates
            _ = viewModel.cpuMetrics
            _ = viewModel.ramMetrics
            _ = viewModel.networkMetrics
            _ = viewModel.topProcesses
            
            updateCount += 1
            
            try? await Task.sleep(nanoseconds: UInt64(updateInterval * 1_000_000_000))
        }
        
        let expectedUpdates = Int(updatesPerSecond * testDuration)
        let actualUpdates = updateCount
        
        // Allow 20% tolerance for timing variations
        XCTAssertGreaterThanOrEqual(actualUpdates, Int(Double(expectedUpdates) * 0.8))
        XCTAssertLessThanOrEqual(actualUpdates, Int(Double(expectedUpdates) * 1.2))
        
        print("UI updates under load: \(actualUpdates) updates in \(testDuration)s")
    }
    
    func testMemoryLeaksInUI() throws {
        // Test for memory leaks in UI components
        weak var weakViewModel: MetricsViewModel?
        weak var weakPopover: NSPopover?
        weak var weakHostingController: NSHostingController<ContentView>?
        
        autoreleasepool {
            let viewModel = MetricsViewModel()
            let popover = NSPopover()
            let hostingController = NSHostingController(rootView: ContentView())
            
            weakViewModel = viewModel
            weakPopover = popover
            weakHostingController = hostingController
        }
        
        // Give time for deallocation
        autoreleasepool {
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        }
        
        XCTAssertNil(weakViewModel, "ViewModel should be deallocated")
        XCTAssertNil(weakPopover, "Popover should be deallocated")
        XCTAssertNil(weakHostingController, "HostingController should be deallocated")
    }
    
    func testDarkModeCompatibility() throws {
        let darkAppearance = NSAppearance(named: .darkAqua)
        let lightAppearance = NSAppearance(named: .aqua)
        
        // Test views with different appearances
        let darkView = ContentView()
            .environment(\.colorScheme, .dark)
        let lightView = ContentView()
            .environment(\.colorScheme, .light)
        
        let darkController = NSHostingController(rootView: darkView)
        let lightController = NSHostingController(rootView: lightView)
        
        darkController.view.appearance = darkAppearance
        lightController.view.appearance = lightAppearance
        
        XCTAssertNotNil(darkController.view)
        XCTAssertNotNil(lightController.view)
        
        // Verify views can be rendered with both appearances
        let darkBounds = darkController.view.bounds
        let lightBounds = lightController.view.bounds
        
        XCTAssertFalse(darkBounds.isEmpty, "Dark mode view should have valid bounds")
        XCTAssertFalse(lightBounds.isEmpty, "Light mode view should have valid bounds")
    }
    
    func testMenuBarIntegration() throws {
        // Test status item creation and management
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        XCTAssertNotNil(statusItem)
        XCTAssertNotNil(statusItem.button)
        
        // Test system symbol image usage
        statusItem.button?.image = NSImage(systemSymbolName: "cpu", accessibilityDescription: "System Monitor")
        
        XCTAssertNotNil(statusItem.button?.image)
        XCTAssertEqual(statusItem.button?.image?.accessibilityDescription, "System Monitor")
        
        // Clean up
        NSStatusBar.system.removeStatusItem(statusItem)
    }
    
    func testResponsiveLayout() throws {
        let contentView = ContentView()
        let hostingController = NSHostingController(rootView: contentView)
        
        // Test different sizes
        let testSizes = [
            NSSize(width: 300, height: 600),
            NSSize(width: 380, height: 850),
            NSSize(width: 500, height: 1000)
        ]
        
        for size in testSizes {
            hostingController.view.frame = NSRect(origin: .zero, size: size)
            
            // Verify view can handle different sizes without crashing
            hostingController.view.layoutSubtreeIfNeeded()
            
            XCTAssertFalse(hostingController.view.bounds.isEmpty, "View should be renderable at size \(size)")
        }
    }
    
    func testErrorBannerUI() throws {
        // Test error banner visibility and behavior
        let errorMessage = "Test error message"
        
        // This would require mocking the ViewModel to simulate errors
        // For now, just test that the error banner component exists and can be created
        let errorBanner = ErrorBannerView(message: errorMessage, isVisible: true) {
            // Empty action
        }
        
        let hostingController = NSHostingController(rootView: errorBanner)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 300, height: 100)
        
        XCTAssertNotNil(hostingController.view)
        
        // Test invisible state
        let invisibleErrorBanner = ErrorBannerView(message: errorMessage, isVisible: false) {
            // Empty action
        }
        
        let invisibleController = NSHostingController(rootView: invisibleErrorBanner)
        XCTAssertNotNil(invisibleController.view)
    }
    
    func testAnimationPerformance() throws {
        // Test SwiftUI animations don't impact performance
        let testView = ContentView()
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.blue.opacity(0.1))
                    .frame(height: 4)
            )
        
        measure {
            for _ in 0..<20 {
                let controller = NSHostingController(rootView: testView)
                _ = controller.view
            }
        }
    }
    
    func testConcurrentUIUpdates() async throws {
        let viewModel = MetricsViewModel()
        let concurrentTasks = 10
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<concurrentTasks {
                group.addTask {
                    // Simulate concurrent UI operations
                    for _ in 0..<50 {
                        _ = viewModel.cpuMetrics
                        _ = viewModel.ramMetrics
                        _ = viewModel.networkMetrics
                        _ = viewModel.topProcesses
                    }
                }
            }
        }
        
        // Verify ViewModel is still functional after concurrent access
        XCTAssertNotNil(viewModel.cpuMetrics)
        XCTAssertNotNil(viewModel.ramMetrics)
        XCTAssertNotNil(viewModel.networkMetrics)
    }
}