import Foundation

/// Simple glossary for acronym definitions with optional domain
public struct Glossary: Sendable {
    public struct Entry: Sendable {
        public let acronym: String
        public let definition: String
        public let context: String
        public let usage: String

        public init(
            acronym: String,
            definition: String,
            context: String = "",
            usage: String = ""
        ) {
            self.acronym = acronym
            self.definition = definition
            self.context = context
            self.usage = usage
        }
    }

    public var domain: String
    public var entries: [Entry]
    private let acronyms: [String: String]

    public init() {
        // Try to load from configuration
        let loader = BundleGlossaryLoader()
        if let config = try? loader.load() {
            self.acronyms = config.acronyms
            self.domain = "default"
            self.entries = config.acronyms.map { Entry(acronym: $0.key, definition: $0.value) }
        } else {
            // No configuration file, start empty
            self.acronyms = [:]
            self.domain = "default"
            self.entries = []
        }
    }

    public init(domain: String, entries: [Entry]) {
        self.domain = domain
        self.entries = entries
        var acronymsMap: [String: String] = [:]
        for entry in entries {
            acronymsMap[entry.acronym] = entry.definition
        }
        self.acronyms = acronymsMap
    }

    public init(acronyms: [String: String]) {
        self.acronyms = acronyms
        self.domain = "default"
        self.entries = acronyms.map { Entry(acronym: $0.key, definition: $0.value) }
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
