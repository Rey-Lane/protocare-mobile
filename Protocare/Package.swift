// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Protocare",
    platforms: [.iOS(.v17), .macOS(.v10_15)],
    products: [
        .library(name: "Protocare", targets: ["Protocare"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Protocare",
            dependencies: [],
            path: "Protocare"
        ),
        .testTarget(
            name: "ProtocareTests",
            dependencies: ["Protocare"],
            path: "ProtocareTests"
        ),
    ]
)
