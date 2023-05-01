// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "base32-swift",
    products: [
        .library(
            name: "Base32",
            targets: ["Base32"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nixberg/subtle-swift", "0.11.0"..<"0.12.0"),
    ],
    targets: [
        .target(
            name: "Base32",
            dependencies: [
                .product(name: "Subtle", package: "subtle-swift"),
            ]),
        .testTarget(
            name: "Base32Tests",
            dependencies: ["Base32"]),
    ]
)
