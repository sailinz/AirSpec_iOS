// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "airspec",
    products: [
        .library(
            name: "airspec",
            targets: ["airspec"]
        ),
        .library(
            name: "airspec_msg",
            targets: ["airspec_msg"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.20.0"),
    ],
    targets: [
        .target(
            name: "airspec",
            dependencies: [
                "airspec_msg",
            ]
        ),
        .target(
            name: "airspec_msg",
            dependencies: [.product(name: "SwiftProtobuf", package: "swift-protobuf")]
        ),
        .testTarget(
            name: "airspec_test",
            dependencies: ["airspec"]
        )
    ]
)
