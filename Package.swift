// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GeoLogCore",
    platforms: [.iOS("27.0"), .macOS(.v13)],
    products: [.library(name: "GeoLogCore", targets: ["GeoLogCore"])],
    targets: [
        .target(name: "GeoLogCore"),
        .testTarget(name: "GeoLogCoreTests", dependencies: ["GeoLogCore"]),
    ]
)
