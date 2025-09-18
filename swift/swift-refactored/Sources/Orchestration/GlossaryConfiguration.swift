import Foundation

/// Codable configuration for glossary data that business can edit (e.g., in JSON)
public struct GlossaryConfiguration: Codable, Sendable {
    /// Simple map of acronyms to their definitions
    public let acronyms: [String: String]

    public init(acronyms: [String: String]) {
        self.acronyms = acronyms
    }
}
