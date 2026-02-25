import AppKit
import SwiftUI

enum ScreenshotGenerator {
    @MainActor static func generate(outputPath: String, scale: CGFloat = 3.0) {
        let view = ScreenshotView()
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(4)
            .environment(\.colorScheme, .dark)

        let renderer = ImageRenderer(content: view)
        renderer.scale = scale

        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:])
        else {
            fputs("Failed to render screenshot\n", stderr)
            exit(1)
        }

        do {
            let url = URL(filePath: outputPath)
            try png.write(to: url)
            print("Screenshot saved to \(outputPath) (\(Int(scale))x)")
        } catch {
            fputs("Failed to write: \(error)\n", stderr)
            exit(1)
        }
    }
}

private struct ScreenshotToggle: View {
    let label: String
    let isOn: Bool

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Capsule()
                .fill(isOn ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 26, height: 15)
                .overlay(alignment: isOn ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .frame(width: 13, height: 13)
                        .padding(.horizontal, 1)
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}

private struct ScreenshotView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(nsImage: AppIcon.tray)
                    .resizable()
                    .frame(width: 24, height: 24)
                Text("Tidy")
                    .font(.headline)
                Text("v1.0.0")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Circle()
                    .fill(.green)
                    .frame(width: 10, height: 10)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

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

            VStack(alignment: .leading, spacing: 4) {
                ScreenshotToggle(label: "Enabled", isOn: true)
                ScreenshotToggle(label: "Start at Login", isOn: false)
            }
            .padding(.vertical, 6)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Transforms:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.top, 6)

                ScreenshotToggle(label: "Strip trailing ws", isOn: true)
                ScreenshotToggle(label: "Collapse spaces", isOn: true)
                ScreenshotToggle(label: "Unwrap paragraphs", isOn: true)
                ScreenshotToggle(label: "Trim indent", isOn: true)
                ScreenshotToggle(label: "Collapse blanks", isOn: true)
            }
            .padding(.bottom, 6)

            Divider()

            VStack(spacing: 0) {
                HStack {
                    Label("Support", systemImage: "heart")
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)

                HStack {
                    Label("Quit", systemImage: "xmark.circle")
                    Spacer()
                    Text("\u{2318}Q")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 220)
    }
}
