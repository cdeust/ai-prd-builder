import Foundation
import AIBridge
import AIProviders

/// Main entry point for the Swift-based AI orchestrator using Apple Intelligence via MLX.
///
/// This orchestrator provides a privacy-first approach to AI processing,
/// prioritizing Apple's on-device Foundation Models, then Private Cloud Compute,
/// and only using external providers when explicitly allowed.
///
/// - Note: Requires macOS 14+ for MLX/Metal support and macOS 15.1+ for Apple Intelligence Writing Tools
public struct AppleIntelligenceOrchestrator {

    // MARK: - Main Entry Point

    /// Main entry point that initializes the orchestrator and handles command routing.
    ///
    /// Configures the Metal environment, parses command-line arguments,
    /// and launches either command mode or interactive mode based on input.
    public static func runMain() async {
        displayHeader()
        MetalSetup.configure()

        let config = CommandLineArgumentParser.parse()
        let orchestrator = createOrchestrator(with: config)

        displayOrchestratorStatus()
        ProviderDisplay.displayPrivacyMode(allowExternal: config.allowExternal)
        displayProviders(orchestrator: orchestrator, allowExternal: config.allowExternal)
        ProviderDisplay.displayPrivacyPolicy()

        await routeCommand(config: config, orchestrator: orchestrator)
    }

    // MARK: - Initialization

    private static func createOrchestrator(with config: CommandLineArgumentParser.Configuration) -> Orchestrator {
        let privacyConfig = Orchestrator.PrivacyConfiguration(
            allowExternalProviders: config.allowExternal,
            requireUserConsent: true,
            logExternalCalls: true
        )

        print(OrchestratorConstants.App.creatingMessage)
        let orchestrator = Orchestrator(privacyConfig: privacyConfig)
        print(OrchestratorConstants.App.createdMessage)

        return orchestrator
    }

    // MARK: - Display Methods

    private static func displayHeader() {
        print(OrchestratorConstants.App.title)
        print(OrchestratorConstants.App.separator)
        print(OrchestratorConstants.App.privacyFlow)
        print("")
    }

    private static func displayOrchestratorStatus() {
        // Status already printed in createOrchestrator
    }

    private static func displayProviders(orchestrator: Orchestrator, allowExternal: Bool) {
        let providers = orchestrator.getAvailableProviders()
        ProviderDisplay.displayAvailableProviders(providers, allowExternal: allowExternal)
    }

    // MARK: - Command Routing

    private static func routeCommand(
        config: CommandLineArgumentParser.Configuration,
        orchestrator: Orchestrator
    ) async {
        if let command = config.command {
            await handleExplicitCommand(command, orchestrator: orchestrator)
        } else {
            // Default to interactive mode
            await runInteractive(orchestrator: orchestrator)
        }
    }

    private static func handleExplicitCommand(
        _ command: CommandLineArgumentParser.Configuration.Command,
        orchestrator: Orchestrator
    ) async {
        switch command {
        case .interactive:
            await runInteractive(orchestrator: orchestrator)

        case .help:
            HelpCommand.printHelp()

        case .unknown(let cmd):
            handleUnknownCommand(cmd)
        }
    }

    private static func handleUnknownCommand(_ command: String) {
        print("\(OrchestratorConstants.UI.unknownCommand)\(command)")
        HelpCommand.printHelp()
    }

    // MARK: - Interactive Mode

    /// Runs the orchestrator in interactive mode with menu-driven interface.
    ///
    /// Provides an interactive CLI experience where users can generate PRDs,
    /// chat with AI providers, manage sessions, and more.
    private static func runInteractive(orchestrator: Orchestrator) async {
        CommandLineInterface.displayMainMenu()

        let sessionManager = SessionManager(orchestrator: orchestrator)
        _ = sessionManager.startNewSession()

        await runInteractionLoop(orchestrator: orchestrator, sessionManager: sessionManager)

        print(OrchestratorConstants.App.thankYouMessage)
    }

    private static func runInteractionLoop(
        orchestrator: Orchestrator,
        sessionManager: SessionManager
    ) async {
        while true {
            guard let input = getUserInput() else { continue }

            if shouldExit(input) { break }

            await processUserCommand(
                input,
                orchestrator: orchestrator,
                sessionManager: sessionManager
            )
        }
    }

    // MARK: - Command Processing

    private static func processUserCommand(
        _ input: String,
        orchestrator: Orchestrator,
        sessionManager: SessionManager
    ) async {
        switch input.lowercased() {
        case OrchestratorConstants.Commands.chat:
            await runChatMode(orchestrator: orchestrator)

        case OrchestratorConstants.Commands.prd:
            await runPRDGenerator(orchestrator: orchestrator)

        case OrchestratorConstants.Commands.session:
            sessionManager.handleSessionCommand()

        default:
            await processChatMessage(input, orchestrator: orchestrator)
        }
    }

    private static func runChatMode(orchestrator: Orchestrator) async {
        await InteractiveMode.runChatSession(orchestrator: orchestrator)
    }

    private static func runPRDGenerator(orchestrator: Orchestrator) async {
        let generator = PRDGenerator(orchestrator: orchestrator)
        await generator.generate()
    }

    private static func processChatMessage(_ message: String, orchestrator: Orchestrator) async {
        do {
            let (response, provider) = try await ProgressIndicator.withStatusFeedback(
                message: OrchestratorConstants.Processing.processingMessage
            ) {
                try await orchestrator.chat(
                    message: message,
                    useAppleIntelligence: true
                )
            }

            displayChatResponse(response: response, provider: provider)
        } catch {
            CommandLineInterface.displayError("\(error)")
        }
    }

    // MARK: - Helper Methods

    private static func getUserInput() -> String? {
        print(OrchestratorConstants.UI.inputPrompt, terminator: "")
        guard let input = readLine(), !input.isEmpty else { return nil }
        return input
    }

    private static func shouldExit(_ input: String) -> Bool {
        return input.lowercased() == OrchestratorConstants.Commands.exit
    }

    private static func displayChatResponse(response: String, provider: Orchestrator.AIProvider) {
        print("\(OrchestratorConstants.Processing.aiResponsePrefix)\(provider.rawValue)\(OrchestratorConstants.Processing.aiResponseSuffix)\(response)\n")
    }

    // MARK: - Public Utilities

    /// Shows a processing status message (exposed for other components)
    public static func showProcessingStatus(_ message: String) {
        ProgressIndicator.showProcessingStatus(message)
    }
}