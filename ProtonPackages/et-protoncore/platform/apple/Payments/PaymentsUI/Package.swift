// swift-tools-version: 5.9
// SPDX-License-Identifier: GPL-3.0-or-later
import PackageDescription

let package = Package(
    name: "PaymentsUI", platforms: [.iOS(.v17)], products: [.library(name: "PaymentsUI", targets: ["PaymentsUI"])],
    dependencies: [.package(path: "../PaymentsNG"), .package(path: "../../../../../proton_app_uniffi")], targets: [.target(name: "PaymentsUI", dependencies: ["PaymentsNG", "proton_app_uniffi"])],)
