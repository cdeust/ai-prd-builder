import Foundation

public enum CommandLineInterface {
    
    public static func displayMainMenu() {
        print("""
        =================================
        🧭 AI Orchestrator - Interactive Mode
        =================================
        Commands:
          chat       Chat with the AI assistant
          spec       Build requirements spec through conversation
          session    Start a new session
          exit       Quit
        
        Tips:
          - This tool prioritizes privacy: Apple Foundation Models → PCC → External (if allowed)
          - Use '--allow-external' to enable external providers
          - Type any message to chat directly
        """)
    }
    
    public static func displaySuccess(_ message: String) {
        print("✅ \(message)")
    }
    
    public static func displayError(_ message: String) {
        // Print to stderr to distinguish errors in scripts/pipes
        let err = "❌ \(message)\n"
        FileHandle.standardError.write(err.data(using: .utf8) ?? Data())
    }
}
