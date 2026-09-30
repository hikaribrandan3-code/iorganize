// swift-tools-version: 6.1
// iOrganize — local Mac cleanup + file automation (Smart Sanitize / Auto-Flow)
import PackageDescription

let package = Package(
    name: "IOrganize",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "IOrganize",
            path: "Sources/IOrganize"
        )
    ],
    swiftLanguageModes: [.v5]
)
