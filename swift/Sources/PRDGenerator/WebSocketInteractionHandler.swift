import Foundation

/// WebSocket-based interaction handler for remote PRD generation
/// This handler sends structured JSON messages over a websocket connection
/// for real-time communication with web clients
public final class WebSocketInteractionHandler: UserInteractionHandler {

    public typealias MessageSender = (String) async throws -> Void
    public typealias ResponseReceiver = () async throws -> String

    private let sendMessage: MessageSender
    private let receiveResponse: ResponseReceiver

    /// Timeout for waiting for user responses (default: 5 minutes)
    public var responseTimeout: TimeInterval = 300

    public init(
        sendMessage: @escaping MessageSender,
        receiveResponse: @escaping ResponseReceiver
    ) {
        self.sendMessage = sendMessage
        self.receiveResponse = receiveResponse
    }

    // MARK: - UserInteractionHandler Implementation

    public func askQuestion(_ question: String) async -> String {
        do {
            let message = WebSocketMessage(
                type: .question,
                payload: ["question": question]
            )
            try await sendMessage(message.toJSON())

            // Wait for response with timeout
            return try await withTimeout(responseTimeout) {
                try await self.receiveResponse()
            }
        } catch {
            return ""
        }
    }

    public func askMultipleChoice(_ question: String, options: [String]) async -> String {
        do {
            let message = WebSocketMessage(
                type: .multipleChoice,
                payload: [
                    "question": question,
                    "options": options
                ]
            )
            try await sendMessage(message.toJSON())

            return try await withTimeout(responseTimeout) {
                try await self.receiveResponse()
            }
        } catch {
            return options.first ?? ""
        }
    }

    public func askYesNo(_ question: String) async -> Bool {
        do {
            let message = WebSocketMessage(
                type: .yesNo,
                payload: ["question": question]
            )
            try await sendMessage(message.toJSON())

            let response = try await withTimeout(responseTimeout) {
                try await self.receiveResponse()
            }
            return response.lowercased() == "y" || response.lowercased() == "yes"
        } catch {
            return false
        }
    }

    public func showInfo(_ message: String) {
        Task {
            do {
                let msg = WebSocketMessage(
                    type: .info,
                    payload: ["message": message]
                )
                try await sendMessage(msg.toJSON())
            } catch {
                // Silently fail - websocket may be closed
            }
        }
    }

    public func showWarning(_ message: String) {
        Task {
            do {
                let msg = WebSocketMessage(
                    type: .warning,
                    payload: ["message": message]
                )
                try await sendMessage(msg.toJSON())
            } catch {
                // Silently fail
            }
        }
    }

    public func showProgress(_ message: String) {
        Task {
            do {
                let msg = WebSocketMessage(
                    type: .progress,
                    payload: ["message": message]
                )
                try await sendMessage(msg.toJSON())
            } catch {
                // Silently fail
            }
        }
    }

    public func showDebug(_ message: String) {
        Task {
            do {
                let msg = WebSocketMessage(
                    type: .debug,
                    payload: ["message": message]
                )
                try await sendMessage(msg.toJSON())
            } catch {
                // Silently fail
            }
        }
    }

    public func showSectionContent(_ content: String) {
        Task {
            do {
                let msg = WebSocketMessage(
                    type: .sectionContent,
                    payload: ["content": content]
                )
                try await sendMessage(msg.toJSON())
            } catch {
                // Silently fail
            }
        }
    }

    // MARK: - Professional Analysis Methods

    public func showProfessionalAnalysis(_ summary: String, hasCritical: Bool) {
        Task {
            do {
                let msg = WebSocketMessage(
                    type: .professionalAnalysis,
                    payload: [
                        "summary": summary,
                        "hasCriticalIssues": hasCritical
                    ]
                )
                try await sendMessage(msg.toJSON())
            } catch {
                // Silently fail
            }
        }
    }

    public func showArchitecturalConflict(_ conflict: String, severity: String) {
        Task {
            do {
                let msg = WebSocketMessage(
                    type: .architecturalConflict,
                    payload: [
                        "conflict": conflict,
                        "severity": severity
                    ]
                )
                try await sendMessage(msg.toJSON())
            } catch {
                // Silently fail
            }
        }
    }

    public func showTechnicalChallenge(_ challenge: String, priority: String) {
        Task {
            do {
                let msg = WebSocketMessage(
                    type: .technicalChallenge,
                    payload: [
                        "challenge": challenge,
                        "priority": priority
                    ]
                )
                try await sendMessage(msg.toJSON())
            } catch {
                // Silently fail
            }
        }
    }

    public func showComplexityScore(_ score: Int, needsBreakdown: Bool) {
        Task {
            do {
                let msg = WebSocketMessage(
                    type: .complexityScore,
                    payload: [
                        "score": score,
                        "needsBreakdown": needsBreakdown
                    ]
                )
                try await sendMessage(msg.toJSON())
            } catch {
                // Silently fail
            }
        }
    }

    // MARK: - Helper Methods

    private func withTimeout<T>(
        _ timeout: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw WebSocketError.timeout
            }

            guard let result = try await group.next() else {
                throw WebSocketError.timeout
            }

            group.cancelAll()
            return result
        }
    }
}

// MARK: - Supporting Types

/// WebSocket message structure for client communication
public struct WebSocketMessage: Codable {
    public let type: MessageType
    public let payload: [String: AnyCodable]
    public let timestamp: String

    public init(type: MessageType, payload: [String: Any]) {
        self.type = type
        self.payload = payload.mapValues { AnyCodable($0) }
        self.timestamp = ISO8601DateFormatter().string(from: Date())
    }

    public func toJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

/// Message types for WebSocket communication
public enum MessageType: String, Codable {
    case question
    case multipleChoice
    case yesNo
    case info
    case warning
    case progress
    case debug
    case sectionContent
    case error
    case complete
    case professionalAnalysis
    case architecturalConflict
    case technicalChallenge
    case complexityScore
}

/// Type-erased wrapper for heterogeneous JSON encoding
public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported type"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(
                codingPath: container.codingPath,
                debugDescription: "Unsupported type: \(type(of: value))"
            )
            throw EncodingError.invalidValue(value, context)
        }
    }
}

/// WebSocket-specific errors
public enum WebSocketError: Error {
    case timeout
    case connectionClosed
    case encodingFailed
    case decodingFailed
}