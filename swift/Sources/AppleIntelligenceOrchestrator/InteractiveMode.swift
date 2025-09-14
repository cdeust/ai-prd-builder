import Foundation
import AIBridge
import AIProviders
import Dispatch

public enum InteractiveMode {
    // Session-scoped settings for the interactive chat mode
    // Removed persona and PRD enforcement - keeping it simple
    
    /// Runs a simple chat session loop using Orchestrator.chat.
    public static func runChatSession(orchestrator: Orchestrator) async {
        print("""
        💬 Chat Mode (Acronym-aware)
        Type '/help' for commands. Type 'exit' to return to the main menu.
        """)
        
        // Show current domain and glossary summary
        let glossarySummary = await orchestrator.listGlossary().prefix(8).map { "\($0.acronym)=\($0.definition)" }.joined(separator: ", ")
        print("Domain: product (default). Glossary: \(glossarySummary.isEmpty ? "none" : glossarySummary)")
        print("Chat mode active")

        while true {
            print("> ", terminator: "")
            guard let input = readLine(), !input.isEmpty else { continue }
            if input.lowercased() == "exit" { break }
            
            // Commands
            if input.hasPrefix("/") {
                let parts = input.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
                let cmd = parts.first?.lowercased() ?? ""
                
                switch cmd {
                case "/help":
                    print("""
                    Commands:
                      /glossary list
                      exit
                    """)
                case "/glossary":
                    if parts.count >= 2 {
                        let sub = parts[1].lowercased()
                        if sub == "list" {
                            let items = await orchestrator.listGlossary()
                            if items.isEmpty {
                                print("ℹ️ Glossary is empty")
                            } else {
                                print("📚 Glossary entries:")
                                for e in items {
                                    print("  - \(e.acronym): \(e.definition)")
                                }
                            }
                        } else if sub == "add" {
                            print("ℹ️ Glossary entries are loaded from configuration file. Edit Glossary.yaml to add entries.")
                        } else {
                            print("Usage: /glossary list")
                        }
                    } else {
                        print("Usage: /glossary list")
                    }
                // Spec building moved to main menu
                default:
                    print("❌ Unknown command. Type /help for commands.")
                }
                
                continue
            }
            
            // Normal chat
            do {
                let options = ChatOptions(
                    injectContext: true,
                    useRefinement: false
                )

                // Show simple status
                AppleIntelligenceOrchestrator.showProcessingStatus("Processing your message...")

                let startTime = Date()
                let (response, provider) = try await orchestrator.chat(
                    message: input,
                    useAppleIntelligence: true,
                    options: options
                )
                let elapsed = Date().timeIntervalSince(startTime)

                if elapsed > 5 {
                    print("   ✓ Completed in \(String(format: "%.1f", elapsed)) seconds")
                }

                print("\n[🤖 \(provider.rawValue)] \(response)\n")
            } catch {
                CommandLineInterface.displayError("\(error)")
            }
        }
    }
    // PRD building moved to main menu as 'spec' command
}
