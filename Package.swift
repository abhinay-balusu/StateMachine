// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "StateMachine",
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
    ]
)
