import Foundation

/// Performs structural validation on OpenAPI specifications
/// Checks for syntactic correctness and structural requirements
public class OpenAPIStructuralValidator {

    // MARK: - Properties

    private let validationPatterns: OpenAPIValidationPatterns

    // MARK: - Initialization

    public init() {
        self.validationPatterns = OpenAPIValidationPatterns()
    }

    // MARK: - Public Interface

    public func validate(_ spec: String) -> [String] {
        var issues: [String] = []
        let lines = spec.components(separatedBy: .newlines)

        // Perform all validation checks
        issues.append(contentsOf: validateDuplicatePaths(in: lines))
        issues.append(contentsOf: validateHttpMethods(in: lines))
        issues.append(contentsOf: validateComponentsStructure(in: spec))
        issues.append(contentsOf: validateRequiredFields(in: spec))
        issues.append(contentsOf: validateSchemaDefinitions(in: spec))
        issues.append(contentsOf: validateResponseStructure(in: spec, lines: lines))
        issues.append(contentsOf: validateSecurityDefinitions(in: spec))
        issues.append(contentsOf: validateOperationalCompleteness(in: spec))
        issues.append(contentsOf: validateContentTypes(in: spec))

        return issues
    }

    // MARK: - Path Validation

    private func validateDuplicatePaths(in lines: [String]) -> [String] {
        var issues: [String] = []
        var pathCounts: [String: Int] = [:]

        for line in lines {
            if let pathMatch = line.range(of: validationPatterns.pathPattern, options: .regularExpression) {
                let path = String(line[pathMatch]).trimmingCharacters(in: .whitespaces).dropLast()
                pathCounts[String(path), default: OpenAPIPromptConstants.Indices.firstElement] += OpenAPIPromptConstants.Indices.issueNumberOffset
            }
        }

        for (path, count) in pathCounts where count > OpenAPIPromptConstants.Indices.issueNumberOffset {
            issues.append(formatDuplicatePathIssue(path: path, count: count))
        }

        return issues
    }

    private func formatDuplicatePathIssue(path: String, count: Int) -> String {
        return "❌ Path '\(path)' defined \(count) times. Fix: Merge all HTTP methods under a single path definition."
    }

    // MARK: - HTTP Method Validation

    private func validateHttpMethods(in lines: [String]) -> [String] {
        var issues: [String] = []
        var currentMethod = ""
        var currentPath = ""

        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Track current path
            if trimmedLine.starts(with: "/") && trimmedLine.contains(":") {
                currentPath = trimmedLine.components(separatedBy: ":").first ?? ""
            }

            // Track current method
            currentMethod = extractHttpMethod(from: trimmedLine)

            // Check for requestBody in GET
            if currentMethod == "GET" && trimmedLine.starts(with: "requestBody:") {
                issues.append(formatGetRequestBodyIssue(
                    path: currentPath,
                    lineNumber: index + OpenAPIPromptConstants.Indices.issueNumberOffset
                ))
            }
        }

