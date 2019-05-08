// swift-tools-version:5.0

import PackageDescription

// 🛡 A Page is promoted to a Squire
let package = Package(
    name: "Squire",
    // 📟 Query PagerDuty API
    dependencies: [
        .package(path: "../../../github.com/Yasumoto/PagerDutySwift/")
    ],
    targets: [
        .target(
            name: "Squire",
            dependencies: ["PagerDutySwift"]),
        .testTarget(
            name: "SquireTests",
            dependencies: ["Squire"]),
    ]
)
