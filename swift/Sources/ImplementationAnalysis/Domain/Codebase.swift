import Foundation

/// Represents a codebase that can be analyzed and linked to PRDs
/// This is a lightweight representation used for user-facing codebase management
public struct Codebase: Identifiable, Codable, Sendable {
    public let id: UUID
    public let name: String
    public let repositoryUrl: String?
    public let description: String?
    public let createdAt: Date
    public let updatedAt: Date
    public let userId: UUID

    public init(
        id: UUID = UUID(),
        name: String,
        repositoryUrl: String? = nil,
        description: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        userId: UUID
    ) {
        self.id = id
        self.name = name
        self.repositoryUrl = repositoryUrl
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.userId = userId
    }
}

// NOTE: CodeFile is defined in CodebaseContext.swift to avoid duplicate definitions
