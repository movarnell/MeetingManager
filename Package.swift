// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MeetingManager",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0"),
    ],
    targets: [
        .executableTarget(
            name: "MeetingManager",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit"),
            ],
            path: "MeetingManager",
            exclude: ["Info.plist", "MeetingManager.entitlements", "Preview Content"],
            resources: [
                .process("Assets.xcassets"),
            ]
        ),
    ]
)
