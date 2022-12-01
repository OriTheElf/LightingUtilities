// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LightingUtilities",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "LightingUtilities",
            targets: ["LightingUtilities"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/MillerTechnologyPeru/ArtNet.git", branch: "master"),
        .package(url: "https://github.com/dnadoba/sACN.git", exact: "0.2.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "LightingUtilities",
            dependencies: []),
        .testTarget(
            name: "LightingUtilitiesTests",
            dependencies: ["LightingUtilities"]),
    ]
)