import Foundation
import DomainCore

/// Repository protocol for session persistence
/// Orchestration layer protocol - implementations provide session storage
public protocol SessionRepositoryProtocol {
    /// Create a new session
    func create() async throws -> Session

    /// Fetch a session by ID
    func fetch(id: UUID) async throws -> Session?

    /// Save or update a session
    func save(_ session: Session) async throws

    /// Delete a session
    func delete(id: UUID) async throws

    /// List all active sessions
    func listActive() async throws -> [Session]
}
