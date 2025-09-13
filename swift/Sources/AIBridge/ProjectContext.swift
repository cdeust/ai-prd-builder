import Foundation

// MARK: - Project Context for PRD Generation

public struct ProjectContext {
    public let teamSize: Int?
    public let sprintDuration: String?  // e.g., "2 weeks"
    public let ciPipeline: String?      // e.g., "GitHub Actions", "Jenkins"
    public let testFramework: String?   // e.g., "XCTest", "Quick/Nimble"
    public let deploymentMethod: String? // e.g., "TestFlight", "Docker"
    public let currentVersion: String?   // e.g., "Swift 5.9", "iOS 16"
    public let targetVersion: String?    // e.g., "Swift 6.0", "iOS 17"
    public let performanceBaselines: [String: String] // e.g., ["p95_latency": "200ms", "memory": "150MB"]
    public let techDebt: [String]       // Known issues to consider
    public let constraints: [String]    // Time, budget, compatibility constraints
    public let monitoringTools: [String] // e.g., ["Datadog", "Sentry"]
    public let rollbackMechanism: String? // e.g., "Feature flags", "Blue-green deployment"
    
    public init(
        teamSize: Int? = nil,
        sprintDuration: String? = nil,
        ciPipeline: String? = nil,
        testFramework: String? = nil,
        deploymentMethod: String? = nil,
        currentVersion: String? = nil,
        targetVersion: String? = nil,
        performanceBaselines: [String: String] = [:],
        techDebt: [String] = [],
        constraints: [String] = [],
        monitoringTools: [String] = [],
        rollbackMechanism: String? = nil
    ) {
        self.teamSize = teamSize
        self.sprintDuration = sprintDuration
        self.ciPipeline = ciPipeline
        self.testFramework = testFramework
        self.deploymentMethod = deploymentMethod
        self.currentVersion = currentVersion
        self.targetVersion = targetVersion
        self.performanceBaselines = performanceBaselines
        self.techDebt = techDebt
        self.constraints = constraints
        self.monitoringTools = monitoringTools
        self.rollbackMechanism = rollbackMechanism
    }
    
    public var contextPrompt: String {
        var parts: [String] = []
        
        if let team = teamSize {
            parts.append("Team: \(team) developers")
        }
        if let sprint = sprintDuration {
            parts.append("Sprints: \(sprint)")
        }
        if let ci = ciPipeline {
            parts.append("CI/CD: \(ci) - use exact pipeline commands")
        }
        if let test = testFramework {
            parts.append("Testing: \(test) - reference actual test commands")
        }
        if let deploy = deploymentMethod {
            parts.append("Deployment: \(deploy) - use specific deployment steps")
        }
        if let current = currentVersion, let target = targetVersion {
            parts.append("Migration: \(current) → \(target)")
        }
        if !performanceBaselines.isEmpty {
            let metrics = performanceBaselines.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            parts.append("Current baselines: \(metrics) - compare against these")
        }
        if !techDebt.isEmpty {
            parts.append("Tech debt to consider: \(techDebt.joined(separator: ", "))")
        }
        if !constraints.isEmpty {
            parts.append("Hard constraints: \(constraints.joined(separator: ", "))")
        }
        if !monitoringTools.isEmpty {
            parts.append("Monitoring: \(monitoringTools.joined(separator: ", ")) - define alerts")
        }
        if let rollback = rollbackMechanism {
            parts.append("Rollback via: \(rollback) - provide exact steps")
        }
        
        if parts.isEmpty {
            return """
            PROJECT CONTEXT MISSING:
            Generate relative timelines (Week 1, Sprint 2) not absolute dates.
            Use placeholder metrics that should be filled in.
            Ask for missing context when critical.
            """
        }
        
        return """
        ACTUAL PROJECT CONTEXT:
        \(parts.map { "- \($0)" }.joined(separator: "\n"))
        
        REQUIREMENTS:
        - Reference these specific tools/versions
        - Use relative timelines based on sprint duration
        - Set quantitative thresholds (fail if X > Y)
        - Make rollback steps executable
        """
    }
    
    public var hasMinimalContext: Bool {
        // Check if we have enough context to generate actionable PRD
        return ciPipeline != nil || testFramework != nil || rollbackMechanism != nil
    }
    
    public func validateForScope(_ scope: StructuredPRDGenerator.ProjectScope) -> [String] {
        var missing: [String] = []
        
        switch scope {
        case .migration:
            if currentVersion == nil || targetVersion == nil {
                missing.append("Current and target versions needed for migration")
            }
            if rollbackMechanism == nil {
                missing.append("Rollback mechanism critical for migration")
            }
            
        case .optimization:
            if performanceBaselines.isEmpty {
                missing.append("Current performance baselines needed for optimization")
            }
            if monitoringTools.isEmpty {
                missing.append("Monitoring setup needed to verify optimization")
            }
            
        case .bugfix:
            if testFramework == nil {
                missing.append("Test framework needed for regression tests")
            }
            
        default:
            break
        }
        
        if ciPipeline == nil {
            missing.append("CI/CD pipeline info needed for actionable steps")
        }
        
        return missing
    }
}
