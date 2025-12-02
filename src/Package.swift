// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "MBConverter",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "MBConverter", targets: ["MBConverter"]),
    ],
    targets: [
        .executableTarget(
            name: "MBConverter",
            path: "Sources/MBConverter"
        )
    ]
)
