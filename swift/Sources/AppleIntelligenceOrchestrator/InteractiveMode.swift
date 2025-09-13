import Foundation
import AIBridge
import AIProviders

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
        let glossarySummary = await orchestrator.listGlossary().prefix(8).map { "\($0.acronym)=\($0.expansion)" }.joined(separator: ", ")
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
                      /prd - Start building a PRD through conversation
                      /domain <product|engineering|design|marketing>
                      /glossary add <ACRONYM> <Expansion text...>
                      /glossary list
                      exit
                    """)
                case "/domain":
                    if parts.count >= 2 {
                        let domainStr = parts[1].lowercased()
                        if let domain = DomainGlossary.Domain(rawValue: domainStr) {
                            await orchestrator.setDomain(domain)
                            print("✅ Domain set to \(domain.rawValue)")
                        } else {
                            print("❌ Unknown domain. Use one of: product, engineering, design, marketing")
                        }
                    } else {
                        print("Usage: /domain product|engineering|design|marketing")
                    }
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
                                    print("  - \(e.acronym): \(e.expansion)")
                                }
                            }
                        } else if sub == "add" {
                            // Expect: /glossary add PRD Product Requirements Document
                            let remainder = input.dropFirst("/glossary add ".count)
                            let comps = remainder.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                            if comps.count == 2 {
                                let acronym = String(comps[0])
                                let expansion = String(comps[1])
                                await orchestrator.addGlossaryEntry(acronym: acronym, expansion: expansion)
                                print("✅ Added \(acronym.uppercased()) = \(expansion)")
                            } else {
                                print("Usage: /glossary add <ACRONYM> <Expansion text...>")
                            }
                        } else {
                            print("Usage: /glossary list | /glossary add <ACRONYM> <Expansion text...>")
                        }
                    } else {
                        print("Usage: /glossary list | /glossary add <ACRONYM> <Expansion text...>")
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
                let (response, provider) = try await orchestrator.chat(
                    message: input,
                    useAppleIntelligence: true,
                    options: options
                )
                print("\n[🤖 \(provider.rawValue)] \(response)\n")
            } catch {
                CommandLineInterface.displayError("\(error)")
            }
        }
    }
    // PRD building moved to main menu as 'spec' command
}
