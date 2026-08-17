// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BitcoinClock",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "BitcoinClock",
            path: "Sources/BitcoinClock"
        )
    ]
)
