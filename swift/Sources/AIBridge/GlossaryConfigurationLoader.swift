import Foundation

public protocol GlossaryConfigurationLoader {
    func load() throws -> GlossaryConfiguration
}

/// Default config to ship in code as a safety net (used if file missing and fallback enabled)
/// Keep this intentionally tiny so that real content must come from the external file.
public extension GlossaryConfiguration {
    static var `default`: GlossaryConfiguration {
        GlossaryConfiguration(domains: [
            "product": [
                "PRD": "Product Requirements Document"
            ]
        ])
    }
}

/// Loads Glossary.json from the main bundle by default.
/// Place a file named "Glossary.json" in your app bundle (Copy Bundle Resources).
public struct BundleGlossaryLoader: GlossaryConfigurationLoader {
    private let resourceName: String
    private let resourceExtension: String
    private let defaultFallback: Bool
    
    public init(
        resourceName: String = "Glossary",
        resourceExtension: String = "json",
        defaultFallback: Bool = true
    ) {
        self.resourceName = resourceName
        self.resourceExtension = resourceExtension
        self.defaultFallback = defaultFallback
    }
    
    public func load() throws -> GlossaryConfiguration {
        let bundle = Bundle.main
        guard let url = bundle.url(forResource: resourceName, withExtension: resourceExtension) else {
            if defaultFallback {
                return .default
            }
            throw NSError(
                domain: "GlossaryLoader",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Glossary file not found in bundle: \(resourceName).\(resourceExtension). Please add Glossary.\(resourceExtension) to the app target’s Copy Bundle Resources."]
            )
        }
        do {
            let data = try Data(contentsOf: url)
            let config = try JSONDecoder().decode(GlossaryConfiguration.self, from: data)
            // Basic validation
            if config.domains.isEmpty {
                if defaultFallback { return .default }
                throw NSError(
                    domain: "GlossaryLoader",
                    code: 422,
                    userInfo: [NSLocalizedDescriptionKey: "Glossary file is empty. Provide at least one domain with entries."]
                )
            }
            return config
        } catch let DecodingError.dataCorrupted(ctx) {
            if defaultFallback { return .default }
            throw NSError(
                domain: "GlossaryLoader",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Glossary JSON is malformed: \(ctx.debugDescription)"]
            )
        } catch let DecodingError.keyNotFound(key, ctx) {
            if defaultFallback { return .default }
            throw NSError(
                domain: "GlossaryLoader",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Missing key '\(key.stringValue)' in Glossary JSON: \(ctx.debugDescription)"]
            )
        } catch let DecodingError.typeMismatch(type, ctx) {
            if defaultFallback { return .default }
            throw NSError(
                domain: "GlossaryLoader",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Type mismatch for \(type) in Glossary JSON: \(ctx.debugDescription)"]
            )
        } catch let DecodingError.valueNotFound(type, ctx) {
            if defaultFallback { return .default }
            throw NSError(
                domain: "GlossaryLoader",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Missing value for \(type) in Glossary JSON: \(ctx.debugDescription)"]
            )
        } catch {
            if defaultFallback {
                return .default
            }
            throw NSError(
                domain: "GlossaryLoader",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to load Glossary: \(error.localizedDescription)"]
            )
        }
    }
}

/// Loads glossary configuration from an absolute file path (JSON)
public struct FileGlossaryLoader: GlossaryConfigurationLoader {
    private let filePath: String
    
    public init(filePath: String) {
        self.filePath = filePath
    }
    
    public func load() throws -> GlossaryConfiguration {
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(GlossaryConfiguration.self, from: data)
    }
}

#if canImport(Yams)
import Yams

/// Loads Glossary.yaml from the main bundle (preferred for business editing).
/// Place a file named "Glossary.yaml" in your app bundle (Copy Bundle Resources).
public struct BundleYAMLGlossaryLoader: GlossaryConfigurationLoader {
    private let resourceName: String
    private let resourceExtension: String
    private let defaultFallback: Bool
    
    public init(
        resourceName: String = "Glossary",
        resourceExtension: String = "yaml",
        defaultFallback: Bool = true
    ) {
        self.resourceName = resourceName
        self.resourceExtension = resourceExtension
        self.defaultFallback = defaultFallback
    }
    
    public func load() throws -> GlossaryConfiguration {
        let bundle = Bundle.main
        guard let url = bundle.url(forResource: resourceName, withExtension: resourceExtension) else {
            if defaultFallback { return .default }
            throw NSError(
                domain: "GlossaryLoader",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Glossary YAML not found in bundle: \(resourceName).\(resourceExtension). Please add Glossary.\(resourceExtension) to Copy Bundle Resources."]
            )
        }
        do {
            let data = try Data(contentsOf: url)
            guard let yamlString = String(data: data, encoding: .utf8) else {
                if defaultFallback { return .default }
                throw NSError(domain: "GlossaryLoader", code: 415, userInfo: [NSLocalizedDescriptionKey: "Invalid encoding for YAML (expected UTF-8)."])
            }
            let decoded = try Yams.load(yaml: yamlString)
            // Convert YAML -> JSON data -> decode with JSONDecoder to reuse the model
            let jsonData = try JSONSerialization.data(withJSONObject: decoded as Any, options: [])
            let config = try JSONDecoder().decode(GlossaryConfiguration.self, from: jsonData)
            if config.domains.isEmpty {
                if defaultFallback { return .default }
                throw NSError(domain: "GlossaryLoader", code: 422, userInfo: [NSLocalizedDescriptionKey: "Glossary YAML is empty. Provide at least one domain with entries."])
            }
            return config
        } catch let error as YamlError {
            if defaultFallback { return .default }
            throw NSError(domain: "GlossaryLoader", code: 400, userInfo: [NSLocalizedDescriptionKey: "Glossary YAML is malformed: \(error)"])
        } catch {
            if defaultFallback { return .default }
            throw NSError(domain: "GlossaryLoader", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to load Glossary YAML: \(error.localizedDescription)"])
        }
    }
}
#endif
