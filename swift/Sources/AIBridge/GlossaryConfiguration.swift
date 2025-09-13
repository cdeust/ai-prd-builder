import Foundation

/// Codable configuration for glossary data that business can edit (e.g., in JSON)
public struct GlossaryConfiguration: Codable, Sendable {
    /// Map of domain (e.g., "product", "engineering") to acronym map
    public let domains: [String: [String: String]]
    
    public init(domains: [String: [String: String]]) {
        self.domains = domains
    }
}
