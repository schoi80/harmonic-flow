// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HarmonicFlow",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "HarmonicFlow",
            targets: ["HarmonicFlow"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nethouse/TensorFlowLiteSwift.git", branch: "master")
    ],
    targets: [
        .target(
            name: "HarmonicFlow",
            dependencies: [
                .product(name: "TensorFlowLite", package: "TensorFlowLiteSwift")
            ],
            path: "Sources/HarmonicFlow"
        ),
        .testTarget(
            name: "HarmonicFlowTests",
            dependencies: ["HarmonicFlow"],
            path: "Tests/HarmonicFlowTests"
        ),
    ]
)
