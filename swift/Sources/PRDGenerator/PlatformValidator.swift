import Foundation

/// Validates platform consistency and prevents incompatible technology combinations
public struct PlatformValidator {

    public enum Platform {
        case macOS
        case linux
        case windows
        case unknown

        static var current: Platform {
            #if os(macOS)
            return .macOS
            #elseif os(Linux)
            return .linux
            #elseif os(Windows)
            return .windows
            #else
            return .unknown
            #endif
        }

        var name: String {
            switch self {
            case .macOS: return "macOS"
            case .linux: return "Linux"
            case .windows: return "Windows"
            case .unknown: return "Unknown"
            }
        }
    }

    /// Technologies that are platform-specific
    private static let platformSpecificTech: [Platform: Set<String>] = [
        .macOS: [
            "Swift", "SwiftUI", "Core Data", "CloudKit", "TestFlight",
            "App Store", "XCTest", "Apple Platform Security", "Foundation Models",
            "Metal", "Core ML", "ARKit", "HealthKit", "HomeKit"
        ],
        .linux: [
            "systemd", "apt", "yum", "snap", "Docker", "Kubernetes",
            "Linux kernel modules", "SELinux", "AppArmor"
        ],
        .windows: [
            "Windows Registry", "PowerShell", "IIS", ".NET Framework",
            "Windows Store", "MSIX", "Windows Security"
        ]
    ]

    /// Cross-platform technologies
    private static let crossPlatformTech = Set([
        "JavaScript", "TypeScript", "Python", "Java", "Go", "Rust", "C++",
        "PostgreSQL", "MySQL", "MongoDB", "Redis", "SQLite",
        "Docker", "Kubernetes", "GitHub Actions", "GitLab CI", "Jenkins",
        "REST API", "GraphQL", "gRPC", "WebSocket",
        "React", "Vue", "Angular", "Node.js", "Express",
        "Jest", "Mocha", "PyTest", "JUnit"
    ])

    /// Validate if a technology stack is compatible with the current platform
    public static func validateStack(_ stack: StackContext) -> ValidationResult {
        let platform = Platform.current
        var issues: [String] = []
        var suggestions: [String] = []

        // Check language compatibility
        if let langIssue = validateTechnology(stack.language, on: platform) {
            issues.append("Language: \(langIssue)")
            suggestions.append(suggestAlternative(for: stack.language, on: platform, category: "language"))
        }

        // Check test framework
        if let testFramework = stack.testFramework,
           let testIssue = validateTechnology(testFramework, on: platform) {
            issues.append("Test Framework: \(testIssue)")
            suggestions.append(suggestAlternative(for: testFramework, on: platform, category: "testing"))
        }

        // Check deployment
        if let deployment = stack.deployment,
           let deployIssue = validateTechnology(deployment, on: platform) {
            issues.append("Deployment: \(deployIssue)")
            suggestions.append(suggestAlternative(for: deployment, on: platform, category: "deployment"))
        }

        // Check database
        if let database = stack.database,
           let dbIssue = validateTechnology(database, on: platform) {
            issues.append("Database: \(dbIssue)")
            suggestions.append(suggestAlternative(for: database, on: platform, category: "database"))
        }

        return ValidationResult(
            isValid: issues.isEmpty,
            platform: platform,
            issues: issues,
            suggestions: suggestions
        )
    }

    /// Check if a specific technology is compatible with a platform
    private static func validateTechnology(_ tech: String, on platform: Platform) -> String? {
        // Check if it's cross-platform (always OK)
        if crossPlatformTech.contains(tech) {
            return nil
        }

        // Check if it's platform-specific
        for (specificPlatform, technologies) in platformSpecificTech {
            if technologies.contains(where: { tech.contains($0) }) {
                if specificPlatform != platform {
                    return "\(tech) is only available on \(specificPlatform.name), not on \(platform.name)"
                }
                return nil // It's valid for this platform
            }
        }

        // Unknown technology - assume OK
        return nil
    }

    /// Suggest alternatives for incompatible technologies
    private static func suggestAlternative(for tech: String, on platform: Platform, category: String) -> String {
        switch (category, platform) {
        case ("language", .linux):
            if tech.contains("Swift") {
                return "Consider Python, Go, or Rust for Linux development"
            }
        case ("testing", .linux):
            if tech.contains("XCTest") {
                return "Use PyTest (Python), Jest (JS), or Go testing framework"
            }
        case ("deployment", .linux):
            if tech.contains("TestFlight") || tech.contains("App Store") {
                return "Use Docker Hub, Kubernetes, or package managers (apt/yum)"
            }
        case ("database", .linux):
            if tech.contains("Core Data") || tech.contains("CloudKit") {
                return "Use PostgreSQL, MySQL, or MongoDB"
            }
        default:
            break
        }
        return "Choose a \(category) compatible with \(platform.name)"
    }

    /// Get default stack for the current platform
    public static func getDefaultStack(for platform: Platform) -> StackContext {
        switch platform {
        case .macOS:
            return StackContext(
                language: "Swift",
                testFramework: "XCTest",
                cicdPipeline: "GitHub Actions",
                deployment: "TestFlight/App Store",
                database: "Core Data/CloudKit",
                security: "Apple Platform Security",
                performance: "60fps, <400ms response",
                integrations: ["Apple Services"],
                questions: ""
            )
        case .linux:
            return StackContext(
                language: "Python",
                testFramework: "PyTest",
                cicdPipeline: "GitHub Actions",
                deployment: "Docker/Kubernetes",
                database: "PostgreSQL",
                security: "OAuth2/JWT",
                performance: "<200ms response",
                integrations: ["REST API", "Docker"],
                questions: ""
            )
        case .windows:
            return StackContext(
                language: "C#/.NET",
                testFramework: "MSTest",
                cicdPipeline: "Azure DevOps",
                deployment: "Windows Store/MSI",
                database: "SQL Server",
                security: "Windows Security",
                performance: "<200ms response",
                integrations: [".NET Framework"],
                questions: ""
            )
        case .unknown:
            return StackContext(
                language: "JavaScript",
                testFramework: "Jest",
                cicdPipeline: "GitHub Actions",
                deployment: "Docker",
                database: "PostgreSQL",
                security: "OAuth2/JWT",
                performance: "<200ms response",
                integrations: ["REST API"],
                questions: ""
            )
        }
    }

    public struct ValidationResult {
        let isValid: Bool
        let platform: Platform
        let issues: [String]
        let suggestions: [String]

        var summary: String {
            if isValid {
                return "✅ Stack is compatible with \(platform.name)"
            } else {
                var result = "❌ Stack has compatibility issues with \(platform.name):\n"
                for (issue, suggestion) in zip(issues, suggestions) {
                    result += "\n   • \(issue)\n     💡 \(suggestion)"
                }
                return result
            }
        }
    }
}