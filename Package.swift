// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DaySwitch",
    platforms: [.macOS(.v10_13), .iOS(.v12)],
    products: [
        .library(
            name: "DaySwitch",
            targets: ["DaySwitch"]),
    ],
    targets: [
        .target(name: "DaySwitch")
    ]
)
