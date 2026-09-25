// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Moechat",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Moechat", targets: ["Moechat"])
    ],
    targets: [
        .executableTarget(
            name: "Moechat",
            path: "Sources/Moechat"
        )
    ]
)
