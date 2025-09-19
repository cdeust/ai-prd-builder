import Foundation
import Orchestration

/// Handles chat session interactions
public struct ChatSessionHandler {
    private let orchestrator: Orchestrator
    private var sessionHistory: [String] = []

    public init(orchestrator: Orchestrator) {
        self.orchestrator = orchestrator
    }

    public mutating func displayWelcome() {
        print("""
        \n💬 Chat Mode - Interactive AI Conversation
        Type 'exit' to return to main menu
        Type 'help' for available commands
        \n
        """)
    }

    public mutating func displayGlossaryInfo() async {
        print("ℹ️ Domain glossary loaded. Acronyms will be expanded on first use.\n")
    }

    public mutating func handleCommand(_ input: String) async -> Bool {
        switch input.lowercased() {
        case "help":
            displayHelp()
            return true
        case "clear":
            clearHistory()
            print("✅ Chat history cleared.\n")
            return true
        case "history":
            displayHistory()
            return true
        default:
            return false
        }
    }

    public mutating func processMessage(_ message: String) async throws {
        // Add to history
        sessionHistory.append("User: \(message)")

        // Process with orchestrator
        let response = try await orchestrator.chat(
            message: message,
            useAppleIntelligence: true
        )

        let responseText = response.response
        sessionHistory.append("AI: \(responseText)")

        // Display response
        print("\n🤖 [Provider: \(response.provider.rawValue)]")
        print("\(responseText)\n")
    }

    public mutating func handleInput(_ input: String) async -> String {
        // Add to history
        sessionHistory.append("User: \(input)")

        do {
            // Process with orchestrator
            let response = try await orchestrator.chat(
                message: input,
                useAppleIntelligence: true
            )

            let responseText = response.response
            sessionHistory.append("AI: \(responseText)")

            return responseText
        } catch {
            let errorMessage = "Error: \(error.localizedDescription)"
            sessionHistory.append(errorMessage)
            return errorMessage
        }
    }

    private func displayHelp() {
        print("""
        \n📚 Available Commands:
        - help: Show this help message
        - clear: Clear chat history
        - history: Show chat history
        - exit: Return to main menu
        \n
        """)
    }

    private func displayHistory() {
        print("\n🗓️ Chat History:")
        if sessionHistory.isEmpty {
            print("No messages yet.\n")
        } else {
            for message in sessionHistory {
                print(message)
            }
            print()
        }
    }

    public func getSessionHistory() -> [String] {
        return sessionHistory
    }

    public mutating func clearHistory() {
        sessionHistory.removeAll()
    }
}