import Foundation
import AIBridge
import AIProviders
import Dispatch

public enum InteractiveMode {
    // Session-scoped settings for the interactive chat mode
    // Now uses ChatSessionHandler for cleaner code organization

    /// Runs a simple chat session loop using Orchestrator.chat.
    public static func runChatSession(orchestrator: Orchestrator) async {
        var handler = ChatSessionHandler(orchestrator: orchestrator)

        // Display welcome and initial info
        handler.displayWelcome()
        await handler.displayGlossaryInfo()

        // Main interaction loop
        await runInteractionLoop(with: &handler, orchestrator: orchestrator)
    }

    /// Main interaction loop - handles input and delegates to appropriate handlers
    private static func runInteractionLoop(
        with handler: inout ChatSessionHandler,
        orchestrator: Orchestrator
    ) async {
        while true {
            // Get user input
            guard let input = getUserInput() else { continue }
            // Check for exit
            if shouldExit(input) { break }
            // Process input
            await processInput(input, handler: &handler)
        }
    }

    /// Get input from user with prompt
    private static func getUserInput() -> String? {
        print(CommandConstants.Format.inputPrompt, terminator: "")
        guard let input = readLine(), !input.isEmpty else { return nil }
        return input
    }

    /// Check if user wants to exit
    private static func shouldExit(_ input: String) -> Bool {
        return input.lowercased() == CommandConstants.Commands.exit
    }

    /// Process user input - either command or chat message
    private static func processInput(
        _ input: String,
        handler: inout ChatSessionHandler
    ) async {
        // Try to handle as command first
        let wasCommand = await handler.handleCommand(input)
        // If not a command, process as chat message
        if !wasCommand {
            await processChatMessage(input, handler: handler)
        }
    }

    /// Process a chat message
    private static func processChatMessage(
        _ message: String,
        handler: ChatSessionHandler
    ) async {
        do {
            try await handler.processMessage(message)
        } catch {
            CommandLineInterface.displayError("\(error)")
        }
    }

}
