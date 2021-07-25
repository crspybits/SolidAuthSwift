// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SolidAuthSwift",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        // iOS redirect to allow user to sign in via browser
        .library(
            name: "SolidAuthSwiftUI",
            targets: ["SolidAuthSwiftUI"]),

        // DPoP, Refresh, Validate tokens
        .library(
            name: "SolidAuthSwiftTools",
            targets: ["SolidAuthSwiftTools"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
        .package(url: "https://github.com/Flight-School/AnyCodable.git", from: "0.6.0"),
    ],
    targets: [
        .target(
            name: "SolidAuthSwiftUI",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                "AnyCodable",
            ],
            path: "Sources/SolidAuthSwiftUI"),
        .target(
            name: "SolidAuthSwiftTools",
            dependencies: [
            ],
            path: "Sources/SolidAuthSwiftTools"),
            
        .testTarget(
            name: "SolidAuthSwiftUITests",
            dependencies: ["SolidAuthSwiftUI"],
            path: "Tests/SolidAuthSwiftUITests"),
        .testTarget(
            name: "SolidAuthSwiftToolsTests",
            dependencies: ["SolidAuthSwiftTools"],
            path: "Tests/SolidAuthSwiftToolsTests"),
    ]
)
