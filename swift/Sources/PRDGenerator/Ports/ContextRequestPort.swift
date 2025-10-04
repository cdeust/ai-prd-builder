import Foundation
import CommonModels
import ImplementationAnalysis

/// Port for requesting additional context from the server during PRD generation
/// Follows Dependency Inversion Principle - library defines, server implements
public protocol ContextRequestPort: Sendable {

    /// Request additional codebase context based on clarification question
    /// Uses RAG (semantic search) to find relevant code chunks
    ///
    /// - Parameters:
    ///   - projectId: Codebase project UUID
    ///   - question: Original clarification question from LLM
    ///   - searchQuery: Extracted keywords for semantic search
    /// - Returns: Codebase context response or nil if no relevant data found
    func requestCodebaseContext(
        projectId: UUID,
        question: String,
        searchQuery: String
    ) async throws -> CodebaseContextResponse?

    /// Request mockup analysis data for a specific feature
    ///
    /// - Parameters:
    ///   - requestId: PRD request UUID
    ///   - featureQuery: Feature-related keywords to filter mockup analyses
    /// - Returns: Mockup context response or nil if no relevant data found
    func requestMockupContext(
        requestId: UUID,
        featureQuery: String
    ) async throws -> MockupContextResponse?

    /// Check if additional context (codebase/mockups) is available
    ///
    /// - Parameter requestId: PRD request UUID
    /// - Returns: Availability flags and codebase project ID if linked
    func hasAdditionalContext(requestId: UUID) async -> ContextAvailability
}

// MARK: - Response Models

/// Context for a single code file
public struct CodeFileContext: Sendable {
    /// File path relative to project root
    public let filePath: String

    /// Code excerpt relevant to the query
    public let excerpt: String

    /// Purpose/description of this file
    public let purpose: String

    /// Similarity score (0.0-1.0) from semantic search
    public let similarity: Double

    public init(
        filePath: String,
        excerpt: String,
        purpose: String,
        similarity: Double
    ) {
        self.filePath = filePath
        self.excerpt = excerpt
        self.purpose = purpose
        self.similarity = similarity
    }
}

/// Result from mockup analysis
public struct MockupAnalysisResult: Sendable {
    /// Mockup file name
    public let fileName: String

    /// Extracted features from mockup
    public let features: [String]

    /// UI elements identified
    public let uiElements: [String]

    /// User flows described
    public let userFlows: [String]

    /// Full analysis text
    public let analysisText: String

    public init(
        fileName: String,
        features: [String],
        uiElements: [String],
        userFlows: [String],
        analysisText: String
    ) {
        self.fileName = fileName
        self.features = features
        self.uiElements = uiElements
        self.userFlows = userFlows
        self.analysisText = analysisText
    }
}

/// Response containing codebase context for a clarification question
public struct CodebaseContextResponse: Sendable {
    /// Relevant code file contexts (paths, excerpts, purposes)
    public let relevantFiles: [CodeFileContext]

    /// AI-generated summary answering the clarification question
    public let summary: String

    /// Confidence score (0.0-1.0) indicating relevance of found context
    public let confidence: Double

    /// Number of code chunks analyzed
    public let chunksAnalyzed: Int

    public init(
        relevantFiles: [CodeFileContext],
        summary: String,
        confidence: Double,
        chunksAnalyzed: Int
    ) {
        self.relevantFiles = relevantFiles
        self.summary = summary
        self.confidence = confidence
        self.chunksAnalyzed = chunksAnalyzed
    }
}

/// Response containing mockup context for a feature query
public struct MockupContextResponse: Sendable {
    /// Relevant mockup analyses matching the feature query
    public let relevantAnalyses: [MockupAnalysisResult]

    /// AI-generated summary of mockup insights
    public let summary: String

    /// Confidence score (0.0-1.0)
    public let confidence: Double

    public init(
        relevantAnalyses: [MockupAnalysisResult],
        summary: String,
        confidence: Double
    ) {
        self.relevantAnalyses = relevantAnalyses
        self.summary = summary
        self.confidence = confidence
    }
}

/// Availability of additional context sources
public struct ContextAvailability: Sendable {
    /// Whether a codebase is linked to this PRD request
    public let hasCodebase: Bool

    /// Whether mockups are uploaded for this PRD request
    public let hasMockups: Bool

    /// Codebase project UUID (if linked)
    public let codebaseProjectId: UUID?

    /// Number of mockups uploaded
    public let mockupCount: Int

    /// Whether codebase is indexed with embeddings (RAG available)
    public let isCodebaseIndexed: Bool

    public init(
        hasCodebase: Bool,
        hasMockups: Bool,
        codebaseProjectId: UUID?,
        mockupCount: Int,
        isCodebaseIndexed: Bool
    ) {
        self.hasCodebase = hasCodebase
        self.hasMockups = hasMockups
        self.codebaseProjectId = codebaseProjectId
        self.mockupCount = mockupCount
        self.isCodebaseIndexed = isCodebaseIndexed
    }
}
