// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftPMLicensesGenerator",
    products: [
        .library(name: "SwiftPMLicensesGenerator", targets: ["SwiftPMLicensesGenerator"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            from: "0.3.1"
        ),
        .package(
            url: "https://github.com/JohnSundell/ShellOut",
            from: "2.3.0"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftPMLicensesGenerator",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "ShellOut", package: "ShellOut")
            ]
        ),
        .testTarget(
            name: "SwiftPMLicensesGeneratorTests",
            dependencies: ["SwiftPMLicensesGenerator"]),
    ]
)
