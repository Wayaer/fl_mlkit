// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "fl_camera",
    platforms: [
        .iOS("15.5")
    ],
    products: [
        .library(name: "fl-camera", targets: ["fl_camera"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(name: "fl_channel", path: "../fl_channel")
    ],
    targets: [
        .target(
            name: "fl_camera",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "fl-channel", package: "fl_channel")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
