import Foundation
import AIBridge
import AIProviders

/// Handles chat session logic with clean separation of concerns
public struct ChatSessionHandler {

    private let orchestrator: Orchestrator
    private var currentThinkingMode: Orchestrator.ThinkingMode

    public init(orchestrator: Orchestrator, thinkingMode: Orchestrator.ThinkingMode = .automatic) {
        self.orchestrator = orchestrator
        self.currentThinkingMode = thinkingMode
    }

    // MARK: - Session Setup

    public func displayWelcome() {
        print(CommandConstants.Messages.welcomeMessage)
        print(CommandConstants.Messages.welcomeInstructions)
    }

    public func displayGlossaryInfo() async {
        let glossarySummary = await orchestrator.listGlossary()
            .prefix(CommandConstants.Thresholds.glossaryPreviewCount)
            .map { "\($0.acronym)\(CommandConstants.Separators.glossaryFormat)\($0.definition)" }
            .joined(separator: CommandConstants.Separators.glossaryJoiner)

        print("\(CommandConstants.Messages.domainPrefix)\(glossarySummary.isEmpty ? CommandConstants.Messages.glossaryNone : glossarySummary)")
        print(CommandConstants.Messages.chatModeActive)
    }

    // MARK: - Command Handling

    public mutating func handleCommand(_ input: String) async -> Bool {
        let command = CommandParser.parse(input)

        switch command.type {
        case .help:
            CommandHandlers.displayHelp()
        case .glossary:
            await CommandHandlers.handleGlossary(command.args, orchestrator: orchestrator)
        case .thinking:
            currentThinkingMode = await CommandHandlers.handleThinking(
                command.args,
                currentMode: currentThinkingMode,
                orchestrator: orchestrator
            )
        case .exit:
            return false  // Signal to exit
        case .unknown:
            print(CommandConstants.Messages.unknownCommand)
        case .notCommand:
            return false  // Not a command, process as message
        }

        return true
    }

    // MARK: - Message Processing

    public func processMessage(_ message: String) async throws {
        let processor = MessageProcessor(
            orchestrator: orchestrator,
            thinkingMode: currentThinkingMode
        )

        try await processor.process(message)
    }

    // MARK: - Session State

    public func getCurrentThinkingMode() -> Orchestrator.ThinkingMode {
        return currentThinkingMode
    }

    public mutating func setThinkingMode(_ mode: Orchestrator.ThinkingMode) {
        currentThinkingMode = mode
    }
}
