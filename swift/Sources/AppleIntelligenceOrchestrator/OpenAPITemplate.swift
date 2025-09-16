import Foundation

/// OpenAPI Template System for generating valid specifications
public class OpenAPITemplate {

    // MARK: - Properties

    private let baseTemplate: String
    private let resourceTemplate: String

    // MARK: - Initialization

    public init() {
        self.baseTemplate = OpenAPITemplateConstants.baseTemplate
        self.resourceTemplate = OpenAPITemplateConstants.resourceBlockTemplate
    }

    // MARK: - Public Interface

    /// Generate OpenAPI spec from template with replacements
    public func generate(from context: OpenAPIContext) -> String {
        var result = baseTemplate

        // Replace service metadata
        result = replaceServiceMetadata(in: result, context: context)

        // Generate paths for each resource
        let pathsContent = generatePaths(for: context.resources)
        result = result.replacingOccurrences(
            of: OpenAPITemplateConstants.Placeholders.pathsBlock,
            with: pathsContent
        )

        // Generate schemas for each resource
        let schemasContent = generateSchemas(for: context.resources)
        result = result.replacingOccurrences(
            of: OpenAPITemplateConstants.Placeholders.schemasBlock,
            with: schemasContent
        )

        return result
    }

    /// Extract context from user input for template filling
    public func extractContext(from input: String) -> OpenAPIContext {
        // Extract service information
        let title = extractTitle(from: input)
        let description = extractDescription(from: input)

        // Always ensure we have at least one resource
        let resources = extractResources(from: input)
        let finalResources = resources.isEmpty ? [createDefaultResource()] : resources

        return OpenAPIContext(
            title: title,
            version: "1.0.0",
            description: description,
            serverUrl: "https://api.example.com",
            resources: finalResources
        )
    }

    // MARK: - Private Template Processing

    private func replaceServiceMetadata(in template: String, context: OpenAPIContext) -> String {
        return template
            .replacingOccurrences(of: "<SERVICE_TITLE>", with: context.title)
            .replacingOccurrences(of: "<SEMVER>", with: context.version)
            .replacingOccurrences(of: "<ONE_SENTENCE_DESCRIPTION>", with: context.description)
            .replacingOccurrences(of: "<HTTPS_URL>", with: context.serverUrl)
    }

    private func generatePaths(for resources: [OpenAPIResource]) -> String {
        return resources.map { resource in
            generateResourcePaths(resource)
        }.joined(separator: "\n")
    }

    private func generateResourcePaths(_ resource: OpenAPIResource) -> String {
        let pathTemplate = OpenAPITemplateConstants.pathTemplate

        return pathTemplate
            .replacingOccurrences(of: "<resPlural>", with: resource.pluralName)
            .replacingOccurrences(of: "<ResPluralPascal>", with: resource.pluralPascalCase)
            .replacingOccurrences(of: "<Res>", with: resource.singularName)
            .replacingOccurrences(of: "<ResPascal>", with: resource.singularPascalCase)
    }

    private func generateSchemas(for resources: [OpenAPIResource]) -> String {
        return resources.map { resource in
            generateResourceSchemas(resource)
        }.joined(separator: "\n")
    }

    private func generateResourceSchemas(_ resource: OpenAPIResource) -> String {
        let schemaTemplate = OpenAPITemplateConstants.schemaTemplate

        // Generate properties for the resource
        let propertiesYAML = resource.properties.map { prop in
            "        \(prop.name): { type: \(prop.type)\(prop.format != nil ? ", format: \(prop.format!)" : "") }"
        }.joined(separator: "\n")

        // Generate required fields
        let requiredFields = resource.properties
            .filter { $0.required }
            .map { "\"\($0.name)\"" }
            .joined(separator: ", ")

        return schemaTemplate
            .replacingOccurrences(of: "<Res>", with: resource.singularName)
            .replacingOccurrences(of: "<PROPERTIES>", with: propertiesYAML)
            .replacingOccurrences(of: "<REQUIRED_FIELDS>", with: requiredFields)
    }

    // MARK: - Context Extraction

