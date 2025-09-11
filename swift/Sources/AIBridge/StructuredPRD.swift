import Foundation

// MARK: - Structured PRD Models (Codable)

public struct StructuredPRD: Codable {
    public let metadata: Metadata
    public let discovery: Discovery
    public let scope: Scope
    public let acceptanceCriteria: [AcceptanceCriterion]
    public let nonFunctional: NonFunctionalRequirements
    public let risks: [Risk]
    public let timeline: Timeline
    public let metrics: Metrics
    
    public struct Metadata: Codable {
        public let feature: String
        public let priority: String
        public let author: String
        public let createdAt: Date
        public let version: String
    }
    
    public struct Discovery: Codable {
        public let problem: String
        public let currentState: CurrentState
        public let impacts: [Impact]
        public let users: [UserPersona]
        
        public struct CurrentState: Codable {
            public let description: String
            public let painPoints: [String]
            public let metrics: [String: Double] // baseline metrics
        }
        
        public struct Impact: Codable {
            public let area: String
            public let severity: String // high/medium/low
            public let quantified: String // e.g., "45 min/week wasted"
        }
        
        public struct UserPersona: Codable {
            public let name: String
            public let role: String
            public let frequency: String // daily/weekly/monthly
            public let painLevel: Int // 1-10
        }
    }
    
    public struct Scope: Codable {
        public let inScope: [ScopeItem]
        public let outOfScope: [String]
        public let assumptions: [String]
        public let dependencies: [Dependency]
        
        public struct ScopeItem: Codable {
            public let id: String
            public let title: String
            public let description: String
            public let priority: String // P0/P1/P2
            public let effort: String // e.g., "3-5d"
        }
        
        public struct Dependency: Codable {
            public let name: String
            public let team: String
            public let requiredBy: String // date
            public let status: String
        }
    }
    
    public struct AcceptanceCriterion: Codable {
        public let title: String
        public let given: String
        public let when: String
        public let then: [String]
        public let nonFunctional: NonFunctionalAC?
        
        public struct NonFunctionalAC: Codable {
            public let p95DurationSec: Int?
            public let successRate: String?
            public let throughput: String?
        }
    }
    
    public struct NonFunctionalRequirements: Codable {
        public let performance: Performance
        public let security: [String]
        public let observability: [ObservabilityMetric]
        
        public struct Performance: Codable {
            public let p95ResponseTime: String
            public let throughput: String
            public let availability: String
            public let errorBudget: String
        }
        
        public struct ObservabilityMetric: Codable {
            public let metric: String
            public let threshold: String
            public let alertCondition: String
        }
    }
    
    public struct Risk: Codable {
        public let title: String
        public let probability: String // high/medium/low
        public let impact: String // high/medium/low
        public let mitigation: String
        public let owner: String
    }
    
    public struct Timeline: Codable {
        public let phases: [Phase]
        public let totalDuration: String
        public let targetLaunch: String
        
        public struct Phase: Codable {
            public let name: String
            public let duration: String
            public let deliverables: [String]
            public let startDate: String?
            public let endDate: String?
        }
    }
    
    public struct Metrics: Codable {
        public let success: [SuccessMetric]
        public let tracking: [String]
        
        public struct SuccessMetric: Codable {
            public let name: String
            public let baseline: Double?
            public let target: Double
            public let unit: String
            public let measurementMethod: String
        }
    }
}

// MARK: - Domain Lexicon for GitHub Actions

// Removed - now using DomainKnowledge dynamically for context-adaptive generation

// MARK: - PRD Generator with Structured Approach

public class StructuredPRDGenerator {
    
    /// Generate planning bullets first (Pass 1)
    public static func createPlannerPrompt(
        feature: String,
        context: String,
        requirements: [String]
    ) -> String {
        // Generate context-aware reference instead of domain-specific
        let contextReference = DomainKnowledge.generateContextReference(
            feature: feature,
            context: context,
            requirements: requirements
        )
        
        return """
        You are a technical planner. Output ONLY bullet points and numbers. NO prose.
        
        Feature: \(feature)
        Context: \(context)
        Requirements: \(requirements.joined(separator: "; "))
        
        \(contextReference)
        
        Output JSON with these exact keys:
        {
          "discovery_facts": ["fact1", "fact2"],
          "scope_items": ["item1", "item2"],
          "acceptance_tests": ["test1", "test2"],
          "risks": ["risk1", "risk2"],
          "metrics": ["metric1", "metric2"],
          "timeline_phases": ["phase1", "phase2"]
        }
        
        Each array item must be a short, specific fact with numbers where possible.
        Focus on the specific context and requirements provided.
        """
    }
    
