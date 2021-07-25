// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Linux",
    dependencies: [
        .package(url: "https://github.com/crspybits/SolidAuthSwift.git", .branch("main")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Linux",
            dependencies: [
                .product(name: "SolidAuthSwiftTools", package: "SolidAuthSwift"),
            ]),
        .testTarget(
            name: "LinuxTests",
            dependencies: ["Linux"]),
    ]
)