    private func extractTitle(from input: String) -> String {
        // Look for service/API name patterns
        let patterns = [
            "service for (.+)",
            "API for (.+)",
            "(.+) service",
            "(.+) API"
        ]

        for pattern in patterns {
            if let range = input.range(of: pattern, options: .regularExpression) {
                let match = String(input[range])
                // Extract captured group
                if let titleRange = match.range(of: "[A-Za-z0-9 ]+", options: .regularExpression) {
                    return String(match[titleRange])
                }
            }
        }

        return "API Service"
    }

    private func extractDescription(from input: String) -> String {
        // Generate concise description
        let lines = input.components(separatedBy: .newlines)
        if let firstLine = lines.first(where: { !$0.isEmpty }) {
            return String(firstLine.prefix(100))
        }
        return "API service for managing resources"
    }

    private func extractResources(from input: String) -> [OpenAPIResource] {
        var resources: [OpenAPIResource] = []

        // Look for resource mentions
        let resourcePatterns = [
            "manage ([a-z]+)",
            "([a-z]+) management",
            "CRUD for ([a-z]+)",
            "([a-z]+) operations"
        ]

        var foundResources = Set<String>()

        for pattern in resourcePatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let matches = regex?.matches(in: input, options: [], range: NSRange(location: 0, length: input.count)) ?? []

            for match in matches {
                if match.numberOfRanges > 1,
                   let range = Range(match.range(at: 1), in: input) {
                    let resourceName = String(input[range]).lowercased()
                    foundResources.insert(resourceName)
                }
            }
        }

        // Convert found resources to OpenAPIResource objects
        for name in foundResources {
            resources.append(createResource(from: name))
        }

        // Always return found resources (empty check is now in extractContext)

        return resources
    }

    private func createDefaultResource() -> OpenAPIResource {
        return OpenAPIResource(
            singularName: "prd",
            pluralName: "prds",
            singularPascalCase: "PRD",
            pluralPascalCase: "PRDs",
            properties: OpenAPIGenerationHelpers.generateDefaultProperties(for: "prd")
        )
    }

    private func createResource(from name: String) -> OpenAPIResource {
        let singular = name
        let plural = OpenAPIGenerationHelpers.pluralize(name)

        return OpenAPIResource(
            singularName: singular,
            pluralName: plural,
            singularPascalCase: OpenAPIGenerationHelpers.toPascalCase(singular),
            pluralPascalCase: OpenAPIGenerationHelpers.toPascalCase(plural),
            properties: OpenAPIGenerationHelpers.generateDefaultProperties(for: singular)
        )
    }

    private func pluralize(_ word: String) -> String {
        return OpenAPIGenerationHelpers.pluralize(word)
    }

    private func toPascalCase(_ text: String) -> String {
        return OpenAPIGenerationHelpers.toPascalCase(text)
    }

    private func generateDefaultProperties(for resource: String) -> [OpenAPIProperty] {
        return OpenAPIGenerationHelpers.generateDefaultProperties(for: resource)
    }
}

// MARK: - Supporting Types

public struct OpenAPIContext {
    public let title: String
    public let version: String
    public let description: String
    public let serverUrl: String
    public let resources: [OpenAPIResource]

    public init(
        title: String,
        version: String,
        description: String,
        serverUrl: String,
        resources: [OpenAPIResource]
    ) {
        self.title = title
        self.version = version
        self.description = description
        self.serverUrl = serverUrl
        self.resources = resources
    }
}

public struct OpenAPIResource {
    public let singularName: String
    public let pluralName: String
    public let singularPascalCase: String
    public let pluralPascalCase: String
    public let properties: [OpenAPIProperty]

    public init(
        singularName: String,
        pluralName: String,
        singularPascalCase: String,
        pluralPascalCase: String,
        properties: [OpenAPIProperty]
    ) {
        self.singularName = singularName
        self.pluralName = pluralName
        self.singularPascalCase = singularPascalCase
        self.pluralPascalCase = pluralPascalCase
        self.properties = properties
    }
}

public struct OpenAPIProperty {
    public let name: String
    public let type: String
    public let required: Bool
    public let format: String?

    public init(name: String, type: String, required: Bool, format: String?) {
        self.name = name
        self.type = type
        self.required = required
        self.format = format
    }
}
