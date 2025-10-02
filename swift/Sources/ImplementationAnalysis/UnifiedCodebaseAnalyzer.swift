import Foundation
import CommonModels
import AIProvidersCore

/// Unified Codebase Analyzer - Combines file system scanning with semantic search
/// Provides comprehensive codebase understanding for PRD generation and verification
public actor UnifiedCodebaseAnalyzer {

    private let fileSystemAnalyzer: ImplementationAnalyzer
    private let embeddingGenerator: EmbeddingGeneratorPort?
    private let codebaseRepository: CodebaseRepositoryProtocol?

    /// Initialize with AI provider and optional semantic search capabilities
    public init(
        provider: AIProvider,
        projectRoot: String? = nil,
        embeddingGenerator: EmbeddingGeneratorPort? = nil,
        codebaseRepository: CodebaseRepositoryProtocol? = nil
    ) {
        self.fileSystemAnalyzer = ImplementationAnalyzer(
            provider: provider,
            projectRoot: projectRoot
        )
        self.embeddingGenerator = embeddingGenerator
        self.codebaseRepository = codebaseRepository
    }

    /// Comprehensive analysis combining file system scanning and semantic search
    public func analyzeCodebase(
        forPRD prdContent: String? = nil,
        focus: String? = nil
    ) async throws -> ComprehensiveAnalysis {

        print("\n🔍 Starting Unified Codebase Analysis")
        print(String(repeating: "=", count: 60))

        // 1. File system analysis (pattern detection, structure understanding)
        print("📁 Phase 1: File System Analysis...")
        let fileSystemAnalysis = try await fileSystemAnalyzer.analyzeCurrentImplementation()

        var semanticResults: [SemanticSearchResult] = []
        var relevantCodeContext: String?

        // 2. Semantic search (if enabled and PRD content provided)
        if let prdContent = prdContent,
           let embeddingGenerator = embeddingGenerator,
           let repository = codebaseRepository {

            print("🧠 Phase 2: Semantic Search...")
            semanticResults = try await performSemanticSearch(
                query: prdContent,
                embeddingGenerator: embeddingGenerator,
                repository: repository,
                focus: focus
            )

            relevantCodeContext = buildCodeContext(from: semanticResults)
        }

        // 3. Synthesize findings
        print("⚡ Phase 3: Synthesizing Results...")
        let synthesis = synthesizeFindings(
            fileSystem: fileSystemAnalysis,
            semantic: semanticResults
        )

        print("✅ Analysis Complete\n")

        return ComprehensiveAnalysis(
            timestamp: Date(),
            fileSystemAnalysis: fileSystemAnalysis,
            semanticResults: semanticResults,
            relevantCodeContext: relevantCodeContext,
            synthesis: synthesis
        )
    }

    /// Perform semantic search across codebase
    private func performSemanticSearch(
        query: String,
        embeddingGenerator: EmbeddingGeneratorPort,
        repository: CodebaseRepositoryProtocol,
        focus: String?,
        limit: Int = 10
    ) async throws -> [SemanticSearchResult] {

        // Generate embedding for search query
        let queryEmbedding = try await embeddingGenerator.generateEmbedding(text: query)

        // Search for similar code
        // Note: This assumes repository has searchFiles method that returns results with similarity
        // The actual implementation depends on the repository protocol

        var results: [SemanticSearchResult] = []

        // For now, return empty results - this needs to be implemented based on repository capabilities
        // The repository would need to support vector similarity search

        return results
    }

    /// Build code context from semantic search results
    private func buildCodeContext(from results: [SemanticSearchResult]) -> String {
        var context = "# Relevant Code Context\n\n"

        for (index, result) in results.enumerated() {
            context += "## Match \(index + 1) (Similarity: \(String(format: "%.2f", result.similarity)))\n"
            context += "**File:** `\(result.filePath)`\n\n"
            context += "```\n\(result.content)\n```\n\n"
        }

        return context
    }

    /// Synthesize findings from both analysis approaches
    private func synthesizeFindings(
        fileSystem: ImplementationAnalyzer.CodebaseAnalysis,
        semantic: [SemanticSearchResult]
    ) -> Synthesis {

        let patterns = fileSystem.patterns
        let architecture = fileSystem.architecture

        // Combine insights
        var insights: [String] = []

        // From file system analysis
        insights.append("Identified \(patterns.count) architectural patterns")
        insights.append("Architecture: \(architecture)")
        insights.append("Source files: \(fileSystem.sourceFiles.count)")

        // From semantic search
        if !semantic.isEmpty {
            let avgSimilarity = semantic.map { $0.similarity }.reduce(0, +) / Float(semantic.count)
            insights.append("Found \(semantic.count) semantically relevant code sections")
            insights.append("Average relevance: \(String(format: "%.2f", avgSimilarity))")
        }

        return Synthesis(
            timestamp: Date(),
            insights: insights,
            confidence: calculateConfidence(fileSystem: fileSystem, semantic: semantic),
            recommendations: generateRecommendations(fileSystem: fileSystem, semantic: semantic)
        )
    }

    /// Calculate confidence score based on available data
    private func calculateConfidence(
        fileSystem: ImplementationAnalyzer.CodebaseAnalysis,
        semantic: [SemanticSearchResult]
    ) -> Float {
        var confidence: Float = 0.5 // Base confidence

        // Increase confidence based on file system analysis completeness
        if fileSystem.sourceFiles.count > 10 {
            confidence += 0.2
        }

        // Increase confidence based on semantic search results
        if !semantic.isEmpty {
            let avgSimilarity = semantic.map { $0.similarity }.reduce(0, +) / Float(semantic.count)
            confidence += avgSimilarity * 0.3
        }

        return min(1.0, confidence)
    }

    /// Generate recommendations based on analysis
    private func generateRecommendations(
        fileSystem: ImplementationAnalyzer.CodebaseAnalysis,
        semantic: [SemanticSearchResult]
    ) -> [String] {
        var recommendations: [String] = []

        // Based on patterns found
        if fileSystem.patterns.isEmpty {
            recommendations.append("Consider establishing clear architectural patterns")
        }

        // Based on semantic search
        if semantic.isEmpty {
            recommendations.append("Index codebase for semantic search to improve PRD accuracy")
        }

        return recommendations
    }

    // MARK: - Public Types

    /// Comprehensive analysis result combining both approaches
    public struct ComprehensiveAnalysis {
        public let timestamp: Date
        public let fileSystemAnalysis: ImplementationAnalyzer.CodebaseAnalysis
        public let semanticResults: [SemanticSearchResult]
        public let relevantCodeContext: String?
        public let synthesis: Synthesis
    }

    /// Semantic search result
    public struct SemanticSearchResult {
        public let filePath: String
        public let content: String
        public let similarity: Float
        public let lineNumber: Int?

        public init(filePath: String, content: String, similarity: Float, lineNumber: Int? = nil) {
            self.filePath = filePath
            self.content = content
            self.similarity = similarity
            self.lineNumber = lineNumber
        }
    }

    /// Synthesis of findings from both approaches
    public struct Synthesis {
        public let timestamp: Date
        public let insights: [String]
        public let confidence: Float
        public let recommendations: [String]
    }
}

// MARK: - Protocols are defined in Domain layer
// EmbeddingGeneratorPort is in Domain/EmbeddingGeneratorPort.swift
// CodebaseRepositoryProtocol is in Domain/CodebaseRepositoryProtocol.swift

/// Basic code file info (simplified)
public struct CodeFileInfo: Sendable {
    public let id: UUID
    public let codebaseId: UUID
    public let filePath: String
    public let content: String
    public let language: String?
    public let embedding: [Float]

    public init(
        id: UUID = UUID(),
        codebaseId: UUID,
        filePath: String,
        content: String,
        language: String? = nil,
        embedding: [Float]
    ) {
        self.id = id
        self.codebaseId = codebaseId
        self.filePath = filePath
        self.content = content
        self.language = language
        self.embedding = embedding
    }
}
