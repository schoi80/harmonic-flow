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
    ],
    targets: [
        .target(
            name: "TensorFlowLite",
            path: "Sources/TensorFlowLite"
        ),
        .target(
            name: "HarmonicFlow",
            dependencies: [
                "TensorFlowLite"
            ],
            path: "Sources/HarmonicFlow"
        ),
    ]
)
