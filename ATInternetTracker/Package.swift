// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ATInternetTracker",
    platforms: [
        .iOS("8.0"),
        .tvOS("9.0"),
        .watchOS("2.0")
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Tracker",
            targets: ["Tracker iOS"]),
    ],
    dependencies: [],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Tracker iOS",
            dependencies: [],
            path: "Sources",
            exclude:[
                "Crash.h",
                "Crash.m",
                "Hash.h",
                "Hash.m"
            ]),
        .testTarget(
            name: "TrackerTests",
            dependencies: ["Tracker iOS"],
            path: "Tests",
            exclude:[
                "Crash.h",
                "Crash.m",
                "Hash.h",
                "Hash.m"
            ]),
    ]
)
