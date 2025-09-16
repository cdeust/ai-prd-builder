// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppleIntelligenceOrchestrator",
    platforms: [
        .macOS(.v14) // macOS 14+ for MLX support
    ],
    products: [
        .executable(
            name: "ai-orchestrator",
            targets: ["AppleIntelligenceOrchestrator"]
        ),
        .library(
            name: "AIBridge",
            targets: ["AIBridge"]
        ),
        .library(
            name: "AIProviders",
            targets: ["AIProviders"]
        ),
        .library(
            name: "ThinkingFramework",
            targets: ["ThinkingFramework"]
        )
    ],
    dependencies: [
        // MLX Swift package
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.18.0"),
        // MLX Swift Examples for LLM support
        .package(url: "https://github.com/ml-explore/mlx-swift-examples", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "AppleIntelligenceOrchestrator",
            dependencies: [
                "AIBridge",
                "AIProviders",
                "ThinkingFramework",
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXNN", package: "mlx-swift"),
                .product(name: "MLXOptimizers", package: "mlx-swift")
            ],
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-disable-availability-checking"])
            ],
            linkerSettings: [
                .linkedFramework("Metal"),
                .linkedFramework("MetalPerformanceShaders"),
                .linkedFramework("MetalPerformanceShadersGraph"),
                .linkedFramework("FoundationModels", .when(platforms: [.macOS]))
            ]
        ),
        .target(
            name: "AIBridge",
            dependencies: [
                "AIProviders",
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXNN", package: "mlx-swift"),
                .product(name: "MLXOptimizers", package: "mlx-swift"),
                .product(name: "MLXRandom", package: "mlx-swift"),
                .product(name: "MLXLLM", package: "mlx-swift-examples"),
                .product(name: "MLXLMCommon", package: "mlx-swift-examples")
            ]
        ),
        .target(
            name: "AIProviders",
            dependencies: [],
            linkerSettings: [
                .linkedFramework("FoundationModels", .when(platforms: [.macOS]))
            ]
        ),
        .target(
            name: "ThinkingFramework",
            dependencies: [
                "AIBridge"
            ]
        )
    ]
)
