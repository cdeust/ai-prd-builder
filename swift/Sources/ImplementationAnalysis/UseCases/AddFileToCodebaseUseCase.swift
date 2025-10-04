import Foundation
import Foundation

/// Use case for adding a file to a codebase
public struct AddFileToCodebaseUseCase {
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
        public let filePath: String
        public let content: String
        public let language: String?

        public init(
            codebaseId: UUID,
            filePath: String,
            content: String,
            language: String?
        ) {
            self.codebaseId = codebaseId
            self.filePath = filePath
            self.content = content
            self.language = language
        }
    }

    public func execute(_ input: Input) async throws -> CodeFile {
        // Calculate content hash
        let contentHash = input.content.sha256Hash

        // Detect language
        let language = input.language.flatMap { ProgrammingLanguage(rawValue: $0) }

        // Create code file entity
        let file = CodeFile(
            id: UUID(),
            codebaseProjectId: input.codebaseId,
            filePath: input.filePath,
            fileHash: contentHash,
            fileSize: input.content.utf8.count,
            language: language,
            isParsed: false,
            parseError: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Save to repository
        let savedFiles = try await repository.saveFiles([file], projectId: input.codebaseId)
        guard let savedFile = savedFiles.first else {
            throw CodebaseError.saveFailed
        }
        return savedFile
    }
}
