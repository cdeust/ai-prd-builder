import Foundation
import Foundation

/// Use case for retrieving a codebase by ID
public struct GetCodebaseUseCase {
    private let repository: CodebaseRepositoryProtocol

    public init(repository: CodebaseRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(codebaseId: UUID) async throws -> Codebase? {
        return try await repository.getCodebase(by: codebaseId)
    }
}
