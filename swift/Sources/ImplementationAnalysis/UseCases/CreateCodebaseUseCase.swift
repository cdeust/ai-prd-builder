import Foundation
import Foundation

/// Use case for creating a new codebase
public struct CreateCodebaseUseCase {
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
        public let name: String
        public let repositoryUrl: String?
        public let description: String?
        public let userId: UUID

        public init(
            name: String,
            repositoryUrl: String?,
            description: String?,
            userId: UUID
        ) {
            self.name = name
            self.repositoryUrl = repositoryUrl
            self.description = description
            self.userId = userId
        }
    }

    public func execute(_ input: Input) async throws -> Codebase {
        // Create codebase entity
        let codebase = Codebase(
            id: UUID(),
            name: input.name,
            repositoryUrl: input.repositoryUrl,
            description: input.description,
            createdAt: Date(),
            updatedAt: Date(),
            userId: input.userId
        )

        // Save to repository
        return try await repository.createCodebase(codebase)
    }
}