        return issues
    }

    private func extractHttpMethod(from line: String) -> String {
        for method in DecisionTreeConstants.HTTPMethods.all {
            if line == "\(method):" {
                return method.uppercased()
            }
        }

        return ""
    }

    private func formatGetRequestBodyIssue(path: String, lineNumber: Int) -> String {
        return "❌ GET \(path) has requestBody at line \(lineNumber). Fix: Remove requestBody from GET operations - use query parameters instead."
    }

    // MARK: - Components Structure Validation

    private func validateComponentsStructure(in spec: String) -> [String] {
        var issues: [String] = []

        let hasComponents = spec.contains("components:")
        let hasSecuritySchemes = spec.contains("securitySchemes:")
        let hasSchemas = spec.contains("schemas:") && !hasComponents

        if hasSecuritySchemes && !hasComponents {
            issues.append(ValidationMessages.missingComponentsSection)
        } else if hasSecuritySchemes && hasComponents {
            if !isSecuritySchemesProperlyNested(in: spec) {
                issues.append(ValidationMessages.improperSecuritySchemesNesting)
            }
        }

        if hasSchemas {
            issues.append(ValidationMessages.schemasNotUnderComponents)
        }

        return issues
    }

    private func isSecuritySchemesProperlyNested(in spec: String) -> Bool {
        return spec.contains("components:\n  securitySchemes:") ||
               spec.contains("components:\r\n  securitySchemes:") ||
               spec.contains("components:\n    securitySchemes:")
    }

    // MARK: - Required Fields Validation

    private func validateRequiredFields(in spec: String) -> [String] {
        var issues: [String] = []

        let requiredFields = [
            ("openapi:", ValidationMessages.missingOpenAPIVersion),
            ("info:", ValidationMessages.missingInfoSection),
            ("paths:", ValidationMessages.missingPathsSection)
        ]

        for (field, message) in requiredFields {
            if !spec.contains(field) {
                issues.append(message)
            }
        }

        // Check for info section completeness
        if spec.contains("info:") {
            if !spec.contains("title:") {
                issues.append(ValidationMessages.missingTitle)
            }
            if !spec.contains("description:") {
                issues.append(ValidationMessages.missingDescription)
            }
        }

        return issues
    }

    // MARK: - Schema Definition Validation

    private func validateSchemaDefinitions(in spec: String) -> [String] {
        var issues: [String] = []

        // Check for invalid schema patterns
        if spec.contains("possibleValues:") {
            issues.append(ValidationMessages.invalidPossibleValues)
        }

        if spec.contains("properties: [") {
            issues.append(ValidationMessages.propertiesAsArray)
        }

        // Check for parameter descriptions
        if spec.contains("parameters:") && !hasParameterDescriptions(in: spec) {
            issues.append(ValidationMessages.missingParameterDescriptions)
        }

        // Check for examples
        if !spec.contains("example:") && !spec.contains("examples:") {
            issues.append(ValidationMessages.missingExamples)
        }

        return issues
    }

    private func hasParameterDescriptions(in spec: String) -> Bool {
        let parameterSections = spec.components(separatedBy: "parameters:")
        for section in parameterSections.dropFirst().prefix(OpenAPIPromptConstants.Limits.prefixCount) {
            if section.contains("description:") {
                return true
            }
        }
        return false
    }

    // MARK: - Response Structure Validation

    private func validateResponseStructure(in spec: String, lines: [String]) -> [String] {
        var issues: [String] = []

        if spec.contains("responses:") {
            // Check for unquoted status codes
            if spec.range(of: validationPatterns.unquotedStatusCodePattern, options: .regularExpression) != nil {
                issues.append(ValidationMessages.unquotedStatusCodes)
            }

            // Check for missing standard responses
            let standardResponses = [
                ("'\(OpenAPIPromptConstants.StatusCodes.success)'", "\"\(OpenAPIPromptConstants.StatusCodes.success)\"", "\(OpenAPIPromptConstants.StatusCodes.successNumeric):", ValidationMessages.missing200Response),
                ("'\(OpenAPIPromptConstants.StatusCodes.badRequest)'", "\"\(OpenAPIPromptConstants.StatusCodes.badRequest)\"", "\(OpenAPIPromptConstants.StatusCodes.badRequestNumeric):", ValidationMessages.missing400Response)
            ]

            for (quoted1, quoted2, unquoted, message) in standardResponses {
                if !spec.contains(quoted1) && !spec.contains(quoted2) && !spec.contains(unquoted) {
                    issues.append(message)
                }
            }

            // Check for response descriptions
            if !hasResponseDescriptions(in: spec) {
                issues.append(ValidationMessages.missingResponseDescriptions)
            }
        }

        // Check response content structure
        if spec.range(of: validationPatterns.responsePattern, options: .regularExpression) != nil {
            if !spec.contains("application/json:") {
                issues.append(ValidationMessages.missingContentType)
            }
        }

        return issues
    }

    private func hasResponseDescriptions(in spec: String) -> Bool {
        return spec.contains("responses:") && spec.contains("description:")
    }

    // MARK: - Security Validation

    private func validateSecurityDefinitions(in spec: String) -> [String] {
        var issues: [String] = []

        let hasAuthenticationMentioned = spec.contains("bearer") ||
                                        spec.contains("Bearer") ||
                                        spec.contains("apiKey")

        if hasAuthenticationMentioned && !spec.contains("securitySchemes:") {
            issues.append(ValidationMessages.missingSecuritySchemes)
        }

        return issues
    }

    // MARK: - Operational Completeness

    private func validateOperationalCompleteness(in spec: String) -> [String] {
        var issues: [String] = []

        if !spec.contains("operationId:") {
            issues.append(ValidationMessages.missingOperationIds)
        }

        return issues
    }

    // MARK: - Content Type Validation

    private func validateContentTypes(in spec: String) -> [String] {
        var issues: [String] = []

        if spec.contains("content:") && !spec.contains("application/json") {
            issues.append(ValidationMessages.noJsonContentType)
        }

        return issues
    }
}

// MARK: - Validation Patterns

private struct OpenAPIValidationPatterns {
    let pathPattern = "^\\s*(/[^:]+):"
    let unquotedStatusCodePattern = "responses:\\s*\\n\\s*(\\d{3}):"
    let responsePattern = "responses:\\s*\\n\\s*'?\\d+"
}

// MARK: - Validation Messages

private enum ValidationMessages {
    // Critical errors
    static let missingOpenAPIVersion = OpenAPIPromptConstants.Messages.missingOpenAPIVersion
    static let missingInfoSection = "❌ Missing 'info' section. Fix: Add info with title, description, and version."
    static let missingPathsSection = "❌ Missing 'paths' section. Fix: Add paths section with at least one endpoint."
    static let missingComponentsSection = "❌ Missing components section - securitySchemes must be under components"
    static let missingSecuritySchemes = "❌ Authentication mentioned but no securitySchemes defined. Fix: Add security schemes under components."
    static let invalidPossibleValues = "❌ Invalid 'possibleValues'. Fix: Use 'enum' keyword for allowed values."
    static let propertiesAsArray = "❌ Properties defined as array. Fix: Use object syntax - properties: { field: { type: string } }"

    // Warnings
    static let improperSecuritySchemesNesting = "⚠️ securitySchemes must be properly nested under components section"
    static let schemasNotUnderComponents = "⚠️ Schema definitions should be under components.schemas"
    static let missingTitle = "⚠️ Missing 'title' in info section. This helps LLMs understand the API purpose."
    static let missingDescription = "⚠️ Missing 'description' in info section. Add detailed API description for better LLM comprehension."
    static let missingParameterDescriptions = "⚠️ Parameters missing descriptions. LLMs need parameter descriptions to understand usage."
    static let unquotedStatusCodes = OpenAPIPromptConstants.Messages.unquotedStatusCodes
    static let missing200Response = OpenAPIPromptConstants.Messages.missing200Response
    static let missing400Response = OpenAPIPromptConstants.Messages.missing400Response
    static let missingResponseDescriptions = "⚠️ Response definitions lack descriptions. LLMs need these to understand responses."
    static let missingContentType = "⚠️ Response definitions missing content type (application/json)"
    static let noJsonContentType = "⚠️ No application/json content type found. Most LLMs expect JSON responses."

    // Recommendations
    static let missingOperationIds = "💡 Missing operationId fields. These help LLMs uniquely identify and call operations."
    static let missingExamples = "💡 Consider adding 'example' values to help LLMs understand expected data formats."
}