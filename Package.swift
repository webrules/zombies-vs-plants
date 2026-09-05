// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ZombiesVsPlants",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "ZombiesVsPlants", targets: ["ZombiesVsPlants"])],
    targets: [
        .executableTarget(
            name: "ZombiesVsPlants",
            path: "Sources/ZombiesVsPlants"
        ),
        .testTarget(
            name: "ZombiesVsPlantsTests",
            dependencies: ["ZombiesVsPlants"],
            path: "Tests/ZombiesVsPlantsTests"
        )
    ]
)