    /// Convert plan to structured JSON (Pass 2)
    public static func createDrafterPrompt(
        plan: String,
        section: String
    ) -> String {
        return """
        Convert these facts into structured JSON for the \(section) section.
        
        Facts:
        \(plan)
        
        Output ONLY valid JSON matching this schema:
        \(getSchemaForSection(section))
        
        Rules:
        - All numbers must be specific (not ranges)
        - All dates must be ISO format
        - Use domain terms from GitHub Actions
        - No prose, only structured data
        """
    }
    
    private static func getSchemaForSection(_ section: String) -> String {
        switch section {
        case "acceptance_criteria":
            return """
            {
              "title": "string",
              "given": "string",
              "when": "string",
              "then": ["outcome1", "outcome2"],
              "nonFunctional": {
                "p95DurationSec": number,
                "successRate": "percentage"
              }
            }
            """
        case "metrics":
            return """
            {
              "name": "string",
              "baseline": number,
              "target": number,
              "unit": "string",
              "measurementMethod": "string"
            }
            """
        default:
            return "{}"
        }
    }
    
    /// Score and rerank generated outputs
    public static func scoreOutput(_ output: String, feature: String, context: String, requirements: [String]) -> Double {
        var score = 0.0
        
        // Completeness: check for required keys
        let requiredKeys = ["given", "when", "then", "title"]
        for key in requiredKeys {
            if output.contains("\"\(key)\"") {
                score += 10
            }
        }
        
        // Specificity: count numbers and dates
        let digitCount = output.filter { $0.isNumber }.count
        score += Double(digitCount) * 2
        
        // Context relevance: dynamically extracted keywords
        let contextKeywords = DomainKnowledge.extractKeywords(
            feature: feature,
            context: context,
            requirements: requirements
        )
        for keyword in contextKeywords {
            if output.lowercased().contains(keyword) {
                score += 5
            }
        }
        
        // Penalize vague words
        let vagueWords = ["improve", "better", "enhance", "optimize"]
        for word in vagueWords {
            if output.lowercased().contains(word) {
                score -= 3
            }
        }
        
        // Reward specific metrics
        if output.contains("%") { score += 5 }
        if output.contains("ms") || output.contains("sec") { score += 5 }
        if output.contains("macos-14") || output.contains("macos-13") { score += 10 }
        
        return score
    }
    
    /// Patch vague metrics with concrete values
    public static func patchMetrics(_ input: String) -> String {
        var patched = input
        
        // Replace vague success rates
        patched = patched.replacingOccurrences(
            of: "\"successRate\": \"high\"",
            with: "\"successRate\": \"99.9%\""
        )
        
        // Add missing baselines
        if patched.contains("\"baseline\": null") {
            patched = patched.replacingOccurrences(
                of: "\"baseline\": null",
                with: "\"baseline\": 0"
            )
        }
        
        // Normalize timeline references
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        patched = patched.replacingOccurrences(
            of: "\"next quarter\"",
            with: "\"\(formatter.string(from: today.addingTimeInterval(90*24*3600)))\""
        )
        
        return patched
    }
    
    /// Validate structured output
    public static func validateSection<T: Codable>(
        _ json: String,
        type: T.Type
    ) -> Result<T, Error> {
        guard let data = json.data(using: .utf8) else {
            return .failure(NSError(domain: "Invalid UTF8", code: 1))
        }
        
        do {
            let decoded = try JSONDecoder().decode(type, from: data)
            return .success(decoded)
        } catch {
            return .failure(error)
        }
    }
    
    /// Generate observability metrics automatically
    public static func generateObservabilityMetrics(
        for requirements: [String]
    ) -> [StructuredPRD.NonFunctionalRequirements.ObservabilityMetric] {
        
        var metrics: [StructuredPRD.NonFunctionalRequirements.ObservabilityMetric] = []
        
        // For each requirement, generate a metric
        for req in requirements {
            if req.contains("release") || req.contains("deploy") {
                metrics.append(.init(
                    metric: "deployment.duration.p95",
                    threshold: "< 300s",
                    alertCondition: "value > 300 for 2 consecutive runs"
                ))
                metrics.append(.init(
                    metric: "deployment.success_rate",
                    threshold: ">= 99%",
                    alertCondition: "value < 99% over 24h window"
                ))
            }
            
            if req.contains("test") {
                metrics.append(.init(
                    metric: "tests.pass_rate",
                    threshold: ">= 100%",
                    alertCondition: "any test failure"
                ))
            }
            
            if req.contains("quality") || req.contains("sonar") {
                metrics.append(.init(
                    metric: "code.coverage",
                    threshold: ">= 85%",
                    alertCondition: "value < 85%"
                ))
            }
        }
        
        return metrics
    }
}