// swift-tools-version: 5.9
// SPDX-License-Identifier: GPL-3.0-or-later
import PackageDescription

let modules = ["AccountChallenge", "AccountLogin", "AccountManager", "AccountPassword", "ProtonUIFoundations", "ProtonCoreUtilities"]
let sdk: Target.Dependency = .product(name: "proton_app_uniffi", package: "proton_app_uniffi")
let package = Package(
    name: "ProtonCoreET",
    platforms: [.iOS(.v17)],
    products: modules.map { .library(name: $0, targets: [$0]) },
    dependencies: [.package(path: "../../../../proton_app_uniffi")],
    targets: [
        .target(name: "ProtonUIFoundations", exclude: ["PROVENANCE.md"]),
        .target(name: "ProtonCoreUtilities"),
        .target(name: "AccountChallenge", dependencies: [sdk]),
        .target(name: "AccountLogin", dependencies: [sdk, "AccountChallenge", "ProtonUIFoundations", "ProtonCoreUtilities"]),
        .target(name: "AccountManager", dependencies: [sdk, "AccountLogin"]),
        .target(name: "AccountPassword", dependencies: [sdk, "AccountLogin"]),
        .testTarget(name: "AccountLoginTests", dependencies: ["AccountLogin"]),
        .testTarget(name: "AccountPasswordTests", dependencies: ["AccountPassword"]),
        .testTarget(name: "ProtonCoreUtilitiesTests", dependencies: ["ProtonCoreUtilities"]),
        .testTarget(name: "ProtonUIFoundationsTests", dependencies: ["ProtonUIFoundations"]),
    ],
)
