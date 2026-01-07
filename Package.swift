// swift-tools-version:5.9
// The Swift tools version – feel free to bump to 5.10 or 6.0 later if needed

import PackageDescription

let package = Package(
    name: "NVHTarGzip-Swift",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "NVHTarGzip-Swift",
            targets: ["NVHTarGzip_Swift"]
        )
    ],
    targets: [
        .target(
            name: "NVHTarGzip_Swift",
            dependencies: [],
            path: "Sources/NVHTarGzip_Swift"
        ),
        .testTarget(
            name: "NVHTarGzip_SwiftTests",
            dependencies: ["NVHTarGzip_Swift"],
            path: "Tests/NVHTarGzip_SwiftTests"
        )
    ],
    swiftLanguageVersions: [.v5, .v6]
)
