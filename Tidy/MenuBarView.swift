import SwiftUI

struct MenuBarView: View {
    @ObservedObject var monitor: ClipboardMonitor
    @ObservedObject var settings: SettingsStore
    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    let supportURL = URL(string: "https://buymeacoffee.com/maferland")!

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        return version.hasPrefix("v") ? version : "v\(version)"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(nsImage: AppIcon.tray)
                    .resizable()
                    .frame(width: 24, height: 24)
                Text("Tidy")
                    .font(.headline)
                Text(appVersion)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Circle()
                    .fill(settings.isEnabled ? .green : .gray.opacity(0.5))
                    .frame(width: 10, height: 10)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

            if let result = monitor.lastResult, result.didChange {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Cleaned clipboard text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)

                Divider()
            }

            VStack(alignment: .leading, spacing: 4) {
                toggleRow(isOn: $settings.isEnabled, label: "Enabled")
                toggleRow(isOn: $launchAtLogin, label: "Start at Login")
                    .onChange(of: launchAtLogin) { _, newValue in
                        if newValue { LaunchAtLogin.enable() } else { LaunchAtLogin.disable() }
                    }
            }
            .padding(.vertical, 6)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Transforms:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.top, 6)

                toggleRow(isOn: $settings.stripTrailing, label: "Strip trailing ws")
                toggleRow(isOn: $settings.collapseSpaces, label: "Collapse spaces")
                toggleRow(isOn: $settings.unwrapParagraphs, label: "Unwrap paragraphs")
                toggleRow(isOn: $settings.trimIndent, label: "Trim indent")
                toggleRow(isOn: $settings.collapseBlankLines, label: "Collapse blanks")
            }
            .padding(.bottom, 6)

            Divider()

            VStack(spacing: 0) {
                Button {
                    NSWorkspace.shared.open(supportURL)
                } label: {
                    HStack {
                        Label("Support", systemImage: "heart")
                        Spacer()
                    }
                }
                .buttonStyle(MenuButtonStyle())

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    HStack {
                        Label("Quit", systemImage: "xmark.circle")
                        Spacer()
                        Text("\u{2318}Q")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(MenuButtonStyle())
                .keyboardShortcut("q")
            }
        }
        .frame(width: 220)
    }

    private func toggleRow(isOn: Binding<Bool>, label: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(CapsuleToggleStyle())
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}

enum AppIcon {
    static var tray: NSImage {
        if let url = Bundle.main.url(forResource: "tray", withExtension: "png", subdirectory: "Resources"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        return NSImage(systemSymbolName: "text.justify.left", accessibilityDescription: "Tidy")!
    }

    static var menuBar: NSImage {
        let icon = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { rect in
            tray.draw(in: rect)
            return true
        }
        icon.isTemplate = true
        return icon
    }
}

struct CapsuleToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Capsule()
            .fill(configuration.isOn ? Color.green : Color.gray.opacity(0.3))
            .frame(width: 26, height: 15)
            .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .frame(width: 13, height: 13)
                    .padding(.horizontal, 1)
            }
            .onTapGesture { configuration.isOn.toggle() }
            .animation(.easeInOut(duration: 0.15), value: configuration.isOn)
    }
}

struct MenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(configuration.isPressed ? Color.gray.opacity(0.2) : Color.clear)
            .contentShape(Rectangle())
    }
}
