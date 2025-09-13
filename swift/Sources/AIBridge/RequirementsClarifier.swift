import Foundation

public enum RequirementsClarifier {
    public static func proposeClarifyingQuestions(
        feature: String,
        context: String,
        requirements: [String]
    ) -> [String] {
        let text = "\(feature) \(context) \(requirements.joined(separator: " "))".lowercased()
        var qs: [String] = []
        
        // Realtime vs batch
        if text.contains("analytics") || text.contains("stream") || text.contains("events") || text.contains("processing") {
            qs.append("Do you require real-time streaming (sub-second) or batch processing? What is acceptable end-to-end latency?")
        }
        
        // Integrations
        if text.contains("integration") || text.contains("workflow") || text.contains("ticket") || text.contains("sync") {
            qs.append("Which integrations are must-have at launch (e.g., Jira, Confluence, GitHub, Slack, Okta, Salesforce)?")
        }
        
        // Data retention / PII
        if text.contains("user") || text.contains("data") || text.contains("pii") || text.contains("privacy") || text.contains("compliance") {
            qs.append("What data retention policy applies? Any PII/PHI considerations (GDPR/SOC2/HIPAA)?")
        }
        
        // Platform targets
        if text.contains("mobile") || text.contains("desktop") || text.contains("web") || text.contains("app") {
            qs.append("Which client platforms are in scope at launch (iOS, iPadOS, macOS, web)? Any offline requirements?")
        }
        
        // SLAs
        if text.contains("api") || text.contains("service") || text.contains("platform") {
            qs.append("What SLAs are required (availability, p95 latency, error budgets)?")
        }
        
        return qs
    }
}
