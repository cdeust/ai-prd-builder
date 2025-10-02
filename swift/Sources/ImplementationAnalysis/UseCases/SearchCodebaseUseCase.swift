import Foundation
import Foundation

/// Use case for searching codebase files using semantic search
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
}
