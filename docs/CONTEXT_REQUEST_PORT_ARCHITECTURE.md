# Context Request Port Architecture

> **Two-Way Communication Between Library and Server for Intelligent Clarification Resolution**

## Repository Structure

This architecture spans three repositories in the AI PRD Builder project:

### 1. **Library (Core PRD Generation)**
- **Path**: `/Users/cdeust/Tools/mcp-tools/claude-code-development/Claude-Code-Development-Kit/Projects/ai-prd-builder/`
- **Purpose**: Pure Swift PRD generation library with domain logic
- **Role**: Defines `ContextRequestPort` protocol (Domain layer)
- **Key Files**:
  - `swift/Sources/Domain/Ports/ContextRequestPort.swift` (NEW)
  - `swift/Sources/PRDGenerator/Components/RequirementsAnalyzer.swift` (UPDATE)
  - `swift/Sources/PRDGenerator/Components/ClarificationCollector.swift` (UPDATE)
  - `swift/Sources/PRDGenerator/PRDGenerator.swift` (UPDATE)

### 2. **Server (Vapor Backend)**
- **Path**: `/Users/cdeust/Tools/mcp-tools/claude-code-development/Claude-Code-Development-Kit/Projects/ai-prd-builder-vapor-server/`
- **Purpose**: Swift Vapor REST API server with database access
- **Role**: Implements `ServerContextRequestAdapter` (Infrastructure layer)
- **Key Files**:
  - `Sources/Infrastructure/Adapters/ServerContextRequestAdapter.swift` (NEW)
  - `Sources/Application/UseCases/GeneratePRDUseCase.swift` (UPDATE)
  - `Sources/Infrastructure/AIProviders/NativePRDGeneratorProvider.swift` (UPDATE)
  - `Database/supabase/FULL_RESET.sql` (reference for DB schema)

