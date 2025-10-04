import Foundation

/// Use case for searching codebase files using semantic search and enriching PRD generation
public struct SearchCodebaseUseCase {
    private let repository: CodebaseRepositoryProtocol
    private let embeddingGenerator: EmbeddingGeneratorPort

    public init(
        repository: CodebaseRepositoryProtocol,
        embeddingGenerator: EmbeddingGeneratorPort
    ) {
        self.repository = repository
        self.embeddingGenerator = embeddingGenerator
    }

    // MARK: - File Search

    public struct Input {
        public let codebaseId: UUID
        public let query: String
        public let limit: Int
        public let similarityThreshold: Float?

        public init(
            codebaseId: UUID,
            query: String,
            limit: Int = 10,
            similarityThreshold: Float? = nil
        ) {
            self.codebaseId = codebaseId
            self.query = query
            self.limit = limit
            self.similarityThreshold = similarityThreshold
        }
    }

    public struct Output {
        public let file: CodeFile
        public let similarity: Float

        public init(file: CodeFile, similarity: Float) {
            self.file = file
            self.similarity = similarity
        }
    }

    public func execute(_ input: Input) async throws -> [Output] {
        // Generate embedding for search query
        let queryEmbedding = try await embeddingGenerator.generateEmbedding(text: input.query)

        // Search repository
        let results = try await repository.searchFiles(
            in: input.codebaseId,
            embedding: queryEmbedding,
            limit: input.limit,
            similarityThreshold: input.similarityThreshold
        )

        // Map to Output
        return results.map { Output(file: $0.file, similarity: $0.similarity) }
    }

    // MARK: - PRD Enrichment with Codebase Context

    public struct PRDEnrichmentInput {
        public let prdDescription: String
        public let projectId: UUID
        public let maxChunks: Int
        public let similarityThreshold: Float

        public init(
            prdDescription: String,
            projectId: UUID,
            maxChunks: Int = 20,
            similarityThreshold: Float = 0.6
        ) {
            self.prdDescription = prdDescription
            self.projectId = projectId
            self.maxChunks = maxChunks
            self.similarityThreshold = similarityThreshold
        }
    }

    public struct PRDEnrichmentOutput {
        public let codeContext: String
        public let relevantChunks: [RelevantCodeChunk]
        public let techStack: TechStackSummary
        public let architecturePatterns: [String]

        public init(
            codeContext: String,
            relevantChunks: [RelevantCodeChunk],
            techStack: TechStackSummary,
            architecturePatterns: [String]
        ) {
            self.codeContext = codeContext
            self.relevantChunks = relevantChunks
            self.techStack = techStack
            self.architecturePatterns = architecturePatterns
        }
    }

    public struct RelevantCodeChunk {
        public let filePath: String
        public let content: String
        public let chunkType: String
        public let language: String
        public let symbols: [String]
        public let similarity: Float
        public let lineRange: String

        public init(
            filePath: String,
            content: String,
            chunkType: String,
            language: String,
            symbols: [String],
            similarity: Float,
            lineRange: String
        ) {
            self.filePath = filePath
            self.content = content
            self.chunkType = chunkType
            self.language = language
            self.symbols = symbols
            self.similarity = similarity
            self.lineRange = lineRange
        }
    }

    public struct TechStackSummary {
        public let languages: [String: Int]
        public let frameworks: [String]
        public let primaryLanguage: String?

        public init(languages: [String: Int], frameworks: [String], primaryLanguage: String?) {
            self.languages = languages
            self.frameworks = frameworks
            self.primaryLanguage = primaryLanguage
        }
    }

    /// Enrich PRD generation with relevant codebase context using RAG
    public func enrichPRDWithCodebase(_ input: PRDEnrichmentInput) async throws -> PRDEnrichmentOutput {
        // Step 1: Generate embedding for the PRD description
        let queryEmbedding = try await embeddingGenerator.generateEmbedding(text: input.prdDescription)

        // Step 2: Search for similar code chunks using vector search
        let similarChunks = try await repository.findSimilarChunks(
            projectId: input.projectId,
            queryEmbedding: queryEmbedding,
            limit: input.maxChunks,
            similarityThreshold: input.similarityThreshold
        )

        // Step 3: Get project metadata for tech stack and architecture
        guard let project = try await repository.findProjectById(input.projectId) else {
            throw CodebaseError.projectNotFound(input.projectId)
        }

        // Step 4: Convert to relevant code chunks with rich metadata
        let relevantChunks = similarChunks.map { similar in
            RelevantCodeChunk(
                filePath: similar.chunk.filePath,
                content: similar.chunk.content,
                chunkType: similar.chunk.chunkType.rawValue,
                language: similar.chunk.language.rawValue,
                symbols: similar.chunk.symbols,
                similarity: Float(similar.similarity),
                lineRange: "\(similar.chunk.startLine)-\(similar.chunk.endLine)"
            )
        }

        // Step 5: Build enriched code context for PRD
        let codeContext = buildCodeContext(
            chunks: relevantChunks,
            project: project
        )

        // Step 6: Extract tech stack summary
        let techStack = extractTechStack(from: project)

        // Step 7: Extract architecture patterns
        let architecturePatterns = extractArchitecturePatterns(from: project)

        return PRDEnrichmentOutput(
            codeContext: codeContext,
            relevantChunks: relevantChunks,
            techStack: techStack,
            architecturePatterns: architecturePatterns
        )
    }

    // MARK: - Helper Methods

    private func buildCodeContext(
        chunks: [RelevantCodeChunk],
        project: CodebaseProject
    ) -> String {
        var context = """
        # Codebase Context

        **Repository:** \(project.repositoryUrl)
        **Branch:** \(project.repositoryBranch)
        **Languages:** \(formatLanguages(project.detectedLanguages))
        **Frameworks:** \(project.detectedFrameworks.joined(separator: ", "))

        ## Relevant Code Examples

        The following code snippets are semantically relevant to your PRD requirements:

        """

        for (index, chunk) in chunks.prefix(10).enumerated() {
            context += """

            ### \(index + 1). \(chunk.filePath) (lines \(chunk.lineRange))
            **Type:** \(chunk.chunkType) | **Language:** \(chunk.language) | **Similarity:** \(String(format: "%.2f", chunk.similarity * 100))%
            \(chunk.symbols.isEmpty ? "" : "**Symbols:** \(chunk.symbols.joined(separator: ", "))")

            ```\(chunk.language.lowercased())
            \(chunk.content)
            ```

            """
        }

        if chunks.count > 10 {
            context += """

            _Note: \(chunks.count - 10) additional relevant code chunks are available._
            """
        }

        return context
    }

    private func extractTechStack(from project: CodebaseProject) -> TechStackSummary {
        let languages = project.detectedLanguages
        let frameworks = project.detectedFrameworks

        // Find primary language (highest byte count)
        let primaryLanguage = languages.max(by: { $0.value < $1.value })?.key

        return TechStackSummary(
            languages: languages,
            frameworks: frameworks,
            primaryLanguage: primaryLanguage
        )
    }

    private func extractArchitecturePatterns(from project: CodebaseProject) -> [String] {
        return project.architecturePatterns.map { $0.name }
    }

    private func formatLanguages(_ languages: [String: Int]) -> String {
        let sorted = languages.sorted { $0.value > $1.value }
        return sorted.prefix(3).map { "\($0.key) (\($0.value) bytes)" }.joined(separator: ", ")
    }
}
