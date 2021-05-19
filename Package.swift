// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Telemetry",
    platforms: [.iOS(.v11)],
    products: [
        .library(name: "Telemetry", targets: ["Telemetry"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.1.0"),
    ],
    targets: [
        .target(name: "Telemetry", dependencies: []),
        .testTarget(name: "TelemetryTests", dependencies: [.product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"), "Telemetry"]),
    ]
)
