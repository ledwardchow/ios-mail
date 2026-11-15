// swift-tools-version: 5.9
// SPDX-License-Identifier: GPL-3.0-or-later
import PackageDescription

let package = Package(
    name: "PaymentsNG", platforms: [.iOS(.v17)], products: [.library(name: "PaymentsNG", targets: ["PaymentsNG"])], dependencies: [.package(path: "../../../../../proton_app_uniffi")],
    targets: [.target(name: "PaymentsNG", dependencies: ["proton_app_uniffi"]), .testTarget(name: "PaymentsNGTests", dependencies: ["PaymentsNG"])],)
