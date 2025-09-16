import Foundation

/// Constants for OpenAPI validation and generation
public enum OpenAPIValidationConstants {

    // MARK: - MCTS Parameters
    public enum MCTS {
        public static let defaultMaxIterations = 50
        public static let explorationConstant = 1.414
        public static let maxActionsPerNode = 3
        public static let maxSimulationDepth = 10
        public static let highQualityThreshold = 0.95
        public static let progressReportInterval = 10

        // Messages
        public static let startMessage = "🌲 Starting MCTS-based OpenAPI generation..."
        public static let successMessage = "✅ Found high-quality spec at iteration %d"
        public static let iterationMessage = "  MCTS iteration %d: Best reward = %.2f"
        public static let failureMessage = "MCTS failed to find valid specification"
    }

    // MARK: - Constraint Validation
    public enum Constraints {
        public static let requiredOpenAPIVersion = "3.1.0"
        public static let requiredSections = ["info", "paths"]
        public static let recommendedSections = ["components", "servers"]

        // Error messages
        public static let missingVersionMessage = "OpenAPI version must be specified"
        public static let missingSectionMessage = "%@ section is required"
        public static let invalidReferenceMessage = "Invalid $ref: %@"
    }

    // MARK: - AST Parsing
    public enum AST {
        public static let indentationUnit = 2
        public static let maxNestingDepth = 20

        // Node types
        public static let versionKey = "openapi"
        public static let infoKey = "info"
        public static let pathsKey = "paths"
        public static let componentsKey = "components"
        public static let serversKey = "servers"
        public static let schemasKey = "schemas"
        public static let securitySchemesKey = "securitySchemes"
    }

    // MARK: - Decision Tree
    public enum DecisionTree {
        public static let structuralCategory = "structural"
        public static let securityCategory = "security"
        public static let schemaCategory = "schema"
        public static let constraintCategory = "constraint"

        // Issue patterns
        public static let pathIssuePatterns = ["path", "duplicate", "endpoint"]
        public static let securityIssuePatterns = ["security", "auth", "bearer", "apiKey"]
        public static let schemaIssuePatterns = ["schema", "property", "type", "example"]
    }

    // MARK: - Validation Thresholds
    public enum Validation {
        public static let minConfidenceThreshold: Float = 0.85
        public static let criticalSeverityWeight = 1.0
        public static let majorSeverityWeight = 0.7
        public static let minorSeverityWeight = 0.3
    }

    // MARK: - Generation Prompts
    public enum Prompts {
        public static let generateSpecTemplate = """
            Generate OpenAPI 3.1.0 specification for: %@

            Requirements:
            • Complete and valid structure
            • All operations have operationId
            • Include examples for all schemas
            • Add security definitions if needed

            Let's think step by step.
            """

        public static let fixSpecTemplate = """
            Fix this OpenAPI specification:

            Issue: %@
            Target: %@

            Current spec:
            %@

            Apply the fix while preserving all working parts.
            """
    }
}