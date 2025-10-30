// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "xtreamcode-swift-api",
    platforms: [
        .iOS(.v14),
        .macOS(.v12),
        .tvOS(.v15),
    ],
    products: [
        .library(
            name: "XtreamcodeSwiftAPI",
            targets: ["XtreamSDKFacade"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.2"),
    ],
    targets: [
        .target(
            name: "XtreamModels",
            dependencies: [],
            path: "Sources/XtreamModels"
        ),
        .target(
            name: "XtreamClient",
            dependencies: [
                "XtreamModels",
                .product(name: "Alamofire", package: "Alamofire"),
            ],
            path: "Sources/XtreamClient"
        ),
        .target(
            name: "XtreamServices",
            dependencies: [
                "XtreamClient",
                "XtreamModels",
            ],
            path: "Sources/XtreamServices"
        ),
        .target(
            name: "XtreamSDKFacade",
            dependencies: [
                "XtreamServices",
                "XtreamModels",
            ],
            path: "Sources/XtreamSDKFacade"
        ),
        .testTarget(
            name: "XtreamcodeSwiftAPITests",
            dependencies: [
                "XtreamSDKFacade",
                "XtreamClient",
                "XtreamModels",
            ],
            path: "Tests/XtreamcodeSwiftAPITests",
            resources: [
                .copy("Fixtures"),
            ]
        ),
    ]
)
