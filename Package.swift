// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GeoLogCore",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [.library(name: "GeoLogCore", targets: ["GeoLogCore"])],
    targets: [
        .target(name: "GeoLogCore"),
        .testTarget(name: "GeoLogCoreTests", dependencies: ["GeoLogCore"]),
    ]
)
