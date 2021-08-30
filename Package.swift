// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "base32-swift",
    products: [
        .library(
            name: "Base32",
            targets: ["Base32"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nixberg/constant-time-swift", from: "0.9.0"),
    ],
    targets: [
        .target(
            name: "Base32",
            dependencies: [
                .product(name: "ConstantTime", package: "constant-time-swift"),
            ]),
        .testTarget(
            name: "Base32Tests",
            dependencies: ["Base32"]),
    ]
)
