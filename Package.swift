// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let package = Package(
    name: "SolidAuthSwift",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        // iOS redirect to allow user to sign in via browser
        // Intended for use on only iOS
        .library(
            name: "SolidAuthSwiftUI",
            targets: ["SolidAuthSwiftUI"]),

        // DPoP, Refresh, Validate tokens
        // Intended for use on either iOS and Linux: So, keep iOS specifics out of this. Seems like there should be a way to indicate this with `platforms:` but not sure how to do that.
        .library(
            name: "SolidAuthSwiftTools",
            targets: ["SolidAuthSwiftTools"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
        .package(url: "https://github.com/Flight-School/AnyCodable.git", from: "0.6.0"),
        
        // Using my own forked copy of SwiftJWT-- because of a single method I needed to make public. Changed its name because of a conflict.
        .package(name: "SwiftJWT2", url: "https://github.com/crspybits/Swift-JWT2.git", from: "3.6.201"),
        
        .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0")
        
    ],
    targets: [
        .target(
            name: "SolidAuthSwiftUI",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                "AnyCodable",
                "SolidAuthSwiftTools",
            ],
            path: "Sources/SolidAuthSwiftUI"),
        .target(
            name: "SolidAuthSwiftTools",
            dependencies: [
                "SwiftJWT2",
                "AnyCodable",
                .product(name: "JWTKit", package: "jwt-kit"),
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

// Workaround: Because it doesn't currently seems possible to indicate that a target is for a specific platform only; see https://forums.swift.org/t/spm-build-fails-for-watchos-libraries/40474/9 and https://github.com/SDGGiesbrecht/SDGCornerstone/blob/ad52edf9fa206d1d83523e097e8b83bd48939b06/Package.swift#L754-L756
// This is pretty hacky, but given that I'm targetting ubuntu and iOS, it works for now.
// When running on Ubuntu, this is in the environment: "SWIFT_PLATFORM": "ubuntu16.04"
//if let platform = ProcessInfo.processInfo.environment["SWIFT_PLATFORM"], platform.hasPrefix("ubuntu") {
//  //print("ProcessInfo.processInfo.environment: \(ProcessInfo.processInfo.environment)")
//  package.targets.removeAll(where: { $0.name.hasPrefix("SolidAuthSwiftUI") })
//  package.products.removeAll(where: { $0.name.hasPrefix("SolidAuthSwiftUI") })
//}

#if os(Linux)
package.targets.removeAll(where: { $0.name.hasPrefix("SolidAuthSwiftUI") })
package.products.removeAll(where: { $0.name.hasPrefix("SolidAuthSwiftUI") })
#endif
