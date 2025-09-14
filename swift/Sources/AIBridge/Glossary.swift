import Foundation

/// Simple glossary for acronym definitions without domain complexity
public struct Glossary: Sendable {
    public struct Entry: Sendable {
        public let acronym: String
        public let definition: String

        public init(acronym: String, definition: String) {
            self.acronym = acronym
            self.definition = definition
        }
    }

    private let acronyms: [String: String]

    public init() {
        // Try to load from configuration
        let loader = BundleGlossaryLoader()
        if let config = try? loader.load() {
            self.acronyms = config.acronyms
        } else {
            // No configuration file, start empty
            self.acronyms = [:]
        }
    }

    public init(acronyms: [String: String]) {
        self.acronyms = acronyms
    }

    public func resolve(_ text: String) -> String {
        var resolved = text
        for (acronym, definition) in acronyms {
            // Only replace whole word matches
            let pattern = "\\b\(acronym)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(resolved.startIndex..., in: resolved)
                resolved = regex.stringByReplacingMatches(
                    in: resolved,
                    range: range,
                    withTemplate: "\(acronym) (\(definition))"
                )
            }
        }
        return resolved
    }

    public func list() -> [Entry] {
        acronyms.map { Entry(acronym: $0.key, definition: $0.value) }
    }

    public func definition(for acronym: String) -> String? {
        acronyms[acronym]
    }
}
