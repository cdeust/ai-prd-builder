import Foundation
import Foundation

/// Use case for listing all codebases for a user
public struct ListCodebasesUseCase {
    private let repository: CodebaseRepositoryProtocol

    public init(repository: CodebaseRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(userId: UUID) async throws -> [Codebase] {
        return try await repository.listCodebases(forUser: userId)
    }
}
