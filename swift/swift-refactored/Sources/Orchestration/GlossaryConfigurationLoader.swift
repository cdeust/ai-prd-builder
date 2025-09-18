import Foundation

public protocol GlossaryConfigurationLoader: Sendable {
    func load() throws -> GlossaryConfiguration
}


/// Loads Glossary.json from the main bundle by default.
/// Place a file named "Glossary.json" in your app bundle (Copy Bundle Resources).
public struct BundleGlossaryLoader: GlossaryConfigurationLoader, Sendable {
    private let resourceName: String
    private let resourceExtension: String

    public init(
        resourceName: String = "Glossary",
        resourceExtension: String = "json"
    ) {
        self.resourceName = resourceName
        self.resourceExtension = resourceExtension
    }
    
    public func load() throws -> GlossaryConfiguration {
        let bundle = Bundle.main
        guard let url = bundle.url(forResource: resourceName, withExtension: resourceExtension) else {
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
            if config.acronyms.isEmpty {
                throw NSError(
                    domain: "GlossaryLoader",
                    code: 422,
                    userInfo: [NSLocalizedDescriptionKey: "Glossary file is empty. Provide at least one acronym."]
                )
            }
            return config
        } catch let DecodingError.dataCorrupted(ctx) {
            throw NSError(
                domain: "GlossaryLoader",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Glossary JSON is malformed: \(ctx.debugDescription)"]
            )
        } catch let DecodingError.keyNotFound(key, ctx) {
            throw NSError(
                domain: "GlossaryLoader",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Missing key '\(key.stringValue)' in Glossary JSON: \(ctx.debugDescription)"]
            )
        } catch let DecodingError.typeMismatch(type, ctx) {
            throw NSError(
                domain: "GlossaryLoader",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Type mismatch for \(type) in Glossary JSON: \(ctx.debugDescription)"]
            )
        } catch let DecodingError.valueNotFound(type, ctx) {
            throw NSError(
                domain: "GlossaryLoader",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Missing value for \(type) in Glossary JSON: \(ctx.debugDescription)"]
            )
        } catch {
            throw NSError(
                domain: "GlossaryLoader",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to load Glossary: \(error.localizedDescription)"]
            )
        }
    }
}

/// Loads glossary configuration from an absolute file path (JSON)
public struct FileGlossaryLoader: GlossaryConfigurationLoader, Sendable {
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

/// Loads glossary configuration from a YAML file path
public struct FileYAMLGlossaryLoader: GlossaryConfigurationLoader, Sendable {
    private let filePath: String

    public init(filePath: String) {
        self.filePath = filePath
    }

    public func load() throws -> GlossaryConfiguration {
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)
        guard let yamlString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "GlossaryLoader", code: 415, userInfo: [NSLocalizedDescriptionKey: "Invalid encoding for YAML (expected UTF-8)."])
        }

        // Parse YAML and extract domains
        if let decoded = try Yams.load(yaml: yamlString) as? [String: Any],
           let domains = decoded["domains"] as? [String: [String: String]] {
            // Flatten all domain entries into a single dictionary
            var allAcronyms: [String: String] = [:]
            for (_, domainAcronyms) in domains {
                allAcronyms.merge(domainAcronyms) { _, new in new }
            }
            return GlossaryConfiguration(acronyms: allAcronyms)
        }

        // Fallback to simple structure
        if let decoded = try Yams.load(yaml: yamlString) as? [String: String] {
            return GlossaryConfiguration(acronyms: decoded)
        }

        throw NSError(domain: "GlossaryLoader", code: 422, userInfo: [NSLocalizedDescriptionKey: "Invalid YAML structure for glossary"])
    }
}

/// Loads Glossary.yaml from the main bundle (preferred for business editing).
/// Place a file named "Glossary.yaml" in your app bundle (Copy Bundle Resources).
public struct BundleYAMLGlossaryLoader: GlossaryConfigurationLoader, Sendable {
    private let resourceName: String
    private let resourceExtension: String

    public init(
        resourceName: String = "Glossary",
        resourceExtension: String = "yaml"
    ) {
        self.resourceName = resourceName
        self.resourceExtension = resourceExtension
    }
    
    public func load() throws -> GlossaryConfiguration {
        let bundle = Bundle.main
        guard let url = bundle.url(forResource: resourceName, withExtension: resourceExtension) else {
            throw NSError(
                domain: "GlossaryLoader",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Glossary YAML not found in bundle: \(resourceName).\(resourceExtension). Please add Glossary.\(resourceExtension) to Copy Bundle Resources."]
            )
        }
        do {
            let data = try Data(contentsOf: url)
            guard let yamlString = String(data: data, encoding: .utf8) else {
                throw NSError(domain: "GlossaryLoader", code: 415, userInfo: [NSLocalizedDescriptionKey: "Invalid encoding for YAML (expected UTF-8)."])
            }
            let decoded = try Yams.load(yaml: yamlString)
            // Convert YAML -> JSON data -> decode with JSONDecoder to reuse the model
            let jsonData = try JSONSerialization.data(withJSONObject: decoded as Any, options: [])
            let config = try JSONDecoder().decode(GlossaryConfiguration.self, from: jsonData)
            if config.acronyms.isEmpty {
                throw NSError(domain: "GlossaryLoader", code: 422, userInfo: [NSLocalizedDescriptionKey: "Glossary YAML is empty. Provide at least one acronym."])
            }
            return config
        } catch let error as YamlError {
            throw NSError(domain: "GlossaryLoader", code: 400, userInfo: [NSLocalizedDescriptionKey: "Glossary YAML is malformed: \(error)"])
        } catch {
            throw NSError(domain: "GlossaryLoader", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to load Glossary YAML: \(error.localizedDescription)"])
        }
    }
}
#endif
