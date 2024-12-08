// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "uHull",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "uHull",
            targets: ["uHull"]),
    ],
    dependencies: [
            .package(url: "https://github.com/Bersaelor/KDTree.git", from: "1.4.2"),
            .package(url: "https://github.com/evgenyneu/SigmaSwiftStatistics.git", from: "9.0.2"),
        ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "uHull"),
        .testTarget(
            name: "uHullTests",
            dependencies: ["uHull"]
        ),
    ]
)
