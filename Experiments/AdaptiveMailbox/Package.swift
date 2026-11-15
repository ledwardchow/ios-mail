// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AdaptiveMailbox",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "AdaptiveMailbox", targets: ["AdaptiveMailbox"])],
    targets: [
        .target(name: "AdaptiveMailbox"),
        .testTarget(name: "AdaptiveMailboxTests", dependencies: ["AdaptiveMailbox"])
    ]
)
