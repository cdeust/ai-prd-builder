import Foundation
import Orchestration
import AIProvidersCore
import AIProviderImplementations
import SessionManagement
import PRDGenerator
import DomainCore
import CommonModels

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
        CLIHelpers.MetalSetup.configure()

        let config = CommandLineArgumentParser.parse()
        let orchestrator = createOrchestrator(with: config)

        displayOrchestratorStatus()
        CLIHelpers.ProviderDisplay.displayPrivacyMode(allowExternal: config.allowExternal)
        displayProviders(orchestrator: orchestrator, allowExternal: config.allowExternal)
        CLIHelpers.ProviderDisplay.displayPrivacyPolicy()

        await routeCommand(config: config, orchestrator: orchestrator)
    }

    // MARK: - Initialization

    private static func createOrchestrator(with config: CommandLineArgumentParser.Configuration) -> Orchestrator {
        let privacyConfig = Orchestrator.PrivacyConfiguration(
            allowExternalProviders: config.allowExternal,
            requireUserConsent: true,
            logExternalCalls: true
        )

        print(CLIHelpers.OrchestratorConstantsExtensions.App.creatingMessage)
        let orchestrator = Orchestrator(privacyConfig: privacyConfig)
        print(CLIHelpers.OrchestratorConstantsExtensions.App.createdMessage)

        return orchestrator
    }

    // MARK: - Display Methods

    private static func displayHeader() {
        print(CLIHelpers.OrchestratorConstantsExtensions.App.title)
        print(CLIHelpers.OrchestratorConstantsExtensions.App.separator)
        print(CLIHelpers.OrchestratorConstantsExtensions.App.privacyFlow)
        print("")
    }

    private static func displayOrchestratorStatus() {
        // Status already printed in createOrchestrator
    }

    private static func displayProviders(orchestrator: Orchestrator, allowExternal: Bool) {
        let providers = orchestrator.getAvailableProviders()
        let providerNames = providers.map { $0.rawValue }
        CLIHelpers.ProviderDisplay.displayAvailableProviders(providerNames, allowExternal: allowExternal)
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
            CLIHelpers.HelpCommand.printHelp()

        case .version:
            CommandLineArgumentParser.printVersion()

        default:
            // Handle other commands as chat input
            await processChatMessage(command.rawValue, orchestrator: orchestrator)
        }
    }

    private static func handleUnknownCommand(_ command: String) {
        print("\(CLIHelpers.OrchestratorConstantsExtensions.UI.unknownCommand)\(command)")
        CLIHelpers.HelpCommand.printHelp()
    }

    // MARK: - Interactive Mode

    /// Runs the orchestrator in interactive mode with menu-driven interface.
    ///
    /// Provides an interactive CLI experience where users can generate PRDs,
    /// chat with AI providers, manage sessions, and more.
    private static func runInteractive(orchestrator: Orchestrator) async {
        CLIHelpers.CommandLineInterface.displayMainMenu()

        let sessionManager = SessionManager(orchestrator: orchestrator)
        _ = sessionManager.startNewSession()

        await runInteractionLoop(orchestrator: orchestrator, sessionManager: sessionManager)

        print(CLIHelpers.OrchestratorConstantsExtensions.App.thankYouMessage)
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
        case CLIHelpers.OrchestratorConstantsExtensions.Commands.chat:
            await runChatMode(orchestrator: orchestrator)

        case CLIHelpers.OrchestratorConstantsExtensions.Commands.prd:
            await runPRDGenerator(orchestrator: orchestrator)

        case CLIHelpers.OrchestratorConstantsExtensions.Commands.session:
            sessionManager.handleSessionCommand()

        default:
            await processChatMessage(input, orchestrator: orchestrator)
        }
    }

    private static func runChatMode(orchestrator: Orchestrator) async {
        await InteractiveMode.runChatSession(orchestrator: orchestrator)
    }

    private static func runPRDGenerator(orchestrator: Orchestrator) async {
        // Use Apple provider from orchestrator
        let appleProvider = AppleProvider()

        // Create configuration that respects privacy settings
        let configuration = Configuration(
            anthropicAPIKey: nil,
            openAIAPIKey: nil,
            geminiAPIKey: nil,
            maxPrivacyLevel: .onDevice,
            preferredProvider: "apple"
        )

        let generator = PRDGenerator(
            provider: appleProvider,
            configuration: configuration
        )

        print("Starting PRD generation...")
        print("Enter your product idea (type 'END' on a new line when finished, or press Enter for a sample):")

        // Read multi-line input
        var lines: [String] = []
        while let line = readLine() {
            if line.uppercased() == "END" {
                break
            }
            if lines.isEmpty && line.isEmpty {
                // Empty first line means use sample
                lines = ["Generate a sample PRD for a task management app"]
                break
            }
            lines.append(line)
        }

        let input = lines.isEmpty ?
            "Generate a sample PRD for a task management app" :
            lines.joined(separator: "\n")

        print("\n🔄 Processing your request...")
        print("📊 Analyzing product requirements...")

        do {
            let prd = try await generator.generatePRD(from: input)

            print("\n✅ Generated PRD:\n")
            print("Title: \(prd.title)\n")
            for section in prd.sections {
                print("\n## \(section.title)")
                print(section.content)
                for subsection in section.subsections {
                    print("\n### \(subsection.title)")
                    print(subsection.content)
                }
            }
        } catch let error as AIProviderError {
            print("\n❌ PRD Generation failed")
            switch error {
            case .notConfigured:
                print("Error: Apple Intelligence is not configured. Please ensure:")
                print("  - You're running macOS 16.0 Tahoe or later")
                print("  - Apple Intelligence is enabled in System Settings")
            case .configurationError(let message):
                print("Configuration error: \(message)")
                if message.contains("context window") {
                    print("\nTip: The input is too large. Try breaking it down into smaller sections.")
                }
            case .unsupportedFeature(let message):
                print("Unsupported: \(message)")
            default:
                print("Error: \(error)")
            }
        } catch {
            print("\n❌ Unexpected error: \(error)")
        }
    }

    private static func processChatMessage(_ message: String, orchestrator: Orchestrator) async {
        do {
            let (response, provider) = try await CLIHelpers.ProgressIndicator.withStatusFeedback(
                message: CLIHelpers.OrchestratorConstantsExtensions.Processing.processingMessage
            ) {
                try await orchestrator.chat(
                    message: message,
                    useAppleIntelligence: true
                )
            }

            displayChatResponse(response: response, provider: provider)
        } catch {
            CLIHelpers.CommandLineInterface.displayError("\(error)")
        }
    }

    // MARK: - Helper Methods

    private static func getUserInput() -> String? {
        print(CLIHelpers.OrchestratorConstantsExtensions.UI.inputPrompt, terminator: "")
        guard let input = readLine(), !input.isEmpty else { return nil }
        return input
    }

    private static func shouldExit(_ input: String) -> Bool {
        return input.lowercased() == CLIHelpers.OrchestratorConstantsExtensions.Commands.exit
    }

    private static func displayChatResponse(response: String, provider: Orchestrator.AIProvider) {
        print("\(CLIHelpers.OrchestratorConstantsExtensions.Processing.aiResponsePrefix)\(provider.rawValue)\(CLIHelpers.OrchestratorConstantsExtensions.Processing.aiResponseSuffix)\(response)\n")
    }

    // MARK: - Public Utilities

    /// Shows a processing status message (exposed for other components)
    public static func showProcessingStatus(_ message: String) {
        CLIHelpers.ProgressIndicator.showProcessingStatus(message)
    }
}