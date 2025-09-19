import Foundation
import Orchestration

/// Manages chat sessions and session-related operations
public struct SessionManager {

    private let orchestrator: Orchestrator

    public init(orchestrator: Orchestrator) {
        self.orchestrator = orchestrator
    }

    // MARK: - Session Management

    /// Starts a new session and displays the session ID
    public func startNewSession() -> UUID {
        let sessionId = orchestrator.startNewSession()
        displaySessionStarted(sessionId)
        return sessionId
    }

    /// Handles the session command in interactive mode
    public func handleSessionCommand() {
        let newSession = orchestrator.startNewSession()
        print("✅ New session started: \(newSession)")
    }

    // MARK: - Private Helpers

    private func displaySessionStarted(_ sessionId: UUID) {
        print("🚀 Session started: \(sessionId)\n")
    }
}