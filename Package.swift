// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftPMLicensesGenerator",
    products: [
        .executable(name: "SwiftPMLicensesGenerator", targets: ["SwiftPMLicensesGenerator"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser", .upToNextMajor(from: "1.0.0")
        ),
    ],
    targets: [
        .executableTarget(
            name: "SwiftPMLicensesGenerator",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "SwiftPMLicensesGeneratorTests",
            dependencies: ["SwiftPMLicensesGenerator"]
        ),
    ]
)
