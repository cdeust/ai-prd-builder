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
            case "spec":
                await buildSpecConversationally(orchestrator: orchestrator)
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
    
    // Build requirements spec through conversation
    static func buildSpecConversationally(orchestrator: Orchestrator) async {
        print("\n📝 Conversational Spec Builder")
        print("=================================")
        print("I'll help you build a detailed requirements specification through conversation.")
        print("Just describe what you want to build, and I'll ask clarifying questions.\n")
        print("What would you like to build? (describe your feature/requirement):")
        print("> ", terminator: "")
        
        guard let initialRequest = readLine(), !initialRequest.isEmpty else {
            print("No input provided")
            return
        }
        
        do {
            // Start the conversation
            var context = try await ConversationalPRD.startConversation(
                initialRequest: initialRequest,
                orchestrator: orchestrator
            )
            
            print("\n💡 Understanding:\n\(context)\n")
            
            // Conversation loop
            while true {
                print("\n💬 Please provide more details (or type 'done' when complete):")
                print("> ", terminator: "")
                
                guard let userInput = readLine() else { break }
                
                if userInput.lowercased() == "done" {
                    print("\n✅ Specification Complete!")
                    break
                }
                
                // Continue building spec
                let response = try await ConversationalPRD.continueConversation(
                    originalRequest: initialRequest,
                    previousContext: context,
                    userResponse: userInput,
                    orchestrator: orchestrator
                )
                
                print("\n📋 Updated Spec:\n\(response)\n")
                context = response
                
                // Check if spec is complete
                if response.contains("\"title\"") && response.contains("\"requirements\"") {
                    print("\n✨ Your specification looks complete! Options:")
                    print("1. Type 'github' to format for GitHub issue")
                    print("2. Type 'jira' to format for JIRA ticket")
                    print("3. Type 'done' to finish")
                    print("4. Or continue adding more details")
                    
                    print("> ", terminator: "")
                    if let format = readLine()?.lowercased() {
                        switch format {
                        case "github":
                            print("\n" + ConversationalPRD.formatForGitHub(prd: response))
                        case "jira":
                            print("\n" + ConversationalPRD.formatForJira(prd: response))
                        case "done":
                            break
                        default:
                            continue
                        }
                    }
                }
            }
            
        } catch {
            CommandLineInterface.displayError("Spec building failed: \(error)")
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
