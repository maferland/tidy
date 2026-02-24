// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Tidy",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Tidy",
            path: "Tidy"
        ),
        .testTarget(
            name: "TidyTests",
            dependencies: ["Tidy"],
            path: "TidyTests"
        )
    ]
)
