import Foundation
import AIProvidersCore
import CommonModels
import DomainCore

/// Manages chat sessions, history, and session-specific glossaries
public class SessionManagement {

    // MARK: - Properties

    private var sessionHistory: [UUID: [ChatMessage]] = [:]
    private var currentSession: UUID?
    private var sessionGlossary: [UUID: Glossary] = [:]

    // MARK: - Initialization

    public init() {
        self.currentSession = UUID()
        self.sessionHistory[currentSession!] = []
    }

    // MARK: - Session Operations

    /// Starts a new session and returns its ID
    public func startNewSession() -> UUID {
        let sessionId = UUID()
        currentSession = sessionId
        sessionHistory[sessionId] = []
        return sessionId
    }

    /// Clears the conversation history for current session
    public func clearConversation() {
        guard let session = currentSession else { return }
        sessionHistory[session] = []
    }

    /// Stores a message in the current session
    public func storeInSession(content: String, role: ChatMessage.Role) {
        guard let session = currentSession else { return }

        let message = ChatMessage(
            role: role,
            content: content
        )

        if sessionHistory[session] == nil {
            sessionHistory[session] = []
        }
        sessionHistory[session]?.append(message)
    }

    // MARK: - Session Retrieval

    /// Gets the current session ID
    public var sessionId: UUID {
        return currentSession ?? UUID()
    }

    /// Gets conversation history for current session
    public var conversationHistory: [ChatMessage] {
        guard let session = currentSession else { return [] }
        return sessionHistory[session] ?? []
    }

    /// Gets session history for specific session or current
    public func getSessionHistory(_ sessionId: UUID? = nil) -> [ChatMessage] {
        let targetSession = sessionId ?? currentSession ?? UUID()
        return sessionHistory[targetSession] ?? []
    }

    /// Gets all session IDs
    public func getAllSessionIds() -> [UUID] {
        return Array(sessionHistory.keys)
    }

    // MARK: - Glossary Management

    /// Sets glossary for current session
    public func setGlossaryForCurrentSession(_ glossary: Glossary) {
        guard let session = currentSession else { return }
        sessionGlossary[session] = glossary
    }

    /// Gets glossary for current session
    public func glossaryForCurrentSession() -> Glossary {
        guard let session = currentSession,
              let glossary = sessionGlossary[session] else {
            return Glossary(domain: "default", entries: [])
        }
        return glossary
    }

    /// Updates glossary for specific session
    public func updateGlossary(for sessionId: UUID, glossary: Glossary) {
        sessionGlossary[sessionId] = glossary
    }

    // MARK: - Session Cleanup

    /// Removes a specific session
    public func removeSession(_ sessionId: UUID) {
        sessionHistory.removeValue(forKey: sessionId)
        sessionGlossary.removeValue(forKey: sessionId)

        if currentSession == sessionId {
            currentSession = nil
        }
    }

    /// Clears all sessions
    public func clearAllSessions() {
        sessionHistory.removeAll()
        sessionGlossary.removeAll()
        currentSession = nil
    }
}

// MARK: - SessionRepositoryProtocol Conformance

extension SessionManagement: SessionRepositoryProtocol {
    public func create() async throws -> Session {
        let sessionId = startNewSession()
        return Session(
            id: sessionId,
            startTime: Date(),
            messages: [],
            metadata: SessionMetadata()
        )
    }

    public func fetch(id: UUID) async throws -> Session? {
        let messages = getSessionHistory(id)
        guard !messages.isEmpty || sessionHistory.keys.contains(id) else {
            return nil
        }

        return Session(
            id: id,
            startTime: Date(), // We don't track this currently
            messages: messages,
            metadata: SessionMetadata(messageCount: messages.count)
        )
    }

    public func save(_ session: Session) async throws {
        // Store messages in session history
        sessionHistory[session.id] = session.messages

        // If this is the current session, keep it current
        if currentSession == nil || session.metadata.isActive {
            currentSession = session.id
        }
    }

    public func delete(id: UUID) async throws {
        removeSession(id)
    }

    public func listActive() async throws -> [Session] {
        return getAllSessionIds().compactMap { id in
            let messages = getSessionHistory(id)
            return Session(
                id: id,
                startTime: Date(),
                messages: messages,
                metadata: SessionMetadata(
                    messageCount: messages.count,
                    isActive: id == currentSession
                )
            )
        }.filter { $0.metadata.isActive }
    }
}