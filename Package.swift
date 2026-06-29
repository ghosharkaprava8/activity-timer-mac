// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Tempo",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Tempo",
            path: "Sources/Tempo"
        )
    ]
)
