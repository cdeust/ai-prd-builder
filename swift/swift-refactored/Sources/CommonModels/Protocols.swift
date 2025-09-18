import Foundation

// MARK: - Core Provider Protocol

public protocol AIProvider {
    var name: String { get }
    func sendMessages(_ messages: [ChatMessage]) async -> Result<String, AIProviderError>
}

public extension AIProvider {
    func sendMessage(_ message: String) async -> Result<String, AIProviderError> {
        let messages = [ChatMessage(role: .user, content: message)]
        return await sendMessages(messages)
    }
}

// MARK: - Orchestration Protocol

public protocol OrchestrationProtocol {
    func process(prompt: String) async throws -> String
    func validate(response: String) async throws -> ValidationResult
}

// MARK: - Thinking Protocol

public protocol ThinkingProtocol {
    func think(about input: String) async throws -> ThoughtChain
    func reason(with context: [String: Any]) async throws -> ReasoningResult
}

// MARK: - Generation Protocols

public protocol PRDGeneratorProtocol {
    func generatePRD(from input: String) async throws -> PRDocument
}

public protocol OpenAPIGeneratorProtocol {
    func generateSpec(from prd: PRDocument) async throws -> OpenAPISpecification
}

public protocol TestGeneratorProtocol {
    func generateTests(for spec: OpenAPISpecification) async throws -> TestSuite
}

// MARK: - Supporting Types

public struct ValidationResult {
    public let isValid: Bool
    public let errors: [ValidationError]
    public let warnings: [String]

    public init(isValid: Bool, errors: [ValidationError] = [], warnings: [String] = []) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
    }
}

public struct ThoughtChain {
    public let thoughts: [Thought]
    public let conclusion: String
    public let confidence: Double

    public init(thoughts: [Thought], conclusion: String, confidence: Double) {
        self.thoughts = thoughts
        self.conclusion = conclusion
        self.confidence = confidence
    }
}

public struct Thought {
    public let content: String
    public let type: ThoughtType
    public let timestamp: Date

    public enum ThoughtType {
        case analysis
        case hypothesis
        case validation
        case conclusion
    }

    public init(content: String, type: ThoughtType, timestamp: Date = Date()) {
        self.content = content
        self.type = type
        self.timestamp = timestamp
    }
}

public struct ReasoningResult {
    public let decision: String
    public let rationale: [String]
    public let alternatives: [String]

    public init(decision: String, rationale: [String], alternatives: [String] = []) {
        self.decision = decision
        self.rationale = rationale
        self.alternatives = alternatives
    }
}

public struct PRDocument {
    public let title: String
    public let sections: [PRDSection]
    public let metadata: [String: Any]

    public init(title: String, sections: [PRDSection], metadata: [String: Any] = [:]) {
        self.title = title
        self.sections = sections
        self.metadata = metadata
    }
}

public struct PRDSection {
    public let title: String
    public let content: String
    public let subsections: [PRDSection]

    public init(title: String, content: String, subsections: [PRDSection] = []) {
        self.title = title
        self.content = content
        self.subsections = subsections
    }
}

public struct OpenAPISpecification {
    public let version: String
    public let info: [String: Any]
    public let paths: [String: Any]
    public let components: [String: Any]

    public init(version: String = "3.1.0", info: [String: Any], paths: [String: Any], components: [String: Any] = [:]) {
        self.version = version
        self.info = info
        self.paths = paths
        self.components = components
    }
}

public struct TestSuite {
    public let name: String
    public let tests: [TestCase]

    public init(name: String, tests: [TestCase]) {
        self.name = name
        self.tests = tests
    }
}

public struct TestCase {
    public let name: String
    public let description: String
    public let steps: [String]
    public let expectedResult: String

    public init(name: String, description: String, steps: [String], expectedResult: String) {
        self.name = name
        self.description = description
        self.steps = steps
        self.expectedResult = expectedResult
    }
}