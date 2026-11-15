// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TestableShareExtension",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TestableShareExtension", targets: ["TestableShareExtension"])
    ],
    dependencies: [
        .package(path: "../InboxAttribution"),
        .package(path: "../InboxComposer"),
        .package(path: "../InboxKeychain"),
        .package(path: "../InboxSnapshotTesting"),
        .package(path: "../InboxTesting"),
        .package(path: "../../ProtonPackages/et-protoncore/platform/apple/ProtonCoreET"),
    ],
    targets: [
        .target(
            name: "TestableShareExtension",
            dependencies: [
                "InboxAttribution",
                "InboxComposer",
                "InboxKeychain",
                .product(name: "ProtonUIFoundations", package: "ProtonCoreET"),
            ]
        ),
        .testTarget(
            name: "ShareExtensionTests",
            dependencies: ["InboxSnapshotTesting", "InboxTesting", "TestableShareExtension"]
        ),
    ]
)
