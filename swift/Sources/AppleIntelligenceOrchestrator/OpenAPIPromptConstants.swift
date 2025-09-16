import Foundation

/// Constants for OpenAPI prompt building and formatting
public enum OpenAPIPromptConstants {

    // MARK: - HTTP Status Codes
    public enum StatusCodes {
        public static let success = "200"
        public static let badRequest = "400"
        public static let unauthorized = "401"
        public static let notFound = "404"
        public static let serverError = "500"

        public static let successNumeric = 200
        public static let badRequestNumeric = 400
        public static let unauthorizedNumeric = 401
        public static let notFoundNumeric = 404
        public static let serverErrorNumeric = 500
    }

    // MARK: - OpenAPI Version
    public enum Version {
        public static let current = "3.1.0"
        public static let versionString = "openapi: 3.1.0"
        public static let jsonSchemaVersion = "2020-12"
    }

    // MARK: - Validation Messages
    public enum Messages {
        public static let missingOpenAPIVersion = "❌ Missing 'openapi: 3.1.0' version field. Fix: Add 'openapi: 3.1.0' at the beginning."
        public static let unquotedStatusCodes = "⚠️ HTTP status codes should be quoted ('200' not 200) for YAML validity."
        public static let missing200Response = "⚠️ Missing 200 success response. LLMs need to know successful response format."
        public static let missing400Response = "⚠️ Missing 400 bad request response. Add for better error handling."

        public static let bulletPrefix = "• "
    }

    // MARK: - Generation Prompts
    public enum GenerationPrompts {
        public static let openAPIVersionPrefix = "Generate an OpenAPI "
        public static let specificationFor = " specification for: "

        public static let returnCorrectedPrefix = "Return a corrected OpenAPI "
        public static let returnFullyCorrectedPrefix = "Return a fully corrected OpenAPI "

        public static let followStandardsMessage = "• Follow OpenAPI 3.1.0 and JSON Schema 2020-12 standards"
        public static let includeStatusCodesMessage = "• Include standard HTTP status codes (200, 400, 401, 404, 500)"
    }

    // MARK: - Issue Resolution Steps
    public enum IssueResolution {
        public static let fixAllCritical = "1. Fixes all critical issues"
        public static let addressImportant = "2. Addresses important issues where possible"
        public static let maintainDescriptions = "3. Maintains LLM-friendly descriptions and examples"
        public static let followStandards = "4. Follows OpenAPI 3.1.0 and JSON Schema 2020-12 standards"
    }

    // MARK: - LLM Compatibility Checks
    public enum LLMCompatibility {
        public static let semanticClarity = "1. Semantic clarity - Can an LLM understand what each endpoint does?"
        public static let parameterCompleteness = "2. Parameter completeness - Are all parameters documented with types and descriptions?"
        public static let responseSchemas = "3. Response schemas - Are all possible responses defined with clear schemas?"
        public static let errorHandling = "4. Error handling - Are error responses documented to help LLMs recover?"
        public static let authentication = "5. Authentication - Is security properly defined and implementable?"
    }

    // MARK: - Confidence Range
    public enum Confidence {
        public static let minValue: Float = 0.0
        public static let maxValue: Float = 1.0
        public static let rangeDescription = "- Confidence: 0.0 to 1.0"
    }

    // MARK: - Parsing
    public enum Parsing {
        public static let minimumIssueLength = 5
        public static let defaultValidConfidence: Float = 0.7
        public static let percentageConversionThreshold: Float = 1.0
        public static let percentageDivisor: Float = 100.0
    }

    // MARK: - Array Indices
    public enum Indices {
        public static let firstElement = 0
        public static let firstPathApproachOffset = 1
        public static let issueNumberOffset = 1
    }

    // MARK: - Limits
    public enum Limits {
        public static let dropFirstCount = 1
        public static let prefixCount = 1
    }
}