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
            case "generate-prd":
                await generatePRD(orchestrator: orchestrator, arguments: Array(arguments.dropFirst(2)))
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
    
    /// Generates a Product Requirements Document from command-line arguments.
    ///
    /// - Parameters:
    ///   - orchestrator: The AI orchestrator instance to use
    ///   - arguments: Command-line arguments containing feature details
    ///
    /// - Note: Supports flags like -f (feature), -c (context), -p (priority)
    private static func generatePRD(orchestrator: Orchestrator, arguments: [String]) async {
        // Parse arguments for PRD generation
        var feature = ""
        var context = ""
        var priority = "medium"
        var requirements: [String] = []
        
        var i = 0
        while i < arguments.count {
            switch arguments[i] {
            case "--feature", "-f":
                if i + 1 < arguments.count {
                    feature = arguments[i + 1]
                    i += 1
                }
            case "--context", "-c":
                if i + 1 < arguments.count {
                    context = arguments[i + 1]
                    i += 1
                }
            case "--priority", "-p":
                if i + 1 < arguments.count {
                    priority = arguments[i + 1]
                    i += 1
                }
            case "--requirement", "-r":
                if i + 1 < arguments.count {
                    requirements.append(arguments[i + 1])
                    i += 1
                }
            default:
                break
            }
            i += 1
        }
        
        if feature.isEmpty {
            print("Error: Feature description is required")
            return
        }
        
        print("\n⚙️ Generating PRD...")
        print("Feature: \(feature)")
        print("Priority: \(priority)")
        print("Context: \(context)")
        print("Requirements: \(requirements.joined(separator: ", "))")
        
        do {
            let (content, provider, quality) = try await orchestrator.generatePRD(
                feature: feature,
                context: context,
                priority: priority,
                requirements: requirements,
                useAppleIntelligence: true,
                useEnhancedGeneration: true
            )
            
            print("\n✅ PRD Generated using \(provider)")
            print("\n📊 Quality Assessment:")
            print(quality.summary)
            print("\n" + String(repeating: "=", count: 60))
            print(content)
            print(String(repeating: "=", count: 60))
            
            // Export options
            print("\n💾 Export Options:")
            print("1. Markdown format saved to: PRD_\(feature.replacingOccurrences(of: " ", with: "_")).md")
            print("2. JIRA format available")
            print("3. JSON format available")
            
        } catch {
            print("\n❌ Error generating PRD: \(error)")
        }
    }
    
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
            case "prd":
                await generatePRDInteractive(orchestrator: orchestrator)
            case "chat":
                await chatMode(orchestrator: orchestrator)
            case "session":
                let newSession = orchestrator.startNewSession()
                CommandLineInterface.displaySuccess("New session started: \(newSession)")
            case "exit":
                print("\n👋 Thank you for using the AI Orchestrator!")
                return
            default:
                // Treat as chat message - delegate to InteractiveMode
                do {
                    print("\n🤔 Processing...")
                    let (response, provider) = try await orchestrator.chat(
                        message: input,
                        useAppleIntelligence: true
                    )
                    print("\n[🤖 \(provider)] \(response)\n")
                } catch {
                    CommandLineInterface.displayError("\(error)")
                }
            }
        }
        
        print("\n👋 Thank you for using the AI Orchestrator!")
    }
    
    /// Interactive PRD generation - delegates to PRDWorkflow
    private static func generatePRDInteractive(orchestrator: Orchestrator) async {
        await PRDWorkflow.runDetailedInteractivePRD(orchestrator: orchestrator)
    }
    
    // Implementation generation moved to ImplementationWorkflow module
    
    /// Handle post-PRD workflow - delegate to appropriate modules
    ///
    /// Allows users to select AI provider, programming language, and testing strategy,
    /// then generates complete implementation including code, tests, and documentation.
    ///
    /// - Parameters:
    ///   - prd: The Product Requirements Document content
    ///   - feature: The feature name for file organization
    ///   - orchestrator: The orchestrator instance for AI operations
    ///   - hybrid: Whether to use hybrid mode (AI assists, user drives)
    private static func generateImplementation(
        prd: String, 
        feature: String, 
        orchestrator: Orchestrator,
        hybrid: Bool = false
    ) async {
        // Delegate to ImplementationWorkflow module
        do {
            try await ImplementationWorkflow.generateImplementation(
                prd: prd,
                feature: feature,
                orchestrator: orchestrator,
                hybrid: hybrid
            )
        } catch {
            CommandLineInterface.displayError("Implementation generation failed: \(error)")
        }
    }
    
    // Chat mode - delegate to InteractiveMode
    static func chatMode(orchestrator: Orchestrator) async {
        await InteractiveMode.runChatSession(orchestrator: orchestrator)
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
