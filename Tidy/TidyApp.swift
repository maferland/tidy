import SwiftUI

@main
struct TidyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(monitor: appDelegate.monitor, settings: appDelegate.monitor.settings)
        } label: {
            Image(nsImage: AppIcon.menuBar)
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let monitor = ClipboardMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let idx = CommandLine.arguments.firstIndex(of: "--screenshot") {
            let output = CommandLine.arguments.dropFirst(idx + 1).first ?? "tidy-screenshot.png"
            ScreenshotGenerator.generate(outputPath: output)
            NSApp.terminate(nil)
            return
        }

        NSApp.setActivationPolicy(.accessory)
        monitor.start()
    }
}
