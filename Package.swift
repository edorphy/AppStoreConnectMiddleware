// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppStoreConnectMiddleware",
    platforms: [
        .iOS(.v18),
        .visionOS(.v2),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "AppStoreConnectMiddleware",
            targets: ["AppStoreConnectMiddleware"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.8.0"),
    ],
    targets: [
        .target(
            name: "AppStoreConnectMiddleware",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
            ]
        ),
        .testTarget(
            name: "AppStoreConnectMiddlewareTests",
            dependencies: [
                "AppStoreConnectMiddleware"
            ]
        ),
    ]
)
