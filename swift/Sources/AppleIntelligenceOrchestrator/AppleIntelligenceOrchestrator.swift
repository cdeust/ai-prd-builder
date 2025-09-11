import Foundation
import AIBridge
import AIProviders

/// Main entry point for the Swift-based AI orchestrator using MLX
struct AppleIntelligenceOrchestrator {
    
    static func runMain() async {
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
        
        let privacyConfig = AIOrchestrator.PrivacyConfiguration(
            allowExternalProviders: allowExternal,
            requireUserConsent: true,
            logExternalCalls: true
        )
        
        print("Creating AIOrchestrator...")
        let orchestrator = AIOrchestrator(privacyConfig: privacyConfig)
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
            case "download-model":
                await downloadModel(arguments: Array(arguments.dropFirst(2)))
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
    
    static func generatePRD(orchestrator: AIOrchestrator, arguments: [String]) async {
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
            let (content, provider) = try await orchestrator.generatePRD(
                feature: feature,
                context: context,
                priority: priority,
                requirements: requirements,
                useAppleIntelligence: true
            )
            
            print("\n✅ PRD Generated using \(provider)")
            print("\n" + String(repeating: "=", count: 60))
            print(content)
            print(String(repeating: "=", count: 60))
            
        } catch {
            print("\n❌ Error generating PRD: \(error)")
        }
    }
    
