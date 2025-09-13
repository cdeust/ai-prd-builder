import Foundation

/// Intelligent domain knowledge system that uses external configuration
public class DomainKnowledge {
    
    /// Detect the domain from context using external configuration
    public static func detectDomain(from text: String) -> String {
        return DomainConfigurationManager.detectDomain(from: text)
    }
    
    /// Provide domain-specific guidance for PRD creation from configuration
    public static func getDomainGuidance(for domain: String, request: String) -> String {
        let domainDef = DomainConfigurationManager.getDomainDefinition(for: domain)
        
        var result = "\(domainDef.name.uppercased()) CONTEXT DETECTED\n\n"
        result += DomainConfigurationManager.formatGuidance(domainDef.guidance)
        result += "\n"
        result += DomainConfigurationManager.formatMetrics(domainDef.metrics)
        
        return result
    }
    
    /// Extract domain-specific requirements that might be missing
    public static func suggestDomainRequirements(domain: String, currentRequirements: [String]) -> [String] {
        let domainDef = DomainConfigurationManager.getDomainDefinition(for: domain)
        
        // Filter out requirements that are already present
        let suggestions = domainDef.requirementsChecklist.filter { check in
            !currentRequirements.contains { req in
                req.lowercased().contains(check.lowercased()) ||
                check.lowercased().contains(req.lowercased())
            }
        }
        
        return suggestions.map { "Consider adding: \($0)" }
    }
    
    /// Generate intelligent questions based on domain from configuration
    public static func generateDomainQuestions(domain: String, context: String) -> [String] {
        let domainDef = DomainConfigurationManager.getDomainDefinition(for: domain)
        return domainDef.questions
    }
    
    /// Get all available domains from configuration
    public static func getAvailableDomains() -> [String] {
        let config = DomainConfigurationManager.getConfiguration()
        return Array(config.domains.keys).sorted()
    }
    
    /// Get domain metrics from configuration
    public static func getDomainMetrics(for domain: String) -> [(name: String, unit: String, target: String, critical: Bool)] {
        let domainDef = DomainConfigurationManager.getDomainDefinition(for: domain)
        return domainDef.metrics.map { metric in
            (name: metric.name, unit: metric.unit, target: metric.target, critical: metric.critical)
        }
    }
    
    /// Validate if a domain exists in configuration
    public static func isValidDomain(_ domain: String) -> Bool {
        let config = DomainConfigurationManager.getConfiguration()
        return config.domains[domain] != nil || domain == "general"
    }
    
    /// Get priority for a domain (lower number = higher priority)
    public static func getDomainPriority(_ domain: String) -> Int {
        let domainDef = DomainConfigurationManager.getDomainDefinition(for: domain)
        return domainDef.priority ?? Int.max
    }
    
    /// Reload configuration from file (useful for development/testing)
    public static func reloadConfiguration() throws {
        try DomainConfigurationManager.loadConfiguration()
    }
}