// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "StateMachine",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "StateMachine",
            targets: ["StateMachine"]),
    ],
    targets: [
        .target(
            name: "StateMachine"),
        .testTarget(
            name: "StateMachineTests",
            dependencies: ["StateMachine"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
