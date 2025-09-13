import Foundation

public actor DomainGlossary: Sendable {
    public enum Domain: String, CaseIterable, Sendable {
        case product
        case engineering
        case design
        case marketing
    }
    
    public struct Entry: Hashable, Sendable {
        public let acronym: String
        public let expansion: String
        public init(acronym: String, expansion: String) {
            self.acronym = acronym.uppercased()
            self.expansion = expansion
        }
    }
    
    // Injected defaults for all domains
    private let defaultsByDomain: [Domain: [String: String]]
    
    private(set) public var domain: Domain
    // Default entries for the selected domain
    private var defaults: [String: String]
    // User overrides (session-scoped)
    private var overrides: [String: String] = [:]
    
    /// Designated initializer with injected defaults per domain
    public init(
        defaultsByDomain: [Domain: [String: String]],
        domain: Domain = .product
    ) {
        self.defaultsByDomain = defaultsByDomain
        self.domain = domain
        self.defaults = defaultsByDomain[domain]?.normalizedKeys() ?? [:]
    }
    
    /// Initializer that prefers bundled Glossary.yaml, falls back to Glossary.json, then minimal default.
    /// If loading fails, it initializes with empty defaults.
    public init(domain: Domain = .product) {
        // Prefer YAML first, then JSON, then empty/default
        var loaded: [Domain: [String: String]] = [:]
        var loadedSuccessfully = false
        
        // Try YAML if available
        #if canImport(Yams)
        do {
            let yamlLoader = BundleYAMLGlossaryLoader()
            if let config = try? yamlLoader.load(), let mapped = config.mapToDomains() {
                loaded = mapped
                loadedSuccessfully = true
            }
        }
        #endif
        
        // Fallback to JSON if YAML missing or failed
        if !loadedSuccessfully {
            let jsonLoader = BundleGlossaryLoader()
            if let config = try? jsonLoader.load(), let mapped = config.mapToDomains() {
                loaded = mapped
                loadedSuccessfully = true
            }
        }
        
        // If both failed, try using the tiny in-code default as a last resort
        if !loadedSuccessfully {
            let fallback = GlossaryConfiguration.default
            if let mapped = fallback.mapToDomains() {
                loaded = mapped
            } else {
                loaded = [:]
            }
        }
        
        self.init(defaultsByDomain: loaded, domain: domain)
    }
    
    public func setDomain(_ newDomain: Domain) {
        self.domain = newDomain
        self.defaults = defaultsByDomain[newDomain]?.normalizedKeys() ?? [:]
        // Keep overrides so user customizations persist across domain changes in the same session
    }
    
    public func addOverride(acronym: String, expansion: String) {
        overrides[acronym.uppercased()] = expansion
    }
    
    public func resolve(_ acronym: String) -> String? {
        let key = acronym.uppercased()
        if let v = overrides[key] { return v }
        return defaults[key]
    }
    
    public func list() -> [Entry] {
        // Combine overrides over defaults
        var combined = defaults
        for (k, v) in overrides { combined[k.uppercased()] = v }
        return combined.keys.sorted().map { Entry(acronym: $0, expansion: combined[$0] ?? "") }
    }
    
    public func summary(max: Int = 8) -> String {
        let items = list().prefix(max).map { "\($0.acronym)=\($0.expansion)" }
        return items.joined(separator: ", ")
    }
}

private extension Dictionary where Key == String, Value == String {
    /// Normalize keys to uppercased to ensure consistent acronym lookups
    func normalizedKeys() -> [String: String] {
        var out: [String: String] = [:]
        for (k, v) in self {
            out[k.uppercased()] = v
        }
        return out
    }
}

private extension GlossaryConfiguration {
    /// Map from configuration domain strings to Domain enum keys.
    /// Ignores unknown domains. Normalizes acronym keys to uppercase.
    func mapToDomains() -> [DomainGlossary.Domain: [String: String]]? {
        var result: [DomainGlossary.Domain: [String: String]] = [:]
        for (key, value) in domains {
            guard let domain = DomainGlossary.Domain(rawValue: key.lowercased()) else { continue }
            result[domain] = value
        }
        return result
    }
}
