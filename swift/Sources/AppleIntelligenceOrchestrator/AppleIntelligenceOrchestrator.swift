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
    
    /// Main entry point that initializes the orchestrator and handles command routing.
    ///
    /// Configures the Metal environment, parses command-line arguments,
    /// and launches either command mode or interactive mode based on input.
    public static func runMain() async {
        print("🚀 Privacy-First AI Orchestrator")
        print("=================================")
        print("Apple Foundation Models → PCC → External (if allowed)")
        print("")
        
        // Configure Metal environment
        MetalSetup.configure()
        
        // Check for Apple Intelligence priority mode
        _ = CommandLine.arguments.contains("--apple-first") ||
                                    ProcessInfo.processInfo.environment["APPLE_INTELLIGENCE_FIRST"] == "true"
        
        // Check if user wants to allow external providers
        let allowExternal = CommandLine.arguments.contains("--allow-external") ||
                          ProcessInfo.processInfo.environment["ALLOW_EXTERNAL_PROVIDERS"] == "true"
        
        let privacyConfig = Orchestrator.PrivacyConfiguration(
            allowExternalProviders: allowExternal,
            requireUserConsent: true,
            logExternalCalls: true
        )
        
        print("Creating AIOrchestrator...")
        let orchestrator = Orchestrator(privacyConfig: privacyConfig)
        print("AIOrchestrator created")
        
        if allowExternal {
            print("⚠️  External providers enabled (use only when necessary)")
        } else {
            print("🔒 Privacy mode: Only Apple FM, PCC, and local models")
        }
        
        // Check available providers
        let providers = orchestrator.getAvailableProviders()
        
        print("📦 Available AI Providers (privacy-first order):")
        for provider in providers {
            var indicator = ""
            switch provider {
            case .foundationModels:
                indicator = " 🏠 (on-device)"
            case .privateCloudCompute:
                indicator = " ☁️ (privacy-preserved)"
            case .anthropic, .openai, .gemini:
                indicator = allowExternal ? " 🌐 (external)" : " ❌ (disabled)"
            }
            print("  • \(provider.rawValue)\(indicator)")
        }
        
        print("\n🔐 Privacy Policy:")
        print("  1. Apple Foundation Models (on-device, no data leaves)")
        print("  2. Private Cloud Compute (Apple servers, verifiable privacy)")
        print("  3. External APIs (only for complex/long context if --allow-external)")
        print("")
        
        // Parse command line arguments
        let arguments = CommandLine.arguments
        
        if arguments.count > 1 {
            switch arguments[1] {
            // PRD generation removed - keeping it simple
            case "interactive":
                await runInteractive(orchestrator: orchestrator)
            // Using Apple Intelligence (via MLX/Metal) + Big 3 cloud LLMs
            case "--help", "-h":
                printHelp()
            default:
                print("Unknown command: \(arguments[1])")
                printHelp()
            }
        } else {
            // Default to interactive mode
            await runInteractive(orchestrator: orchestrator)
        }
    }
    
    // PRD generation function removed - focusing on core chat functionality
    
    /// Runs the orchestrator in interactive mode with menu-driven interface.
    ///
    /// Provides an interactive CLI experience where users can generate PRDs,
    /// chat with AI providers, manage sessions, and more.
    ///
    /// - Parameter orchestrator: The AI orchestrator instance to use
    private static func runInteractive(orchestrator: Orchestrator) async {
        CommandLineInterface.displayMainMenu()
        
        // Start a new session
        let sessionId = orchestrator.startNewSession()
        print("🆕 Session started: \(sessionId)\n")
        
        while true {
            print("> ", terminator: "")
            guard let input = readLine(), !input.isEmpty else {
                continue
            }
            
            if input.lowercased() == "exit" {
                break
            }
            
            switch input.lowercased() {
            case "chat":
                await chatMode(orchestrator: orchestrator)
            case "prd":
                await generatePRD(orchestrator: orchestrator)
            case "session":
                let newSession = orchestrator.startNewSession()
                CommandLineInterface.displaySuccess("New session started: \(newSession)")
            case "exit":
                print("\n👋 Thank you for using the AI Orchestrator!")
                return
            default:
                // Treat as chat message - delegate to InteractiveMode
                do {
                    let (response, provider) = try await withStatusFeedback(
                        message: "Processing your message..."
                    ) {
                        try await orchestrator.chat(
                            message: input,
                            useAppleIntelligence: true
                        )
                    }
                    print("\n[🤖 \(provider)] \(response)\n")
                } catch {
                    CommandLineInterface.displayError("\(error)")
                }
            }
        }
        
        print("\n👋 Thank you for using the AI Orchestrator!")
    }
    
    // PRD generation removed - focusing on core chat functionality
    
    // Simplified to focus on core chat functionality
    /// then generates complete implementation including code, tests, and documentation.
    ///
    /// - Parameters:
    ///   - prd: The Product Requirements Document content
    ///   - feature: The feature name for file organization
    ///   - orchestrator: The orchestrator instance for AI operations
    ///   - hybrid: Whether to use hybrid mode (AI assists, user drives)
    // Implementation generation removed - focusing on core chat
    
    // Chat mode - delegate to InteractiveMode
    static func chatMode(orchestrator: Orchestrator) async {
        await InteractiveMode.runChatSession(orchestrator: orchestrator)
    }

    // Helper function to create a visual progress bar
    private static func createProgressBar(current: Int, total: Int) -> String {
        let percentage = Int((Double(current) / Double(total)) * 100)
        let filled = Int((Double(current) / Double(total)) * 20)
        let empty = 20 - filled

        let bar = String(repeating: "█", count: filled) + String(repeating: "░", count: empty)
        return "[\(bar)] \(percentage)% (\(current)/\(total))"
    }

    // Simple status indicator for API calls
    public static func showProcessingStatus(_ message: String) {
        print("⏳ \(message)")
    }

    // Helper to run async work with status feedback
    private static func withStatusFeedback<T>(
        message: String,
        work: () async throws -> T
    ) async throws -> T {
        showProcessingStatus(message)

        let startTime = Date()
        var warningShown = false

        // Create a timer that shows a warning after 30 seconds
        let timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { _ in
            if !warningShown {
                print("   ⚠️  Still waiting... This is taking longer than usual.")
                print("   (Apple Intelligence can take 30-60 seconds on first use)")
                warningShown = true
            }
        }

        defer {
            timer.invalidate()
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed > 5 {
                print("   ✓ Completed in \(String(format: "%.1f", elapsed)) seconds")
            }
        }

        return try await work()
    }

    // Generate PRD - simply get Apple Intelligence response in YAML
    static func generatePRD(orchestrator: Orchestrator) async {
        print("\n📋 PRD Generator (YAML)")
        print("========================")
        print("Describe what you want to build:")
        print("> ", terminator: "")

        guard let input = readLine(), !input.isEmpty else {
            print("No input provided")
            return
        }

        do {
            print("\n🤔 Processing initial PRD...")

            // Simply ask Apple Intelligence for a PRD in YAML format
            let prompt = """
            Create a Product Requirements Document for: \(input)

            Output in YAML format.
            """

            let (response, provider) = try await withStatusFeedback(
                message: "Contacting Apple Intelligence..."
            ) {
                try await orchestrator.chat(
                    message: prompt,
                    useAppleIntelligence: true
                )
            }

            print("[Provider: \(provider)]")
            print("\n" + String(repeating: "-", count: 60))
            print(response)
            print(String(repeating: "-", count: 60))

            // Store the PRD
            var fullPRD = response

            // Now ask for test data and acceptance criteria
            print("\n\n🧪 Getting test data and acceptance criteria...")

            let testDataPrompt = """
            For a service with these features:
            \(response)

            Create concrete test data and acceptance criteria:

            1. TEST DATA EXAMPLES:
            - Sample user inputs (at least 5 examples)
            - Expected outputs for each input
            - Edge cases to test
            - Error scenarios

            2. ACCEPTANCE CRITERIA (Given-When-Then format):
            - For each main feature
            - Success scenarios
            - Failure scenarios
            - Performance criteria

            3. VALIDATION METRICS:
            - How to measure success
            - Quality thresholds
            - Performance benchmarks

            Provide specific, concrete examples with actual data values.
            """

            print("⏳ Requesting test data from Apple Intelligence...")

            do {
                let (testData, testProvider) = try await orchestrator.chat(
                    message: testDataPrompt,
                    useAppleIntelligence: true
                )

                print("✅ Test data received from \(testProvider)")

                // Add test data to the PRD
                fullPRD += "\n\n# ===== TEST DATA & ACCEPTANCE CRITERIA =====\n"
                fullPRD += testData

                print("\n" + String(repeating: "-", count: 60))
                print("🧪 Test Data & Acceptance Criteria:")
                print(String(repeating: "-", count: 60))
                print(testData)
                print(String(repeating: "-", count: 60))

            } catch {
                print("⚠️ Could not get test data: \(error)")
                print("Continuing with basic PRD...")
            }

            // Now ask for implementation steps
            print("\n\n📋 Getting implementation steps...")

            let implementationStepsPrompt = """
            For building this service step by step:

            Provide a numbered list of implementation steps:
            1. What to build first
            2. Dependencies to set up
            3. Core components to create
            4. Integration points
            5. Testing approach
            6. Deployment steps

            Be practical and actionable.
            """

            print("⏳ Requesting implementation steps...")

            do {
                let (implSteps, stepsProvider) = try await orchestrator.chat(
                    message: implementationStepsPrompt,
                    useAppleIntelligence: true
                )

                print("✅ Implementation steps received from \(stepsProvider)")

                // Add implementation steps to the PRD
                fullPRD += "\n\n# ===== IMPLEMENTATION STEPS =====\n"
                fullPRD += implSteps

                print("\n" + String(repeating: "-", count: 60))
                print("📋 Implementation Steps:")
                print(String(repeating: "-", count: 60))
                print(implSteps)
                print(String(repeating: "-", count: 60))

            } catch {
                print("⚠️ Could not get implementation steps: \(error)")
            }

            // Show summary
            let wordCount = fullPRD.components(separatedBy: .whitespacesAndNewlines).count
            print("\n📊 Summary:")
            print("   • Total word count: ~\(wordCount)")
            print(String(repeating: "=", count: 60))

            print("\n✅ COMPLETE PRD:")
            print(String(repeating: "=", count: 60))
            print(fullPRD)
            print(String(repeating: "=", count: 60))

            // Offer to save to file
            print("\n💾 Save PRD to file? (yes/no)")
            print("> ", terminator: "")

            if let saveAnswer = readLine()?.lowercased(), saveAnswer == "yes" || saveAnswer == "y" {
                print("Enter filename (without extension, will save as .yaml):")
                print("> ", terminator: "")

                if let filename = readLine(), !filename.isEmpty {
                    let sanitizedFilename = filename.replacingOccurrences(of: " ", with: "_")
                    let filePath = FileManager.default.currentDirectoryPath + "/\(sanitizedFilename).yaml"

                    do {
                        try fullPRD.write(toFile: filePath, atomically: true, encoding: .utf8)
                        print("✅ PRD saved to: \(filePath)")
                    } catch {
                        print("❌ Failed to save file: \(error.localizedDescription)")
                    }
                }
            }

        } catch {
            CommandLineInterface.displayError("Failed: \(error)")
        }
    }


    static func printHelp() {
        print("""
        
        Usage: ai-orchestrator [command] [options]
        
        Commands:
          generate-prd      Generate a Product Requirements Document
          interactive       Run in interactive mode (default)
          --help, -h       Show this help message
        
        Privacy Options:
          --allow-external  Allow external API providers (Anthropic, OpenAI, Gemini)
                          By default, only Apple FM, PCC, and local models are used
          --apple-first    Prioritize Apple Intelligence for all operations
        
        Options for generate-prd:
          --feature, -f    Feature description (required)
          --context, -c    Context or problem statement
          --priority, -p   Priority level (critical/high/medium/low)
          --requirement, -r Add a requirement (can be used multiple times)
        
        Environment Variables:
          ALLOW_EXTERNAL_PROVIDERS=true   Enable external providers
          ANTHROPIC_API_KEY               API key for Claude
          OPENAI_API_KEY                  API key for GPT
          GEMINI_API_KEY                  API key for Gemini
        
        Examples:
          # Privacy-first (default)
          ai-orchestrator generate-prd -f "User authentication" -p high
          
          # Allow external providers for complex tasks
          ai-orchestrator --allow-external generate-prd -f "Complex system" -p critical
          
          # Use Apple Intelligence (default) or cloud providers
          ai-orchestrator --allow-external interactive
        
        Provider Priority:
          1. Apple Intelligence Writing Tools (when available)
          2. Apple Foundation Models (on-device)
          3. Private Cloud Compute (privacy-preserved)
          4. External APIs (if allowed and necessary)
        
        """)
    }
}

// MARK: - Metal Configuration

/// Configures Metal environment for Apple Intelligence via MLX.
struct MetalSetup {
    /// Configures Metal environment variables for Apple Intelligence.
    ///
    /// Sets up necessary Metal debugging and performance flags
    /// to ensure optimal Apple Intelligence operation via MLX/Metal.
    static func configure() {
        #if os(macOS)
        // Enable Metal API validation in debug builds
        #if DEBUG
        setenv("METAL_DEVICE_WRAPPER_TYPE", "1", 1)
        #endif
        // Disable Metal API validation in release for performance
        setenv("METAL_DEBUG_ERROR_MODE", "0", 1)
        #endif
    }
}
