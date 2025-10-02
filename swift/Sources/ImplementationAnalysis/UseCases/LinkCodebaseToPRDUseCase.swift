import Foundation
import Foundation

/// Use case for linking a codebase to a PRD
public struct LinkCodebaseToPRDUseCase {
    private let repository: PRDCodebaseLink

    public init(repository: PRDCodebaseLink) {
        self.repository = repository
    }

    public struct Input {
        public let prdId: UUID
        public let codebaseId: UUID

        public init(prdId: UUID, codebaseId: UUID) {
            self.prdId = prdId
            self.codebaseId = codebaseId
        }
    }

    public func execute(_ input: Input) async throws {
        try await repository.linkCodebaseToPRD(
            prdId: input.prdId,
            codebaseId: input.codebaseId
        )
    }
}
