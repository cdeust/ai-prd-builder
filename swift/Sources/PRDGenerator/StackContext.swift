import Foundation

/// Represents the technical stack and context discovered during PRD generation
public struct StackContext {
    /// Primary programming language for the project
    public let language: String

    /// Testing framework to be used
    public let testFramework: String?

    /// CI/CD pipeline configuration
    public let cicdPipeline: String?

    /// Deployment target and environment
    public let deployment: String?

    /// Database and storage solution
    public let database: String?

    /// Security requirements and standards
    public let security: String?

    /// Performance requirements and SLAs
    public let performance: String?

    /// External integrations and dependencies
    public let integrations: [String]

    /// Discovery questions generated for clarification
    public let questions: String

    public init(
        language: String,
        testFramework: String? = nil,
        cicdPipeline: String? = nil,
        deployment: String? = nil,
        database: String? = nil,
        security: String? = nil,
        performance: String? = nil,
        integrations: [String] = [],
        questions: String = ""
    ) {
        self.language = language
        self.testFramework = testFramework
        self.cicdPipeline = cicdPipeline
        self.deployment = deployment
        self.database = database
        self.security = security
        self.performance = performance
        self.integrations = integrations
        self.questions = questions
    }
}