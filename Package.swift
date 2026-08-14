// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WinMice",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "WinMice", targets: ["WinMice"])
    ],
    targets: [
        .target(
            name: "SwipeGesturePoster",
            path: "Sources/SwipeGesturePoster",
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"])
            ],
            linkerSettings: [
                .linkedFramework("ApplicationServices")
            ]
        ),
        .executableTarget(
            name: "WinMice",
            dependencies: ["SwipeGesturePoster"],
            path: "Sources/WinMice",
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"])
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .testTarget(
            name: "SwipeGesturePosterTests",
            dependencies: ["SwipeGesturePoster"],
            path: "Tests/SwipeGesturePosterTests",
            linkerSettings: [
                .linkedFramework("AppKit")
            ]
        )
    ]
)