### 3. **Web Frontend (React + TypeScript)**
- **Path**: `/Users/cdeust/Tools/mcp-tools/claude-code-development/Claude-Code-Development-Kit/Projects/ai-prd-builder-web/`
- **Purpose**: React web application for PRD creation and management
- **Role**: User interface for PRD generation workflow
- **Key Files**:
  - `src/presentation/components/PRDConfigurationForm.tsx` (reference)
  - `src/presentation/components/CodebaseSelector.tsx` (reference)
  - `src/application/useCases/UploadMockupUseCase.ts` (reference)

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Current Architecture Gap](#current-architecture-gap)
3. [Proposed Solution](#proposed-solution)
4. [Architecture Design](#architecture-design)
5. [Implementation Guide](#implementation-guide)
6. [Flow Diagrams](#flow-diagrams)
7. [Code Examples](#code-examples)
8. [Testing Strategy](#testing-strategy)
9. [Migration Path](#migration-path)
10. [Benefits & Trade-offs](#benefits--trade-offs)

---

## Executive Summary

### Problem Statement

The current PRD generation system has **one-way communication** from server to library. When the AI requests clarifications during PRD generation, the library can only ask the **user** directly, even though the **database may already contain the answer** in codebase or mockup data.

### Solution

Implement a **Context Request Port** following Clean Architecture's **Dependency Inversion Principle**, allowing the library to request additional context from the server on-demand during generation without creating coupling.

### Key Benefits

- ✅ **Intelligent Auto-Resolution**: Answers clarifications from DB when possible
- ✅ **Reduced User Friction**: Fewer manual questions for users
- ✅ **Higher PRD Quality**: More accurate results using existing codebase/mockup data
- ✅ **Clean Architecture**: No coupling between library and infrastructure
- ✅ **Backward Compatible**: Optional dependency, library works standalone

---

## Current Architecture Gap

### Current Flow (One-Way)

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Server (Vapor)                                           │
│    - Has database access                                    │
│    - Fetches codebase + mockups                            │
│    - Builds enriched context                                │
└────────────────────┬────────────────────────────────────────┘
                     │ Enriched Context
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Library (ai-prd-builder)                                 │
│    - Receives pre-built context                            │
│    - Generates PRD                                          │
│    - LLM asks: "What authentication method?"                │
└────────────────────┬────────────────────────────────────────┘
                     │ Question
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. User (Manual Answer Required)                            │
│    ❌ Database HAS OAuth2 implementation                    │
│    ❌ Mockups SHOW login screens                            │
│    ❌ But library can't access this data                    │
└─────────────────────────────────────────────────────────────┘
```

### Why This Is a Problem

**Scenario Example:**

1. User uploads mockups showing OAuth login screens
2. User links GitHub repo with existing OAuth2 + JWT implementation
3. AI asks: "What authentication method should we use?"
4. **Current behavior**: User manually answers "OAuth2"
5. **Should happen**: Library queries DB, finds OAuth2, auto-answers

**Impact:**
- Poor user experience (repetitive questions)
- Lower confidence scores (missing context)
- Incomplete PRDs (ignored existing implementations)

---

## Proposed Solution

### Two-Way Communication Architecture

```
┌──────────────────────────────────────────────────────────────┐
│ Server (Vapor) - Infrastructure Layer                        │
│                                                              │
│ Implements: ServerContextRequestAdapter                     │
│ - Queries database (Supabase)                               │
│ - RAG semantic search (embeddings)                          │
│ - Mockup analysis retrieval                                 │
└────────────────┬──────────────────┬──────────────────────────┘
                 │                  │
         Enriched Context    ContextRequestPort (Interface)
                 │                  │
                 ▼                  ▼
┌──────────────────────────────────────────────────────────────┐
│ Library (ai-prd-builder) - Domain Layer                      │
│                                                              │
│ Defines: ContextRequestPort protocol                         │
│ Uses: Optional dependency injection                          │
│                                                              │
│ Flow:                                                        │
│ 1. LLM asks clarification question                          │
│ 2. Library calls contextPort?.requestCodebaseContext(...)   │
│ 3. If answer found (confidence > 0.7) → auto-answer         │
│ 4. Else → fallback to user prompt                           │
└──────────────────────────────────────────────────────────────┘
```

### Key Principles

1. **Dependency Inversion**: Library owns the interface, server implements it
2. **Optional Dependency**: Works with or without server context
3. **Smart Fallback**: Tries DB first, asks user only if needed
4. **Clean Separation**: No infrastructure leaking into domain

---

## Architecture Design

### 1. Domain Layer (Library)

#### ContextRequestPort Protocol

**Location**: `/Users/cdeust/Tools/mcp-tools/claude-code-development/Claude-Code-Development-Kit/Projects/ai-prd-builder/swift/Sources/Domain/Ports/ContextRequestPort.swift`

```swift
import Foundation

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
```

### 2. Application Layer (Library)

#### Enhanced RequirementsAnalyzer

**Location**: `/Users/cdeust/Tools/mcp-tools/claude-code-development/Claude-Code-Development-Kit/Projects/ai-prd-builder/swift/Sources/PRDGenerator/Components/RequirementsAnalyzer.swift`

**Changes Required:**

```swift
public final class RequirementsAnalyzer {
    private let analysisOrchestrator: AnalysisOrchestrator
    private let confidenceEvaluator: ConfidenceEvaluator
    private let clarificationCollector: ClarificationCollector
    private let requirementsEnricher: RequirementsEnricher
    private let interactionHandler: UserInteractionHandler
    private let contextRequestPort: ContextRequestPort? // NEW: Optional dependency
    private let configuration: Configuration

    // Store request context for context queries
    private var currentRequestId: UUID?
    private var currentProjectId: UUID?

    public init(
        provider: AIProvider,
        interactionHandler: UserInteractionHandler,
        configuration: Configuration = Configuration(),
        contextRequestPort: ContextRequestPort? = nil // NEW: Inject from server
    ) {
        self.analysisOrchestrator = AnalysisOrchestrator(provider: provider)
        self.confidenceEvaluator = ConfidenceEvaluator()
        self.clarificationCollector = ClarificationCollector(
            interactionHandler: interactionHandler,
            contextRequestPort: contextRequestPort // Pass through
        )
        self.requirementsEnricher = RequirementsEnricher()
        self.interactionHandler = interactionHandler
        self.contextRequestPort = contextRequestPort
        self.configuration = configuration

        // ... rest of initialization
    }

    /// Set request context for context queries
    public func setRequestContext(requestId: UUID?, projectId: UUID?) {
        self.currentRequestId = requestId
        self.currentProjectId = projectId
    }
}
```

#### Enhanced ClarificationCollector

**Location**: `/Users/cdeust/Tools/mcp-tools/claude-code-development/Claude-Code-Development-Kit/Projects/ai-prd-builder/swift/Sources/PRDGenerator/Components/ClarificationCollector.swift`

**New Methods:**

```swift
public final class ClarificationCollector {
    private let interactionHandler: UserInteractionHandler
    private let contextRequestPort: ContextRequestPort? // NEW

    public init(
        interactionHandler: UserInteractionHandler,
        contextRequestPort: ContextRequestPort? = nil
    ) {
        self.interactionHandler = interactionHandler
        self.contextRequestPort = contextRequestPort
    }

    /// Collects clarifications with smart DB fallback
    public func collectClarifications(
        for questions: [String],
        requestId: UUID?,
        category: String? = nil
    ) async -> [String: String] {
        var responses: [String: String] = [:]

        if let category = category {
            interactionHandler.showInfo(category)
        }

        for question in questions {
            // NEW: Try to answer from context first
            if let requestId = requestId,
               let contextPort = contextRequestPort,
               let autoAnswer = await tryAnswerFromContext(
                   question: question,
                   requestId: requestId,
                   contextPort: contextPort
               ) {
                responses[question] = autoAnswer
                interactionHandler.showInfo("✅ Auto-resolved from context: \(question)")
                continue
            }

            // Fallback: Ask user
            let userAnswer = await interactionHandler.askQuestion(question)
            if !userAnswer.isEmpty {
                responses[question] = userAnswer
            }
        }

        return responses
    }

    /// Attempt to answer clarification from DB context
    private func tryAnswerFromContext(
        question: String,
        requestId: UUID,
        contextPort: ContextRequestPort
    ) async -> String? {
        // Step 1: Check if additional context is available
        let availability = await contextPort.hasAdditionalContext(requestId: requestId)

        guard availability.hasCodebase || availability.hasMockups else {
            return nil // No context sources available
        }

        interactionHandler.showProgress("🔍 Searching codebase/mockups for: \(question)")

        // Step 2: Try codebase context (RAG semantic search)
        if availability.hasCodebase,
           let projectId = availability.codebaseProjectId,
           availability.isCodebaseIndexed {

            let searchQuery = extractSearchQuery(from: question)

            if let codebaseResponse = try? await contextPort.requestCodebaseContext(
                projectId: projectId,
                question: question,
                searchQuery: searchQuery
            ), codebaseResponse.confidence >= 0.7 {
                interactionHandler.showInfo("📦 Found answer in codebase (\(Int(codebaseResponse.confidence * 100))% confidence)")
                return formatCodebaseAnswer(codebaseResponse)
            }
        }

        // Step 3: Try mockup context
        if availability.hasMockups {
            let featureQuery = extractFeatureQuery(from: question)

            if let mockupResponse = try? await contextPort.requestMockupContext(
                requestId: requestId,
                featureQuery: featureQuery
            ), mockupResponse.confidence >= 0.6 {
                interactionHandler.showInfo("🎨 Found answer in mockup analysis (\(Int(mockupResponse.confidence * 100))% confidence)")
                return formatMockupAnswer(mockupResponse)
            }
        }

        return nil
    }

    /// Extract search query from clarification question
    /// Example: "What authentication method?" → "authentication oauth jwt login"
    private func extractSearchQuery(from question: String) -> String {
        let lowercased = question.lowercased()
        var keywords: [String] = []

        // Authentication-related
        if lowercased.contains("auth") {
            keywords.append(contentsOf: ["authentication", "oauth", "jwt", "login", "security"])
        }

        // Database-related
        if lowercased.contains("database") || lowercased.contains("storage") {
            keywords.append(contentsOf: ["database", "sql", "postgresql", "orm", "migration"])
        }

        // API-related
        if lowercased.contains("api") || lowercased.contains("endpoint") {
            keywords.append(contentsOf: ["api", "rest", "graphql", "endpoint", "route"])
        }

        // State management
        if lowercased.contains("state") || lowercased.contains("store") {
            keywords.append(contentsOf: ["state", "redux", "store", "context", "provider"])
        }

        // Testing
        if lowercased.contains("test") {
            keywords.append(contentsOf: ["test", "testing", "spec", "mock", "jest"])
        }

        // UI/UX
        if lowercased.contains("ui") || lowercased.contains("design") {
            keywords.append(contentsOf: ["ui", "design", "component", "style", "theme"])
        }

        // Fallback: extract nouns and technical terms
        let words = question.components(separatedBy: .whitespacesAndNewlines)
        keywords.append(contentsOf: words.filter { $0.count > 3 && !["what", "how", "when", "where", "should"].contains($0.lowercased()) })

        return keywords.prefix(8).joined(separator: " ")
    }

    /// Extract feature query from question
    /// Example: "How should users log in?" → "login authentication user"
    private func extractFeatureQuery(from question: String) -> String {
        let lowercased = question.lowercased()
        var keywords: [String] = []

        // Extract action verbs
        let actionVerbs = ["login", "logout", "register", "submit", "upload", "download", "search", "filter", "edit", "delete", "create"]
        for verb in actionVerbs {
            if lowercased.contains(verb) {
                keywords.append(verb)
            }
        }

        // Extract feature nouns
        let featureNouns = ["profile", "dashboard", "settings", "account", "notification", "message", "payment", "cart", "checkout"]
        for noun in featureNouns {
            if lowercased.contains(noun) {
                keywords.append(noun)
            }
        }

        return keywords.isEmpty ? question : keywords.joined(separator: " ")
    }

    /// Format codebase answer for PRD generation
    private func formatCodebaseAnswer(_ response: CodebaseContextResponse) -> String {
        var answer = response.summary

        if !response.relevantFiles.isEmpty {
            answer += "\n\nReference files:"
            for file in response.relevantFiles.prefix(3) {
                answer += "\n- \(file.filePath): \(file.purpose)"
            }
        }

        return answer
    }

    /// Format mockup answer for PRD generation
    private func formatMockupAnswer(_ response: MockupContextResponse) -> String {
        var answer = response.summary

        if !response.relevantAnalyses.isEmpty {
            let totalUIElements = response.relevantAnalyses.reduce(0) { $0 + $1.uiElements.count }
            let totalFlows = response.relevantAnalyses.reduce(0) { $0 + $1.inferredUserFlows.count }

            answer += "\n\nBased on \(response.relevantAnalyses.count) mockup(s) with \(totalUIElements) UI elements and \(totalFlows) user flows."
        }

        return answer
    }
}
```

### 3. Infrastructure Layer (Server)

#### ServerContextRequestAdapter

**Location**: `/Users/cdeust/Tools/mcp-tools/claude-code-development/Claude-Code-Development-Kit/Projects/ai-prd-builder-vapor-server/Sources/Infrastructure/Adapters/ServerContextRequestAdapter.swift`

```swift
import Foundation
import Domain
import ImplementationAnalysis

/// Server-side implementation of ContextRequestPort
/// Queries Supabase database and performs RAG semantic search
public final class ServerContextRequestAdapter: ContextRequestPort {
    private let codebaseRepository: CodebaseRepositoryProtocol
    private let mockupUploadRepository: MockupUploadRepositoryProtocol
    private let prdCodebaseLink: PRDCodebaseLink
    private let embeddingGenerator: EmbeddingGeneratorPort
    private let aiProvider: AIProviderPort

    public init(
        codebaseRepository: CodebaseRepositoryProtocol,
        mockupUploadRepository: MockupUploadRepositoryProtocol,
        prdCodebaseLink: PRDCodebaseLink,
        embeddingGenerator: EmbeddingGeneratorPort,
        aiProvider: AIProviderPort
    ) {
        self.codebaseRepository = codebaseRepository
        self.mockupUploadRepository = mockupUploadRepository
        self.prdCodebaseLink = prdCodebaseLink
        self.embeddingGenerator = embeddingGenerator
        self.aiProvider = aiProvider
    }

    // MARK: - ContextRequestPort Implementation

    public func requestCodebaseContext(
        projectId: UUID,
        question: String,
        searchQuery: String
    ) async throws -> CodebaseContextResponse? {
        print("📦 Searching codebase for: '\(searchQuery)'")

        // Step 1: Generate embedding for search query
        let queryEmbedding = try await embeddingGenerator.generateEmbedding(text: searchQuery)

        // Step 2: Perform RAG semantic search
        let similarChunks = try await codebaseRepository.findSimilarChunks(
            projectId: projectId,
            queryEmbedding: queryEmbedding,
            limit: 5,
            similarityThreshold: 0.65
        )

        guard !similarChunks.isEmpty else {
            print("⚠️ No relevant code chunks found")
            return nil
        }

        print("✅ Found \(similarChunks.count) relevant code chunks")

        // Step 3: Build context from chunks
        let relevantFiles = similarChunks.map { similar in
            CodeFileContext(
                filePath: similar.chunk.filePath,
                language: similar.chunk.language.rawValue,
                excerpt: similar.chunk.content,
                purpose: "\(similar.chunk.chunkType.rawValue)\(similar.chunk.symbols.first.map { " '\($0)'" } ?? "")"
            )
        }

        // Step 4: Generate AI summary answering the question
        let summary = try await generateCodebaseSummary(
            question: question,
            chunks: similarChunks
        )

        // Step 5: Calculate average confidence
        let avgSimilarity = similarChunks.map { $0.similarity }.reduce(0, +) / Double(similarChunks.count)

        return CodebaseContextResponse(
            relevantFiles: relevantFiles,
            summary: summary,
            confidence: avgSimilarity,
            chunksAnalyzed: similarChunks.count
        )
    }

    public func requestMockupContext(
        requestId: UUID,
        featureQuery: String
    ) async throws -> MockupContextResponse? {
        print("🎨 Searching mockups for: '\(featureQuery)'")

        // Step 1: Fetch all mockup uploads for this request
        let mockupUploads = try await mockupUploadRepository.findByRequestId(requestId)
        let analyses = mockupUploads.compactMap { $0.analysisResult }

        guard !analyses.isEmpty else {
            print("⚠️ No mockup analyses found")
            return nil
        }

        // Step 2: Filter analyses relevant to the feature query
        let relevant = filterRelevantMockupAnalyses(
            analyses: analyses,
            featureQuery: featureQuery
        )

        guard !relevant.isEmpty else {
            print("⚠️ No relevant mockup analyses for query")
            return nil
        }

        print("✅ Found \(relevant.count) relevant mockup analyses")

        // Step 3: Generate AI summary
        let summary = try await generateMockupSummary(
            featureQuery: featureQuery,
            analyses: relevant
        )

        // Step 4: Calculate confidence based on match quality
        let confidence = calculateMockupConfidence(
            analyses: relevant,
            featureQuery: featureQuery
        )

        return MockupContextResponse(
            relevantAnalyses: relevant,
            summary: summary,
            confidence: confidence
        )
    }

    public func hasAdditionalContext(requestId: UUID) async -> ContextAvailability {
        // Check codebase link
        let linkedCodebase = try? await prdCodebaseLink.getCodebaseForPRD(prdRequestId: requestId)

        // Check mockup count
        let mockupCount = (try? await mockupUploadRepository.countByRequestId(requestId)) ?? 0

        // Check if codebase is indexed
        var isIndexed = false
        if let codebase = linkedCodebase {
            isIndexed = codebase.indexingStatus == .completed && codebase.totalChunks > 0
        }

        return ContextAvailability(
            hasCodebase: linkedCodebase != nil,
            hasMockups: mockupCount > 0,
            codebaseProjectId: linkedCodebase?.id,
            mockupCount: mockupCount,
            isCodebaseIndexed: isIndexed
        )
    }

    // MARK: - Private Helper Methods

    /// Generate AI summary answering the clarification question using codebase chunks
    private func generateCodebaseSummary(
        question: String,
        chunks: [SimilarCodeChunk]
    ) async throws -> String {
        let codeContext = chunks.map { chunk in
            """
            File: \(chunk.chunk.filePath)
            Type: \(chunk.chunk.chunkType.rawValue)
            Symbols: \(chunk.chunk.symbols.joined(separator: ", "))

            ```\(chunk.chunk.language.rawValue)
            \(chunk.chunk.content)
            ```
            """
        }.joined(separator: "\n\n---\n\n")

        let prompt = """
        Based on the following code context from the existing codebase, answer this question:

        **Question**: \(question)

        **Code Context**:
        \(codeContext)

        Provide a concise, technical answer (2-3 sentences max) that directly answers the question.
        Focus on what already exists in the codebase.
        """

        // Use AI provider to generate summary
        let result = try await aiProvider.generateText(from: prompt)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Generate AI summary for mockup analysis
    private func generateMockupSummary(
        featureQuery: String,
        analyses: [MockupAnalysisResult]
    ) async throws -> String {
        let mockupContext = analyses.enumerated().map { index, analysis in
            var context = "Mockup \(index + 1):\n"

            if !analysis.uiElements.isEmpty {
                let elements = analysis.uiElements.prefix(5).map { "- \($0.type): \($0.label ?? "unlabeled")" }.joined(separator: "\n")
                context += "UI Elements:\n\(elements)\n"
            }

            if !analysis.inferredUserFlows.isEmpty {
                let flows = analysis.inferredUserFlows.prefix(3).map { "- \($0.flowName)" }.joined(separator: "\n")
                context += "User Flows:\n\(flows)\n"
            }

            if !analysis.businessLogicInferences.isEmpty {
                let logic = analysis.businessLogicInferences.prefix(3).map { "- \($0.feature): \($0.description)" }.joined(separator: "\n")
                context += "Business Logic:\n\(logic)\n"
            }

            return context
        }.joined(separator: "\n\n")

        let prompt = """
        Based on the following mockup analyses, provide insight for this feature query:

        **Feature Query**: \(featureQuery)

        **Mockup Analyses**:
        \(mockupContext)

        Provide a concise answer (2-3 sentences max) describing how the mockups address this feature.
        Focus on UI/UX patterns and user flows shown in the mockups.
        """

        let result = try await aiProvider.generateText(from: prompt)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Filter mockup analyses relevant to feature query
    private func filterRelevantMockupAnalyses(
        analyses: [MockupAnalysisResult],
        featureQuery: String
    ) -> [MockupAnalysisResult] {
        let queryKeywords = featureQuery.lowercased().components(separatedBy: .whitespaces)

        return analyses.filter { analysis in
            // Check UI elements
            let hasRelevantUI = analysis.uiElements.contains { element in
                let elementText = "\(element.type) \(element.label ?? "")".lowercased()
                return queryKeywords.contains { elementText.contains($0) }
            }

            // Check user flows
            let hasRelevantFlow = analysis.inferredUserFlows.contains { flow in
                let flowText = "\(flow.flowName) \(flow.steps.joined(separator: " "))".lowercased()
                return queryKeywords.contains { flowText.contains($0) }
            }

            // Check business logic
            let hasRelevantLogic = analysis.businessLogicInferences.contains { inference in
                let logicText = "\(inference.feature) \(inference.description)".lowercased()
                return queryKeywords.contains { logicText.contains($0) }
            }

            return hasRelevantUI || hasRelevantFlow || hasRelevantLogic
        }
    }

    /// Calculate confidence score for mockup match
    private func calculateMockupConfidence(
        analyses: [MockupAnalysisResult],
        featureQuery: String
    ) -> Double {
        guard !analyses.isEmpty else { return 0.0 }

        let queryKeywords = featureQuery.lowercased().components(separatedBy: .whitespaces)
        var totalMatches = 0
        var totalPossibleMatches = 0

        for analysis in analyses {
            let elements = analysis.uiElements.count
            let flows = analysis.inferredUserFlows.count
            let logic = analysis.businessLogicInferences.count

            totalPossibleMatches += elements + flows + logic

            // Count keyword matches
            for keyword in queryKeywords where keyword.count > 2 {
                totalMatches += analysis.uiElements.filter { element in
                    "\(element.type) \(element.label ?? "")".lowercased().contains(keyword)
                }.count

                totalMatches += analysis.inferredUserFlows.filter { flow in
                    flow.flowName.lowercased().contains(keyword)
                }.count

                totalMatches += analysis.businessLogicInferences.filter { inference in
                    inference.feature.lowercased().contains(keyword)
                }.count
            }
        }

        guard totalPossibleMatches > 0 else { return 0.5 }

        let matchRatio = Double(totalMatches) / Double(totalPossibleMatches)
        return min(0.95, max(0.6, matchRatio)) // Clamp between 0.6 and 0.95
    }
}

// MARK: - AIProviderPort Extension for Text Generation

extension AIProviderPort {
    /// Generate plain text response (helper for context summaries)
    func generateText(from prompt: String) async throws -> String {
        let command = GeneratePRDCommand(
            requestId: UUID(),
            title: "Context Summary",
            description: prompt,
            mockupSources: [],
            priority: "medium",
            requester: "system",
            preferredProvider: nil,
            options: GenerationOptions()
        )

        let result = try await generatePRD(from: command)
        return result.content
    }
}
```

### 4. Wiring in GeneratePRDUseCase

**Location**: `/Users/cdeust/Tools/mcp-tools/claude-code-development/Claude-Code-Development-Kit/Projects/ai-prd-builder-vapor-server/Sources/Application/UseCases/GeneratePRDUseCase.swift`

**Update `execute()` method:**

```swift
public func execute(_ command: GeneratePRDCommand) async throws -> PRDDocument {
    // ... existing code (lines 38-108: fetch mockups/codebase)

    // NEW: Create context request adapter if dependencies available
    var contextPort: ContextRequestPort? = nil

    if let codebaseRepo = codebaseRepository,
       let mockupRepo = mockupUploadRepository,
       let linkRepo = prdCodebaseLink,
       let embedGen = embeddingGenerator {

        contextPort = ServerContextRequestAdapter(
            codebaseRepository: codebaseRepo,
            mockupUploadRepository: mockupRepo,
            prdCodebaseLink: linkRepo,
            embeddingGenerator: embedGen,
            aiProvider: aiProvider
        )

        print("✅ Context request port enabled for intelligent clarification resolution")
    }

    // Pass enriched command AND context port to AI provider
    let result = try await aiProvider.generatePRD(
        from: enrichedCommand,
        contextRequestPort: contextPort  // NEW parameter
    )

    // ... rest of execution
}
```

### 5. Update NativePRDGeneratorProvider

**Location**: `/Users/cdeust/Tools/mcp-tools/claude-code-development/Claude-Code-Development-Kit/Projects/ai-prd-builder-vapor-server/Sources/Infrastructure/AIProviders/NativePRDGeneratorProvider.swift`

**Update `generatePRD()` method:**

```swift
public func generatePRD(
    from command: GeneratePRDCommand,
    contextRequestPort: ContextRequestPort? = nil  // NEW parameter
) async throws -> PRDGenerationResult {
    guard let provider = getFirstAvailableProvider() else {
        throw DomainError.processingFailed("No AI provider available for PRD generation")
    }

    let config = DomainCore.Configuration(
        debugMode: true,
        enableClarificationPrompts: true,  // Enable clarifications
        enableProfessionalAnalysis: true,
        detectArchitecturalConflicts: true,
        predictTechnicalChallenges: true,
        analyzeComplexity: true,
        identifyScalingBreakpoints: true,
        showCriticalDecisions: true
    )

    let generator = PRDGenerator(
        provider: provider,
        configuration: config,
        interactionHandler: NonInteractiveHandler(),
        contextRequestPort: contextRequestPort  // Pass through to library
    )

    self.prdGenerator = generator

    // Set request context for clarification queries
    if let contextPort = contextRequestPort {
        generator.setRequestContext(
            requestId: command.requestId,
            projectId: command.codebaseContext?.projectId
        )
    }

    // Build optimized context with intelligent chunking
    let enrichedDescription = ContextOptimizer.buildOptimizedContext(
        title: command.title,
        description: command.description,
        codebaseContext: command.codebaseContext,
        mockupAnalyses: command.mockupAnalyses,
        clarifications: command.clarifications
    )

    let document = try await generator.generatePRD(from: enrichedDescription)

    return try await mapToDomainResult(document)
}
```

---

## Flow Diagrams

### Complete Request Flow with Context Port

```
┌──────────────────────────────────────────────────────────────────┐
│ 1. USER INTERACTION (Web Frontend)                               │
└────────────────────┬─────────────────────────────────────────────┘
                     │
                     │ POST /api/v1/prd/generate
                     │ { title, description, codebaseId, mockups }
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│ 2. VAPOR SERVER - GeneratePRDUseCase                             │
│                                                                   │
│ 2.1. Fetch PRD request from DB                                  │
│ 2.2. Fetch mockup uploads & analyses                            │
│ 2.3. Fetch linked codebase project                              │
│ 2.4. Build enriched context (ContextOptimizer)                  │
│ 2.5. Create ServerContextRequestAdapter                         │
│                                                                   │
└────────────────────┬─────────────────────────────────────────────┘
                     │
                     │ generatePRD(command, contextPort: adapter)
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│ 3. LIBRARY - PRDGenerator                                        │
│                                                                   │
│ 3.1. Initialize with context port                               │
│ 3.2. ProcessedInput → RequirementsAnalyzer                      │
│                                                                   │
└────────────────────┬─────────────────────────────────────────────┘
                     │
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│ 4. LIBRARY - RequirementsAnalyzer.analyzeAndClarify()           │
│                                                                   │
│ 4.1. LLM analyzes requirements                                  │
│ 4.2. Generates clarification questions                          │
│      - "What authentication method should we use?"               │
│      - "Should we support offline mode?"                         │
│                                                                   │
└────────────────────┬─────────────────────────────────────────────┘
                     │
                     │ Questions list
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│ 5. LIBRARY - ClarificationCollector.collectClarifications()     │
│                                                                   │
│ For each question:                                               │
│                                                                   │
│ 5.1. Check if contextPort is available                          │
│      └─> hasAdditionalContext(requestId)                        │
│                                                                   │
└────────────────────┬─────────────────────────────────────────────┘
                     │
                     │ Check context availability
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│ 6. SERVER ADAPTER - hasAdditionalContext()                      │
│                                                                   │
│ 6.1. Query prd_codebase_links table                             │
│ 6.2. Query mockup_uploads table                                 │
│ 6.3. Check codebase indexing status                             │
│                                                                   │
│ Returns: ContextAvailability {                                   │
│   hasCodebase: true,                                             │
│   hasMockups: true,                                              │
│   codebaseProjectId: UUID,                                       │
│   mockupCount: 3,                                                │
│   isCodebaseIndexed: true                                        │
│ }                                                                 │
│                                                                   │
└────────────────────┬─────────────────────────────────────────────┘
                     │
                     │ Context available
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│ 7. LIBRARY - ClarificationCollector.tryAnswerFromContext()      │
│                                                                   │
│ 7.1. Extract search query from question                         │
│      "What authentication method?" → "authentication oauth jwt" │
│                                                                   │
│ 7.2. Call contextPort.requestCodebaseContext()                  │
│                                                                   │
└────────────────────┬─────────────────────────────────────────────┘
                     │
                     │ requestCodebaseContext(projectId, question, searchQuery)
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│ 8. SERVER ADAPTER - requestCodebaseContext()                    │
│                                                                   │
│ 8.1. Generate embedding for search query                        │
│      embeddingGenerator.generateEmbedding("authentication...")  │
│                                                                   │
│ 8.2. RAG semantic search in database                            │
│      codebaseRepository.findSimilarChunks(projectId, embedding) │
│                                                                   │
│      SQL: SELECT * FROM code_embeddings                          │
│           JOIN code_chunks ON ...                                │
│           WHERE codebase_project_id = $1                         │
│           ORDER BY embedding <=> $2                              │
│           LIMIT 5                                                │
│                                                                   │
│ 8.3. Found 5 code chunks (avg similarity: 0.82)                │
│      - src/auth/OAuth2Provider.swift (0.89)                     │
│      - src/auth/JWTTokenManager.swift (0.85)                    │
│      - config/auth.config.json (0.78)                           │
│      - ...                                                       │
│                                                                   │
│ 8.4. Generate AI summary using aiProvider                       │
│      Prompt: "Based on these code chunks, answer: What auth...?"│
│                                                                   │
│ 8.5. Return CodebaseContextResponse {                           │
│        relevantFiles: [...],                                     │
│        summary: "Use OAuth2 with JWT tokens...",                │
│        confidence: 0.82,                                         │
│        chunksAnalyzed: 5                                         │
│      }                                                            │
│                                                                   │
└────────────────────┬─────────────────────────────────────────────┘
                     │
                     │ CodebaseContextResponse (confidence: 0.82 ✅)
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│ 9. LIBRARY - ClarificationCollector Decision                    │
│                                                                   │
│ 9.1. Check confidence >= 0.7 threshold ✅                        │
│ 9.2. Format answer from codebase response                       │
│ 9.3. Show info: "✅ Auto-resolved from context"                 │
│ 9.4. Skip user prompt                                            │
│                                                                   │
│ responses["What authentication...?"] = "Use OAuth2 with JWT..." │
│                                                                   │
└────────────────────┬─────────────────────────────────────────────┘
                     │
                     │ Continue with next question (or generate PRD)
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│ 10. LIBRARY - PRDGenerator.orchestrateGeneration()              │
│                                                                   │
│ 10.1. All clarifications resolved (auto + user)                │
│ 10.2. Generate PRD sections with enriched context              │
│ 10.3. Return PRDocument                                         │
│                                                                   │
└────────────────────┬─────────────────────────────────────────────┘
                     │
                     │ PRDocument
                     ▼
┌──────────────────────────────────────────────────────────────────┐
│ 11. SERVER - Save PRD Document                                  │
│                                                                   │
│ 11.1. Save to prd_documents table                              │
│ 11.2. Update prd_requests status to 'completed'                │
│ 11.3. Return PRDResponse to client                             │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

### Clarification Resolution Decision Tree

```
                    LLM generates clarification question
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │ Context Port available? │
                    └────────┬───────────────┘
                             │
                    ┌────────┴────────┐
                    │                 │
                   YES               NO
                    │                 │
                    ▼                 ▼
       ┌───────────────────────┐   ┌──────────────┐
       │ hasAdditionalContext()│   │ Ask User     │
       └──────────┬─────────────┘   └──────────────┘
                  │
                  ▼
      ┌───────────────────────┐
      │ Codebase OR Mockups?  │
      └──────────┬─────────────┘
                 │
        ┌────────┴────────┐
        │                 │
    Codebase          Mockups
        │                 │
        ▼                 ▼
┌──────────────────┐  ┌──────────────────┐
│ RAG Search       │  │ Filter Analyses  │
│ - Extract query  │  │ - Match keywords │
│ - Generate embed │  │ - Check UI/flows │
│ - Find chunks    │  │ - Generate summary│
│ - Gen summary    │  └────────┬─────────┘
└────────┬─────────┘           │
         │                     │
         ▼                     ▼
    ┌────────────────────────────┐
    │ Confidence >= threshold?   │
    │ (0.7 codebase, 0.6 mockup) │
    └────────┬───────────────────┘
             │
    ┌────────┴────────┐
    │                 │
   YES               NO
    │                 │
    ▼                 ▼
┌──────────────┐  ┌──────────────┐
│ Auto-answer  │  │ Ask User     │
│ Show context │  │ Fallback     │
└──────────────┘  └──────────────┘
```

---

## Code Examples

### Example 1: Complete Usage in Server

```swift
// GeneratePRDUseCase.swift
public func execute(_ command: GeneratePRDCommand) async throws -> PRDDocument {
    // Fetch data from database
    let mockupAnalyses = try await fetchMockupAnalyses(command.requestId)
    let linkedCodebase = try await fetchLinkedCodebase(command.requestId)

    // Create context port adapter
    let contextPort = ServerContextRequestAdapter(
        codebaseRepository: codebaseRepository!,
        mockupUploadRepository: mockupUploadRepository!,
        prdCodebaseLink: prdCodebaseLink!,
        embeddingGenerator: embeddingGenerator!,
        aiProvider: aiProvider
    )

    // Build enriched command
    let enrichedCommand = GeneratePRDCommand(
        requestId: command.requestId,
        title: command.title,
        description: command.description,
        mockupSources: command.mockupSources,
        priority: command.priority,
        requester: command.requester,
        preferredProvider: command.preferredProvider,
        options: command.options,
        codebaseContext: buildCodebaseContext(linkedCodebase),
        mockupAnalyses: mockupAnalyses,
        clarifications: command.clarifications
    )

    // Generate PRD with context port
    let result = try await aiProvider.generatePRD(
        from: enrichedCommand,
        contextRequestPort: contextPort
    )

    // Save and return
    let document = createPRDDocument(from: result)
    return try await documentRepository.save(document)
}
```

### Example 2: Library Usage (Standalone)

```swift
// Works without server - manual clarifications only
let generator = PRDGenerator(
    provider: anthropicProvider,
    configuration: Configuration(),
    interactionHandler: ConsoleInteractionHandler(),
    contextRequestPort: nil  // No context port = ask user
)

let document = try await generator.generatePRD(from: "Build user auth system")
```

### Example 3: Library Usage (With Server Context)

```swift
// With server context - intelligent auto-resolution
let contextAdapter = ServerContextRequestAdapter(...)

let generator = PRDGenerator(
    provider: anthropicProvider,
    configuration: Configuration(),
    interactionHandler: WebSocketInteractionHandler(...),
    contextRequestPort: contextAdapter  // Context port = try DB first
)

generator.setRequestContext(
    requestId: UUID(...),
    projectId: UUID(...)
)

let document = try await generator.generatePRD(from: "Build user auth system")
// LLM may ask clarifications, library tries DB first, falls back to user
```

### Example 4: Testing with Mock Port

```swift
// Test with mock context port
final class MockContextPort: ContextRequestPort {
    var mockCodebaseResponse: CodebaseContextResponse?
    var mockMockupResponse: MockupContextResponse?

    func requestCodebaseContext(
        projectId: UUID,
        question: String,
        searchQuery: String
    ) async throws -> CodebaseContextResponse? {
        return mockCodebaseResponse
    }

    func requestMockupContext(
        requestId: UUID,
        featureQuery: String
    ) async throws -> MockupContextResponse? {
        return mockMockupResponse
    }

    func hasAdditionalContext(requestId: UUID) async -> ContextAvailability {
        return ContextAvailability(
            hasCodebase: mockCodebaseResponse != nil,
            hasMockups: mockMockupResponse != nil,
            codebaseProjectId: UUID(),
            mockupCount: 1,
            isCodebaseIndexed: true
        )
    }
}

// Test
func testIntelligentClarificationResolution() async throws {
    let mockPort = MockContextPort()
    mockPort.mockCodebaseResponse = CodebaseContextResponse(
        relevantFiles: [],
        summary: "OAuth2 with JWT tokens found in src/auth/",
        confidence: 0.85,
        chunksAnalyzed: 5
    )

    let generator = PRDGenerator(
        provider: mockProvider,
        configuration: Configuration(),
        interactionHandler: MockInteractionHandler(),
        contextRequestPort: mockPort
    )

    let document = try await generator.generatePRD(from: "Add authentication")

    XCTAssertTrue(document.content.contains("OAuth2"))
    XCTAssertTrue(document.content.contains("JWT"))
}
```

---

## Testing Strategy

### Unit Tests

#### 1. Test ContextRequestPort Protocol

**File**: `Tests/DomainTests/Ports/ContextRequestPortTests.swift`

```swift
import XCTest
@testable import Domain

final class ContextRequestPortTests: XCTestCase {

    func testCodebaseContextResponse() {
        let response = CodebaseContextResponse(
            relevantFiles: [],
            summary: "Test summary",
            confidence: 0.85,
            chunksAnalyzed: 5
        )

        XCTAssertEqual(response.confidence, 0.85)
        XCTAssertEqual(response.chunksAnalyzed, 5)
    }

    func testContextAvailability() {
        let availability = ContextAvailability(
            hasCodebase: true,
            hasMockups: true,
            codebaseProjectId: UUID(),
            mockupCount: 3,
            isCodebaseIndexed: true
        )

        XCTAssertTrue(availability.hasCodebase)
        XCTAssertTrue(availability.hasMockups)
        XCTAssertTrue(availability.isCodebaseIndexed)
        XCTAssertEqual(availability.mockupCount, 3)
    }
}
```

#### 2. Test ClarificationCollector with Context Port

**File**: `Tests/PRDGeneratorTests/Components/ClarificationCollectorTests.swift`

```swift
import XCTest
@testable import PRDGenerator
@testable import Domain

final class ClarificationCollectorTests: XCTestCase {

    func testCollectClarificationsWithContextPort() async throws {
        // Arrange
        let mockPort = MockContextPort()
        mockPort.mockCodebaseResponse = CodebaseContextResponse(
            relevantFiles: [],
            summary: "OAuth2 with JWT",
            confidence: 0.85,
            chunksAnalyzed: 3
        )

        let mockHandler = MockInteractionHandler(responses: ["Manual answer"])
        let collector = ClarificationCollector(
            interactionHandler: mockHandler,
            contextRequestPort: mockPort
        )

        let questions = [
            "What authentication method?",
            "What database to use?"
        ]

        // Act
        let responses = await collector.collectClarifications(
            for: questions,
            requestId: UUID(),
            category: "Technical"
        )

        // Assert
        XCTAssertEqual(responses.count, 2)
        XCTAssertEqual(responses["What authentication method?"], "OAuth2 with JWT")
        XCTAssertEqual(responses["What database to use?"], "Manual answer")
    }

    func testFallbackToUserWhenNoContext() async throws {
        // Arrange
        let mockPort = MockContextPort()
        // No mock responses = no context available

        let mockHandler = MockInteractionHandler(responses: ["PostgreSQL"])
        let collector = ClarificationCollector(
            interactionHandler: mockHandler,
            contextRequestPort: mockPort
        )

        let questions = ["What database to use?"]

        // Act
        let responses = await collector.collectClarifications(
            for: questions,
            requestId: UUID(),
            category: nil
        )

        // Assert
        XCTAssertEqual(responses["What database to use?"], "PostgreSQL")
    }
}
```

#### 3. Test ServerContextRequestAdapter

**File**: `Tests/InfrastructureTests/Adapters/ServerContextRequestAdapterTests.swift`

```swift
import XCTest
@testable import Infrastructure
@testable import Domain

final class ServerContextRequestAdapterTests: XCTestCase {
    var adapter: ServerContextRequestAdapter!
    var mockCodebaseRepo: MockCodebaseRepository!
    var mockMockupRepo: MockMockupUploadRepository!

    override func setUp() {
        super.setUp()
        mockCodebaseRepo = MockCodebaseRepository()
        mockMockupRepo = MockMockupUploadRepository()

        adapter = ServerContextRequestAdapter(
            codebaseRepository: mockCodebaseRepo,
            mockupUploadRepository: mockMockupRepo,
            prdCodebaseLink: MockPRDCodebaseLink(),
            embeddingGenerator: MockEmbeddingGenerator(),
            aiProvider: MockAIProvider()
        )
    }

    func testRequestCodebaseContextSuccess() async throws {
        // Arrange
        let projectId = UUID()
        let mockChunks = [
            SimilarCodeChunk(
                chunk: CodeChunk(...),
                similarity: 0.85
            )
        ]
        mockCodebaseRepo.mockSimilarChunks = mockChunks

        // Act
        let response = try await adapter.requestCodebaseContext(
            projectId: projectId,
            question: "What authentication method?",
            searchQuery: "authentication oauth"
        )

        // Assert
        XCTAssertNotNil(response)
        XCTAssertGreaterThan(response!.confidence, 0.7)
        XCTAssertEqual(response!.chunksAnalyzed, 1)
    }

    func testRequestCodebaseContextNoResults() async throws {
        // Arrange
        mockCodebaseRepo.mockSimilarChunks = []

        // Act
        let response = try await adapter.requestCodebaseContext(
            projectId: UUID(),
            question: "Unknown question",
            searchQuery: "unknown"
        )

        // Assert
        XCTAssertNil(response)
    }

    func testHasAdditionalContext() async {
        // Arrange
        mockMockupRepo.mockCount = 3

        // Act
        let availability = await adapter.hasAdditionalContext(requestId: UUID())

        // Assert
        XCTAssertTrue(availability.hasMockups)
        XCTAssertEqual(availability.mockupCount, 3)
    }
}
```

### Integration Tests

#### Test End-to-End Flow

**File**: `Tests/IntegrationTests/ContextPortIntegrationTests.swift`

```swift
import XCTest
@testable import Application
@testable import Infrastructure
@testable import Domain

final class ContextPortIntegrationTests: XCTestCase {
    var useCase: GeneratePRDUseCase!

    func testPRDGenerationWithCodebaseContext() async throws {
        // Arrange: Setup real repositories with test data
        let testDB = TestDatabaseSetup()
        let codebaseRepo = SupabaseCodebaseRepository(...)
        let mockupRepo = SupabaseMockupUploadRepository(...)

        // Insert test codebase with OAuth2 implementation
        let codebase = try await testDB.insertTestCodebase(
            repositoryUrl: "https://github.com/test/repo",
            hasAuth: true
        )

        // Insert test PRD request linked to codebase
        let request = try await testDB.insertTestPRDRequest(
            title: "Add user authentication",
            linkedCodebaseId: codebase.id
        )

        useCase = GeneratePRDUseCase(
            aiProvider: TestAIProvider(),
            prdRepository: SupabasePRDRepository(...),
            documentRepository: SupabasePRDDocumentRepository(...),
            prdCodebaseLink: SupabasePRDCodebaseLinkRepository(...),
            codebaseRepository: codebaseRepo,
            mockupUploadRepository: mockupRepo,
            embeddingGenerator: TestEmbeddingGenerator()
        )

        // Act
        let command = GeneratePRDCommand(
            requestId: request.id,
            title: "Add user authentication",
            description: "Implement secure user authentication system",
            mockupSources: [],
            priority: "high",
            requester: "test@example.com",
            preferredProvider: nil,
            options: GenerationOptions()
        )

        let document = try await useCase.execute(command)

        // Assert
        XCTAssertTrue(document.content.contains("OAuth2"))
        XCTAssertTrue(document.content.contains("JWT"))
        XCTAssertEqual(document.confidence, 0.85, accuracy: 0.1)

        // Cleanup
        try await testDB.cleanup()
    }
}
```

---

## Migration Path

### Phase 1: Foundation (Week 1)

**Goal**: Define protocols and interfaces

1. ✅ Create `ContextRequestPort.swift` in library Domain layer
2. ✅ Define response models (`CodebaseContextResponse`, `MockupContextResponse`, `ContextAvailability`)
3. ✅ Write unit tests for protocol models
4. ✅ Update `CLAUDE.md` with architecture documentation

**Deliverables**:
- Protocol definition
- Response models
- Unit tests
- Documentation

**Risk**: Low - No breaking changes, purely additive

---

### Phase 2: Library Integration (Week 2)

**Goal**: Update library to support context port

1. ✅ Add `contextRequestPort` parameter to `RequirementsAnalyzer`
2. ✅ Add `contextRequestPort` parameter to `ClarificationCollector`
3. ✅ Implement `tryAnswerFromContext()` logic in `ClarificationCollector`
4. ✅ Add `setRequestContext()` method to pass request/project IDs
5. ✅ Update `PRDGenerator` to accept and pass context port
6. ✅ Write unit tests with mock context port

**Deliverables**:
- Updated library components
- Mock implementation for testing
- Unit tests for clarification flow
- Integration tests

**Risk**: Medium - Changes core generation logic, requires thorough testing

---

### Phase 3: Server Implementation (Week 3)

**Goal**: Implement server-side adapter

1. ✅ Create `ServerContextRequestAdapter.swift` in Infrastructure layer
2. ✅ Implement `requestCodebaseContext()` with RAG search
3. ✅ Implement `requestMockupContext()` with filtering logic
4. ✅ Implement `hasAdditionalContext()` with DB queries
5. ✅ Add helper methods for AI summary generation
6. ✅ Write integration tests with real database

**Deliverables**:
- Server adapter implementation
- RAG semantic search integration
- Mockup filtering logic
- Integration tests

**Risk**: Medium - Database queries and AI calls, performance testing required

---

### Phase 4: Wiring & Integration (Week 4)

**Goal**: Connect library and server

1. ✅ Update `GeneratePRDUseCase.execute()` to create adapter
2. ✅ Update `NativePRDGeneratorProvider.generatePRD()` to accept context port
3. ✅ Pass context port through generation pipeline
4. ✅ Add logging and monitoring
5. ✅ End-to-end integration tests
6. ✅ Performance testing

**Deliverables**:
- Complete end-to-end flow
- Logging and monitoring
- Integration tests
- Performance benchmarks

**Risk**: Low - Integration layer, well-defined interfaces

---

### Phase 5: Testing & Refinement (Week 5)

**Goal**: Validate and optimize

1. ✅ Run full test suite (unit + integration + e2e)
2. ✅ Test with real GitHub repositories
3. ✅ Test with real mockup uploads
4. ✅ Measure performance (response time, token usage)
5. ✅ Optimize confidence thresholds
6. ✅ Optimize search query extraction
7. ✅ User acceptance testing

**Deliverables**:
- Full test coverage report
- Performance benchmarks
- Optimized thresholds
- UAT results

**Risk**: Low - Testing and refinement phase

---

### Phase 6: Deployment (Week 6)

**Goal**: Ship to production

1. ✅ Feature flag for context port (gradual rollout)
2. ✅ Deploy to staging environment
3. ✅ Monitor metrics (auto-resolution rate, user satisfaction)
4. ✅ A/B test (with vs without context port)
5. ✅ Deploy to production (50% → 100%)
6. ✅ Update user documentation

**Deliverables**:
- Production deployment
- Monitoring dashboard
- A/B test results
- User documentation

**Risk**: Low - Feature flag allows safe rollout

---

## Benefits & Trade-offs

### Benefits

#### 1. **User Experience**
- ✅ **Fewer Questions**: Auto-resolves 40-60% of clarifications from DB
- ✅ **Faster Generation**: Reduces user interaction time by 50%
- ✅ **Higher Satisfaction**: Users appreciate intelligent context awareness

#### 2. **PRD Quality**
- ✅ **More Accurate**: Uses actual codebase patterns instead of assumptions
- ✅ **Consistent**: Matches existing architectural decisions
- ✅ **Comprehensive**: Includes mockup insights automatically

#### 3. **Architecture**
- ✅ **Clean Separation**: Library remains independent via DIP
- ✅ **Testable**: Mock port for unit tests, real adapter for integration
- ✅ **Extensible**: Easy to add new context sources (documentation, APIs, etc.)

#### 4. **Cost Efficiency**
- ✅ **Reduced Token Usage**: Fewer clarification rounds = fewer LLM calls
- ✅ **Better ROI**: Higher quality PRDs with less user effort

### Trade-offs

#### 1. **Complexity**
- ❌ **Additional Code**: ~500 LOC for port + adapter + tests
- ❌ **Learning Curve**: Developers need to understand port architecture
- ✅ **Mitigated By**: Good documentation, clear separation of concerns

#### 2. **Performance**
- ❌ **Additional Queries**: RAG search adds ~200-500ms per clarification
- ❌ **Database Load**: Vector similarity search can be expensive
- ✅ **Mitigated By**: Caching, optimized indexes, confidence thresholds

#### 3. **Maintenance**
- ❌ **Two Codebases**: Changes require updates in library + server
- ❌ **Versioning**: Port interface changes need careful coordination
- ✅ **Mitigated By**: Semantic versioning, backward compatibility

#### 4. **Edge Cases**
- ❌ **False Positives**: May auto-answer incorrectly (confidence < 100%)
- ❌ **Incomplete Context**: RAG may miss relevant code chunks
- ✅ **Mitigated By**: Confidence thresholds, user review, feedback loop

### Performance Benchmarks (Expected)

| Metric | Without Context Port | With Context Port | Improvement |
|--------|---------------------|-------------------|-------------|
| Avg Clarifications per PRD | 5-7 | 2-4 | -40% to -60% |
| User Interaction Time | 3-5 min | 1-2 min | -50% to -60% |
| PRD Generation Time | 2-3 min | 2.5-3.5 min | +10% to +20% |
| Auto-Resolution Rate | 0% | 40-60% | N/A |
| User Satisfaction | Baseline | +25% to +35% | N/A |
| Token Usage per PRD | 10K-15K | 8K-12K | -20% to -25% |

---

## Advanced Features (Future Enhancements)

### 1. Multi-Source Context Fusion

Combine multiple context sources for higher confidence:

```swift
func requestCombinedContext(
    requestId: UUID,
    question: String
) async throws -> CombinedContextResponse? {
    // Try codebase
    let codebaseCtx = try? await requestCodebaseContext(...)

    // Try mockups
    let mockupCtx = try? await requestMockupContext(...)

    // Try documentation (future)
    let docsCtx = try? await requestDocumentationContext(...)

    // Fuse responses with weighted confidence
    return fuseSources([codebaseCtx, mockupCtx, docsCtx])
}
```

### 2. Streaming Context Responses

Stream context as it's found (WebSocket):

```swift
func requestCodebaseContext(
    projectId: UUID,
    question: String,
    searchQuery: String,
    onChunkFound: @escaping (CodeFileContext) -> Void
) async throws -> CodebaseContextResponse? {
    let chunks = try await codebaseRepository.findSimilarChunks(...)

    for chunk in chunks {
        let fileContext = CodeFileContext(...)
        onChunkFound(fileContext) // Stream to UI
    }

    return CodebaseContextResponse(...)
}
```

### 3. Learning & Feedback Loop

Track auto-resolution accuracy and adjust thresholds:

```swift
struct ContextResolutionFeedback: Sendable {
    let questionId: UUID
    let autoAnswer: String
    let wasCorrect: Bool
    let userCorrection: String?
    let confidence: Double
}

func submitFeedback(_ feedback: ContextResolutionFeedback) async {
    // Store in database
    // Adjust confidence thresholds based on accuracy
    // Retrain embedding model if needed
}
```

### 4. Contextual Clarification Prioritization

Prioritize clarifications that can't be auto-resolved:

```swift
func prioritizeClarifications(
    _ questions: [String],
    requestId: UUID
) async -> (autoResolvable: [String], userRequired: [String]) {
    var auto: [String] = []
    var manual: [String] = []

    for question in questions {
        if canAutoResolve(question, requestId: requestId) {
            auto.append(question)
        } else {
            manual.append(question)
        }
    }

    return (auto, manual)
}
```

---

## Conclusion

The **Context Request Port** architecture solves a critical gap in the current PRD generation system by enabling **two-way communication** between the library and server while maintaining **Clean Architecture** principles.

### Key Takeaways

1. **Problem Solved**: Library can now query DB for clarification answers instead of always asking users
2. **Clean Design**: Uses Dependency Inversion Principle - library owns interface, server implements
3. **Backward Compatible**: Optional dependency, works with or without server
4. **Measurable Impact**: Expected 40-60% reduction in user clarifications, 50% faster generation
5. **Production Ready**: Comprehensive testing strategy, phased rollout plan, monitoring built-in

### Next Steps

1. Review and approve architecture design
2. Begin Phase 1 implementation (protocol definition)
3. Set up monitoring dashboard for metrics
4. Schedule weekly progress reviews

### Success Criteria

- ✅ Auto-resolution rate >= 40%
- ✅ User interaction time reduced by >= 50%
- ✅ PRD quality score increased by >= 20%
- ✅ No regressions in generation time or accuracy
- ✅ All tests passing (unit + integration + e2e)

---

**Document Version**: 1.0
**Last Updated**: 2025-01-03
**Author**: AI PRD Builder Team
**Status**: Ready for Implementation
