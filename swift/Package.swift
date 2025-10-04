// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ai-prd-builder",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ai-orchestrator", targets: ["CLI"]),
        .library(name: "CommonModels", targets: ["CommonModels"]),
        .library(name: "DomainCore", targets: ["DomainCore"]),
        .library(name: "Orchestration", targets: ["Orchestration"]),
        .library(name: "PRDGenerator", targets: ["PRDGenerator"]),
        .library(name: "AIProvidersCore", targets: ["AIProvidersCore"]),
        .library(name: "AIProviderImplementations", targets: ["AIProviderImplementations"]),
        .library(name: "ThinkingCore", targets: ["ThinkingCore"]),
        .library(name: "ImplementationAnalysis", targets: ["ImplementationAnalysis"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift.git", from: "0.18.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift-examples.git", from: "1.15.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.19.0")
    ],
    targets: [
        // Layer 1: Core Domain (No dependencies)
        .target(
            name: "CommonModels",
            dependencies: []
        ),
        .target(
            name: "DomainCore",
            dependencies: ["CommonModels"]
        ),

        // Layer 2: Business Logic
        .target(
            name: "ThinkingCore",
            dependencies: ["CommonModels", "DomainCore"]
        ),
        .target(
            name: "PRDGenerator",
            dependencies: ["CommonModels", "DomainCore", "ThinkingCore", "ImplementationAnalysis"]
        ),
        .target(
            name: "TestGeneration",
            dependencies: ["CommonModels", "DomainCore", "AIProvidersCore", "PRDGenerator"]
        ),
        .target(
            name: "ValidationEngine",
            dependencies: ["CommonModels", "DomainCore"]
        ),

        // Layer 3: Infrastructure
        .target(
            name: "AIProvidersCore",
            dependencies: ["CommonModels"]
        ),
        .target(
            name: "AIProviderImplementations",
            dependencies: ["AIProvidersCore", "CommonModels"]
        ),
        .target(
            name: "MLXIntegration",
            dependencies: [
                "CommonModels",
                "AIProvidersCore",
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXRandom", package: "mlx-swift"),
                .product(name: "MLXNN", package: "mlx-swift"),
                .product(name: "MLXOptimizers", package: "mlx-swift"),
                .product(name: "MLXLinalg", package: "mlx-swift"),
                .product(name: "MLXFFT", package: "mlx-swift"),
                .product(name: "LLM", package: "mlx-swift-examples")
            ]
        ),
        .target(
            name: "ImplementationAnalysis",
            dependencies: [
                "CommonModels",
                "DomainCore",
                "AIProvidersCore",
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),

        // Layer 4: Application
        .target(
            name: "Orchestration",
            dependencies: [
                "CommonModels",
                "DomainCore",
                "ThinkingCore",
                "PRDGenerator",
                "TestGeneration",
                "ValidationEngine",
                "AIProvidersCore",
                "AIProviderImplementations",
                "MLXIntegration"
            ]
        ),
        .target(
            name: "SessionManagement",
            dependencies: ["CommonModels", "DomainCore", "Orchestration"]
        ),

        // Layer 5: Presentation
        .executableTarget(
            name: "CLI",
            dependencies: [
                "Orchestration",
                "SessionManagement",
                "AIProvidersCore",
                "AIProviderImplementations",
                "PRDGenerator",
                "DomainCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "APIServer",
            dependencies: ["Orchestration", "SessionManagement"]
        ),

        // Test Targets
        .testTarget(
            name: "CommonModelsTests",
            dependencies: ["CommonModels"]
        ),
        .testTarget(
            name: "OrchestrationTests",
            dependencies: ["Orchestration"]
        ),
        .testTarget(
            name: "PRDGeneratorTests",
            dependencies: ["PRDGenerator"]
        )
    ]
)