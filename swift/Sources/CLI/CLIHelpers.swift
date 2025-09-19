import Foundation
import Orchestration

/// Helper utilities for command line interface
public enum CLIHelpers {
    
    // MARK: - MetalSetup
    
    public enum MetalSetup {
        public static func configure() {
            // Metal configuration for MLX framework
            setenv("METAL_DEVICE_WRAPPER_TYPE", "1", 1)
            setenv("METAL_DEBUG_ERROR_MODE", "0", 1)
        }
    }
    
    // MARK: - ProviderDisplay
    
    public enum ProviderDisplay {
        public static func displayPrivacyMode(allowExternal: Bool) {
            if allowExternal {
                print("🔓 Privacy Mode: External providers enabled")
            } else {
                print("🔒 Privacy Mode: Apple-only (On-device + Private Cloud Compute)")
            }
        }
        
        public static func displayAvailableProviders(_ providers: [String], allowExternal: Bool) {
            print("\n📋 Available Providers:")
            for provider in providers {
                let emoji = getProviderEmoji(provider)
                print("  \(emoji) \(provider)")
            }
        }
        
        public static func displayPrivacyPolicy() {
            print("\n🔐 Privacy Policy:")
            print("  • Your data stays private by default")
            print("  • On-device processing is prioritized")
            print("  • Private Cloud Compute maintains Apple's privacy standards")
            print("  • External providers are only used with explicit permission\n")
        }
        
        private static func getProviderEmoji(_ provider: String) -> String {
            switch provider.lowercased() {
            case let p where p.contains("apple") || p.contains("foundation"):
                return "🍎"
            case let p where p.contains("anthropic"):
                return "🤖"
            case let p where p.contains("openai"):
                return "🧠"
            case let p where p.contains("gemini"):
                return "💎"
            default:
                return "📦"
            }
        }
    }
    
    // MARK: - HelpCommand
    
    public enum HelpCommand {
        public static func printHelp() {
            CommandLineArgumentParser.printHelp()
        }
    }
    
    // MARK: - CommandLineInterface
    
    public enum CommandLineInterface {
        public static func displayMainMenu() {
            print("""
            
            ╔════════════════════════════════════════╗
            ║     AI Orchestrator - Main Menu       ║
            ╠════════════════════════════════════════╣
            ║  Commands:                             ║
            ║    chat    - Start chat session        ║
            ║    prd     - Generate PRD              ║
            ║    session - New session                ║
            ║    help    - Show help                 ║
            ║    exit    - Exit program              ║
            ╚════════════════════════════════════════╝
            
            """)
        }
        
        public static func displayError(_ message: String) {
            print("❌ Error: \(message)")
        }
        
        public static func displaySuccess(_ message: String) {
            print("✅ \(message)")
        }
        
        public static func displayWarning(_ message: String) {
            print("⚠️ Warning: \(message)")
        }
        
        public static func displayInfo(_ message: String) {
            print("ℹ️ \(message)")
        }
    }
    
    // MARK: - ProgressIndicator
    
    public enum ProgressIndicator {
        public static func showProcessingStatus(_ message: String) {
            print("⏳ \(message)")
        }
        
        public static func withStatusFeedback<T>(
            message: String,
            operation: () async throws -> T
        ) async throws -> T {
            showProcessingStatus(message)
            return try await operation()
        }
    }
    
    // MARK: - InteractiveMode is defined in separate file
    
    // MARK: - Constants Extension
    
    public struct OrchestratorConstantsExtensions {
        public struct App {
            public static let title = """
            ╔════════════════════════════════════════════════════════╗
            ║           🤖 AI Orchestrator v2.0                       ║
            ║      Privacy-First AI Processing on macOS              ║
            ╚════════════════════════════════════════════════════════╝
            """
            public static let separator = String(repeating: "═", count: 58)
            public static let privacyFlow = "🔒 Privacy Flow: On-Device → Private Cloud → External (if allowed)"
            public static let creatingMessage = "🚀 Creating AI Orchestrator..."
            public static let createdMessage = "✅ AI Orchestrator ready!"
            public static let thankYouMessage = "\n👋 Thank you for using AI Orchestrator!"
        }
        
        public struct UI {
            public static let inputPrompt = "\n> "
            public static let unknownCommand = "Unknown command: "
        }
        
        public struct Commands {
            public static let chat = "chat"
            public static let prd = "prd"
            public static let session = "session"
            public static let exit = "exit"
            public static let help = "help"
        }
        
        public struct Processing {
            public static let processingMessage = "Processing your request..."
            public static let aiResponsePrefix = "\n[Provider: "
            public static let aiResponseSuffix = "]\n\n"
        }
        
        public struct Session {
            public static let newSession = "New session started: "
        }
    }
}

// Extensions are accessed directly via CLIHelpers.TypeName