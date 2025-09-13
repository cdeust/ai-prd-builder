import Foundation

/// Domain configuration loaded from external JSON
public struct DomainConfiguration: Codable {
    public let domains: [String: DomainDefinition]
    public let fallback: DomainDefinition
    
    public struct DomainDefinition: Codable {
        public let name: String
        public let priority: Int?
        public let indicators: [String]?
        public let guidance: Guidance
        public let questions: [String]
        public let requirementsChecklist: [String]
        public let metrics: [MetricDefinition]
        public let acceptanceCriteria: [AcceptanceCriterion]?
        public let testData: TestDataDefinition?
        
        private enum CodingKeys: String, CodingKey {
            case name, priority, indicators, guidance, questions
            case requirementsChecklist = "requirements_checklist"
            case metrics
            case acceptanceCriteria = "acceptance_criteria"
            case testData = "test_data"
        }
    }
    
    public struct Guidance: Codable {
        public let sections: [GuidanceSection]
    }
    
    public struct GuidanceSection: Codable {
        public let title: String
        public let items: [String]
    }
    
    public struct MetricDefinition: Codable {
        public let name: String
        public let unit: String
        public let target: String
        public let critical: Bool
    }
}

/// Manages loading and accessing domain configurations
public class DomainConfigurationManager {
    private static var configuration: DomainConfiguration?
    private static let configFileName = "domains.json"
    
    /// Load domain configuration from JSON file
    public static func loadConfiguration() throws {
        // Try multiple paths to find the configuration file
        var possiblePaths: [URL?] = []
        
        // Try Bundle.main first (for packaged apps)
        if let bundlePath = Bundle.main.url(forResource: "domains", withExtension: "json") {
            possiblePaths.append(bundlePath)
        }
        
        // Direct path in the source directory
        possiblePaths.append(
            URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .appendingPathComponent("DomainConfigurations")
                .appendingPathComponent("domains.json")
        )
        
        // Fallback to a config directory at project root
        possiblePaths.append(
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Configurations")
                .appendingPathComponent("domains.json")
        )
        
        var configURL: URL?
        for path in possiblePaths {
            if let path = path, FileManager.default.fileExists(atPath: path.path) {
                configURL = path
                break
            }
        }
        
        // If not found in standard locations, try to find it relative to source
        if configURL == nil {
            let sourceDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
            let configPath = sourceDir.appendingPathComponent("DomainConfigurations/domains.json")
            if FileManager.default.fileExists(atPath: configPath.path) {
                configURL = configPath
            }
        }
        
        guard let finalURL = configURL else {
            // If external file not found, use embedded default configuration
            configuration = createDefaultConfiguration()
            return
        }
        
        let data = try Data(contentsOf: finalURL)
        configuration = try JSONDecoder().decode(DomainConfiguration.self, from: data)
    }
    
    /// Get the loaded configuration
    public static func getConfiguration() -> DomainConfiguration {
        if configuration == nil {
            do {
                try loadConfiguration()
            } catch {
                print("Warning: Could not load domain configuration from file: \(error)")
                print("Using default embedded configuration")
                configuration = createDefaultConfiguration()
            }
        }
        return configuration!
    }
    
    /// Create a minimal default configuration as fallback
    private static func createDefaultConfiguration() -> DomainConfiguration {
        // This provides a minimal working configuration if the JSON file cannot be loaded
        let fallback = DomainConfiguration.DomainDefinition(
            name: "General",
            priority: nil,
            indicators: nil,
            guidance: DomainConfiguration.Guidance(sections: [
                DomainConfiguration.GuidanceSection(
                    title: "PROJECT BASICS",
                    items: [
                        "Clear problem statement",
                        "Target audience identification",
                        "Success criteria definition",
                        "Resource requirements",
                        "Timeline and milestones",
                        "Risk assessment"
                    ]
                )
            ]),
            questions: [
                "What problem does this solve?",
                "Who are the users/beneficiaries?",
                "What are the success criteria?",
                "What resources are needed?",
                "What is the timeline?"
            ],
            requirementsChecklist: [
                "Requirements document",
                "Project plan",
                "Risk assessment",
                "Resource allocation",
                "Success metrics"
            ],
            metrics: [
                DomainConfiguration.MetricDefinition(
                    name: "Project Completion",
                    unit: "percentage",
                    target: "100%",
                    critical: true
                )
            ],
            acceptanceCriteria: nil,
            testData: nil
        )
        
        return DomainConfiguration(
            domains: [:],
            fallback: fallback
        )
    }
    
    /// Detect domain from text using configuration
    public static func detectDomain(from text: String) -> String {
        let config = getConfiguration()
        let lowercased = text.lowercased()
        
        // Sort domains by priority (if specified)
        let sortedDomains = config.domains.sorted { (lhs, rhs) in
            let lhsPriority = lhs.value.priority ?? Int.max
            let rhsPriority = rhs.value.priority ?? Int.max
            return lhsPriority < rhsPriority
        }
        
        // Check each domain's indicators
        for (domainKey, domain) in sortedDomains {
            if let indicators = domain.indicators {
                if indicators.contains(where: { lowercased.contains($0.lowercased()) }) {
                    return domainKey
                }
            }
        }
        
        return "general"
    }
    
    /// Get domain definition by key
    public static func getDomainDefinition(for domainKey: String) -> DomainConfiguration.DomainDefinition {
        let config = getConfiguration()
        return config.domains[domainKey] ?? config.fallback
    }
    
    /// Format guidance sections into a readable string
    public static func formatGuidance(_ guidance: DomainConfiguration.Guidance) -> String {
        var result = ""
        for section in guidance.sections {
            result += "\(section.title):\n"
            for item in section.items {
                result += "• \(item)\n"
            }
            result += "\n"
        }
        return result
    }
    
    /// Format metrics into a readable string
    public static func formatMetrics(_ metrics: [DomainConfiguration.MetricDefinition]) -> String {
        guard !metrics.isEmpty else { return "" }
        
        var result = "Relevant metrics:\n"
        for metric in metrics {
            let criticalTag = metric.critical ? " [CRITICAL]" : ""
            result += "• \(metric.name) (\(metric.unit)): Target \(metric.target)\(criticalTag)\n"
        }
        return result
    }
}
