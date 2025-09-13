import Foundation

// MARK: - Context-Adaptive Knowledge Extraction

public class DomainKnowledge {
    
    /// Extract context-specific terminology from feature and requirements
    public static func extractContextTerms(feature: String, context: String, requirements: [String]) -> [String] {
        let combined = "\(feature) \(context) \(requirements.joined(separator: " "))"
        var terms = Set<String>()
        
        // Extract technical terms (words with capitals, acronyms, compound words)
        let words = combined.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        for word in words {
            let cleaned = word.trimmingCharacters(in: CharacterSet.punctuationCharacters)
            
            // Keep acronyms (all caps, 2+ chars)
            if cleaned.count >= 2 && cleaned == cleaned.uppercased() && cleaned.rangeOfCharacter(from: .letters) != nil {
                terms.insert(cleaned.lowercased())
            }
            
            // Keep technical terms (contains capitals not at start)
            if cleaned.count > 3 {
                let hasInternalCapital = cleaned.dropFirst().contains { $0.isUppercase }
                if hasInternalCapital {
                    terms.insert(cleaned.lowercased())
                }
            }
            
            // Keep compound words with dashes or underscores
            if cleaned.contains("-") || cleaned.contains("_") {
                terms.insert(cleaned.lowercased())
            }
        }
        
        // Extract noun phrases and technical concepts
        let technicalPatterns = [
            "system", "service", "platform", "framework", "library",
            "process", "workflow", "pipeline", "integration", "interface",
            "component", "module", "feature", "function", "method",
            "database", "storage", "cache", "queue", "stream",
            "user", "customer", "client", "admin", "operator"
        ]
        
        for pattern in technicalPatterns {
            if combined.lowercased().contains(pattern) {
                // Find the actual phrase containing this pattern
                let regex = try? NSRegularExpression(pattern: "\\b\\w*\(pattern)\\w*\\b", options: .caseInsensitive)
                let matches = regex?.matches(in: combined, range: NSRange(combined.startIndex..., in: combined)) ?? []
                for match in matches {
                    if let range = Range(match.range, in: combined) {
                        terms.insert(String(combined[range]).lowercased())
                    }
                }
            }
        }
        
        return Array(terms).sorted()
    }
    
    /// Generate context-aware reference material based on extracted terms
    public static func generateContextReference(feature: String, context: String, requirements: [String]) -> String {
        let terms = extractContextTerms(feature: feature, context: context, requirements: requirements)
        
        if terms.isEmpty {
            return """
            PROJECT CONTEXT:
            Feature: \(feature)
            Context: \(context)
            Focus Areas: \(requirements.joined(separator: ", "))
            """
        }
        
        return """
        PROJECT CONTEXT:
        Feature: \(feature)
        
        KEY CONCEPTS IDENTIFIED:
        \(terms.map { "- \($0)" }.joined(separator: "\n"))
        
        REQUIREMENTS FOCUS:
        \(requirements.map { "- \($0)" }.joined(separator: "\n"))
        
        EVALUATION CRITERIA:
        - Completeness: All requirements addressed
        - Specificity: Concrete metrics and timelines
        - Feasibility: Realistic implementation approach
        - Measurability: Clear success indicators
        """
    }
    
    
    /// Extract relevant keywords dynamically from context
    public static func extractKeywords(feature: String, context: String, requirements: [String]) -> [String] {
        var keywords = Set<String>()
        
        // Extract from feature name
        let featureWords = feature.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted)
        keywords.formUnion(featureWords.filter { $0.count > 2 })
        
        // Extract from context
        let contextWords = context.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted)
        keywords.formUnion(contextWords.filter { $0.count > 3 })
        
        // Extract action verbs and nouns from requirements
        for req in requirements {
            let words = req.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted)
            
            // Focus on longer, meaningful words
            let meaningful = words.filter { $0.count > 3 }
            keywords.formUnion(meaningful)
        }
        
        // Remove common stop words
        let stopWords = Set(["this", "that", "with", "from", "have", "will", "should", "could", "would", "must", "shall", "when", "where", "what", "which", "while", "through", "about", "after", "before", "during"])
        keywords.subtract(stopWords)
        
        return Array(keywords).sorted()
    }
    
    
    /// Generate context-aware quality metrics based on requirements
    /// Note: For concrete SMART metrics, see SMARTMetricsSynthesizer (external).
    public static func generateQualityMetrics(feature: String, context: String, requirements: [String]) -> [String] {
        var metrics: [String] = []
        let combined = "\(feature) \(context) \(requirements.joined(separator: " "))".lowercased()
        
        // Core metrics that apply to most features
        metrics.append("Implementation completeness: 100% of requirements")
        metrics.append("User acceptance rate: > 90%")
        
        // Add performance metrics if mentioned
        if combined.contains("performance") || combined.contains("speed") || combined.contains("fast") {
            metrics.append("Response time: < X seconds")
            metrics.append("Throughput: > X operations/second")
        }
        
        // Add reliability metrics if mentioned
        if combined.contains("reliable") || combined.contains("availability") || combined.contains("uptime") {
            metrics.append("Availability: > 99.9%")
            metrics.append("Error rate: < 0.1%")
        }
        
        // Add scalability metrics if mentioned
        if combined.contains("scale") || combined.contains("growth") || combined.contains("capacity") {
            metrics.append("Scalability: Support X concurrent users")
            metrics.append("Resource efficiency: < X% CPU/memory")
        }
        
        // Add quality metrics if mentioned
        if combined.contains("quality") || combined.contains("test") || combined.contains("coverage") {
            metrics.append("Test coverage: > 85%")
            metrics.append("Defect rate: < X per release")
        }
        
        // Add user experience metrics if mentioned
        if combined.contains("user") || combined.contains("experience") || combined.contains("usability") {
            metrics.append("User satisfaction: > 4.5/5")
            metrics.append("Task completion rate: > 95%")
        }
        
        // Add security metrics if mentioned
        if combined.contains("security") || combined.contains("auth") || combined.contains("privacy") {
            metrics.append("Security vulnerabilities: 0 critical")
            metrics.append("Compliance adherence: 100%")
        }
        
        // Add data metrics if mentioned
        if combined.contains("data") || combined.contains("analytics") || combined.contains("report") {
            metrics.append("Data accuracy: > 99%")
            metrics.append("Processing time: < X minutes")
        }
        
        // If no specific metrics identified, use generic ones
        if metrics.count <= 2 {
            metrics.append("Success rate: > 95%")
            metrics.append("Time to completion: < X days")
            metrics.append("Resource utilization: < budget")
        }
        
        return metrics
    }
    
}
