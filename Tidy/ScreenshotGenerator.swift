import AppKit
import SwiftUI

enum ScreenshotGenerator {
    private static var version: String {
        if let content = try? String(contentsOfFile: "VERSION", encoding: .utf8) {
            let v = content.trimmingCharacters(in: .whitespacesAndNewlines)
            return v.hasPrefix("v") ? v : "v\(v)"
        }
        return "v1.0.0"
    }

    @MainActor static func generate(outputPath: String, scale: CGFloat = 3.0) {
        let view = ScreenshotView(version: version)
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

private struct ScreenshotView: View {
    let version: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(nsImage: AppIcon.tray)
                    .resizable()
                    .frame(width: 24, height: 24)
                Text("Tidy")
                    .font(.headline)
                Text(version)
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
                toggleRow("Enabled", isOn: true)
                toggleRow("Start at Login", isOn: false)
            }
            .padding(.vertical, 6)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Transforms:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.top, 6)

                toggleRow("Strip trailing ws", isOn: true)
                toggleRow("Collapse spaces", isOn: true)
                toggleRow("Unwrap paragraphs", isOn: true)
                toggleRow("Trim indent", isOn: true)
                toggleRow("Collapse blanks", isOn: true)
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

    private func toggleRow(_ label: String, isOn: Bool) -> some View {
        HStack {
            Text(label)
            Spacer()
            CapsuleIndicator(isOn: isOn)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}