    static func runInteractive(orchestrator: AIOrchestrator) async {
        print("\n📋 Interactive AI Assistant with Apple Intelligence")
        print("===================================================")
        print("I'll help you with PRDs, chat, and more")
        print("Commands:")
        print("  'prd' - Generate a Product Requirements Document")
        print("  'chat' - Have a conversation")
        print("  'session' - Start a new session")
        print("  'exit' - Quit the application")
        print("\nType your command or message:\n")
        
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
                print("🆕 New session started: \(newSession)\n")
            default:
                // Treat as chat message
                do {
                    print("\n🤔 Processing...")
                    let (response, provider) = try await orchestrator.chat(
                        message: input,
                        useAppleIntelligence: true
                    )
                    print("\n[🤖 \(provider)] \(response)\n")
                } catch {
                    print("\n❌ Error: \(error)\n")
                }
            }
        }
        
        print("\n👋 Thank you for using the AI Orchestrator!")
    }
    
    static func generatePRDInteractive(orchestrator: AIOrchestrator) async {
        print("\n📋 PRD Generator")
        print("=================")
        
        print("What feature would you like to create a PRD for?")
        guard let feature = readLine(), !feature.isEmpty else {
            return
        }
            
            // Collect requirements
            var userAnswers: [String: String] = [:]
            var requirements: [String] = []
            
            // Challenge for problem statement
            print("\n🎯 Problem Definition")
            print("────────────────────")
            print("What specific problem does '\(feature)' solve?")
            if let problem = readLine(), !problem.isEmpty {
                userAnswers["problem"] = problem
                
                // Follow-up questions
                print("\nHow are users currently solving this problem?")
                if let current = readLine(), !current.isEmpty {
                    userAnswers["current_solution"] = current
                }
            }
            
            // Challenge for users
            print("\n👥 Target Users")
            print("──────────────")
            print("Who are the primary users? (comma-separated)")
            if let users = readLine(), !users.isEmpty {
                userAnswers["users"] = users
            }
            
            // Challenge for success metrics
            print("\n📊 Success Metrics")
            print("─────────────────")
            print("How will you measure success? (Enter metrics, comma-separated)")
            if let metrics = readLine(), !metrics.isEmpty {
                userAnswers["success_metrics"] = metrics
            }
            
            // Challenge for requirements
            print("\n⚙️ Functional Requirements")
            print("────────────────────────")
            print("What are the MUST-HAVE functionalities? (comma-separated)")
            if let reqs = readLine(), !reqs.isEmpty {
                requirements = reqs.split(separator: ",").map { 
                    $0.trimmingCharacters(in: .whitespaces) 
                }
            }
            
            // Challenge for risks
            print("\n⚠️ Risks & Concerns")
            print("──────────────────")
            print("What could go wrong? What are the risks?")
            if let risks = readLine(), !risks.isEmpty {
                userAnswers["risks"] = risks
            }
            
            // Basic validation
            var completeness = 100
            if feature.isEmpty { completeness -= 20 }
            if userAnswers["problem"] == nil { completeness -= 20 }
            if requirements.isEmpty { completeness -= 20 }
            if userAnswers["success_metrics"] == nil { completeness -= 10 }
            if userAnswers["users"] == nil { completeness -= 10 }
            
            print("\n📈 PRD Input Completeness: \(completeness)%")
            
            if completeness < 100 {
                print("\n💡 Consider providing more details for a comprehensive PRD")
                print("\nWould you like to:")
                print("1. Continue anyway")
                print("2. Answer more questions")
                print("3. Start over")
                
                let choice = readLine() ?? "1"
                
                if choice == "2" {
                    // Ask additional questions
                    print("\nProvide additional details (press Enter to skip):")
                    
                    print("What are the expected timelines?")
                    if let timeline = readLine(), !timeline.isEmpty {
                        userAnswers["timeline"] = timeline
                    }
                    
                    print("What are the key dependencies?")
                    if let deps = readLine(), !deps.isEmpty {
                        userAnswers["dependencies"] = deps
                    }
                    
                    print("What is the acceptance criteria?")
                    if let acceptance = readLine(), !acceptance.isEmpty {
                        userAnswers["acceptance_criteria"] = acceptance
                    }
                } else if choice == "3" {
                    return  // Start over by returning from the function
                }
            }
            
            print("\n⚙️ Generating comprehensive PRD...")
            
            do {
                let (content, provider) = try await orchestrator.generatePRD(
                    feature: feature,
                    context: userAnswers["problem"] ?? "",
                    priority: "medium",
                    requirements: requirements,
                    skipValidation: true, // We already validated
                    useAppleIntelligence: true
                )
                
                print("\n✅ PRD Generated using \(provider)")
                print("\n" + String(repeating: "=", count: 60))
                print(content)
                print(String(repeating: "=", count: 60))
                
                // Offer to save
                print("\nWould you like to save this PRD? (yes/no)")
                if let save = readLine(), save.lowercased() == "yes" {
                    let fileName = "PRD_\(feature.replacingOccurrences(of: " ", with: "_"))_\(Date().timeIntervalSince1970).md"
                    let url = FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent("Documents")
                        .appendingPathComponent(fileName)
                    
                    try content.write(to: url, atomically: true, encoding: String.Encoding.utf8)
                    print("✅ PRD saved to: \(url.path)")
                }
                
            } catch {
                print("\n❌ Error generating PRD: \(error)")
            }
            
    }
    
    static func chatMode(orchestrator: AIOrchestrator) async {
        print("\n💬 Chat Mode")
        print("============")
        print("Type 'back' to return to main menu\n")
        
        while true {
            print("You: ", terminator: "")
            guard let message = readLine(), !message.isEmpty else {
                continue
            }
            
            if message.lowercased() == "back" {
                break
            }
            
            do {
                let (response, provider) = try await orchestrator.chat(
                    message: message,
                    useAppleIntelligence: true
                )
                print("\nAI (\(provider)): \(response)\n")
            } catch {
                print("\n❌ Error: \(error)\n")
            }
        }
    }
    
    static func downloadModel(arguments: [String]) async {
        print("\n📥 Model Download Helper")
        print("========================")
        
        if arguments.isEmpty {
            print("\nAvailable MLX models from Hugging Face:")
            print("  • mlx-community/Qwen2.5-3B-Instruct-4bit")
            print("  • mlx-community/Qwen2.5-7B-Instruct-4bit")
            print("  • mlx-community/Llama-3.2-3B-Instruct-4bit")
            print("  • mlx-community/deepseek-r1-distill-llama-8b-4bit")
            print("\nUsage: ai-orchestrator download-model <model-name>")
            return
        }
        
        let modelName = arguments[0]
        print("Downloading \(modelName)...")
        
        // Run huggingface-cli download command
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["huggingface-cli", "download", modelName, "--local-dir", "~/models/\(modelName.split(separator: "/").last ?? "model")"]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                print("✅ Model downloaded successfully!")
            } else {
                print("❌ Download failed. Make sure huggingface-cli is installed:")
                print("   pip install huggingface-hub")
            }
        } catch {
            print("❌ Error: \(error)")
        }
    }
    
    static func printHelp() {
        print("""
        
        Usage: ai-orchestrator [command] [options]
        
        Commands:
          generate-prd      Generate a Product Requirements Document
          interactive       Run in interactive mode (default)
          download-model    Download MLX models from Hugging Face
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
          
          # Download local models
          ai-orchestrator download-model mlx-community/Qwen2.5-3B-Instruct-4bit
        
        Provider Priority:
          1. Apple Intelligence Writing Tools (when available)
          2. Apple Foundation Models (on-device)
          3. Private Cloud Compute (privacy-preserved)
          4. External APIs (if allowed and necessary)
        
        """)
    }
}
