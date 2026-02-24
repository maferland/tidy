import SwiftUI

@main
struct TidyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(monitor: appDelegate.monitor, settings: appDelegate.monitor.settings)
        } label: {
            Image(nsImage: Self.menuBarIcon)
        }
        .menuBarExtraStyle(.window)
        .onChange(of: appDelegate.monitor.lastResult) { _, result in
            if let result, result.didChange {
                print("Clipboard cleaned")
            }
        }
    }

    private static var menuBarIcon: NSImage {
        if let url = Bundle.main.url(forResource: "tray", withExtension: "png", subdirectory: "Resources"),
           let source = NSImage(contentsOf: url) {
            let icon = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
                source.draw(in: rect)
                return true
            }
            icon.isTemplate = true
            return icon
        }
        return NSImage(systemSymbolName: "text.justify.left", accessibilityDescription: "Tidy")!
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let monitor = ClipboardMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        monitor.start()
    }
}
