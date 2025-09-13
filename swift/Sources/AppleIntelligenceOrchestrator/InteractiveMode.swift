import Foundation
import AIBridge
import AIProviders

public enum InteractiveMode {
    // Session-scoped settings for the interactive chat mode
    private static var enforcePRD: Bool = false
    private static var currentPersona: PersonaProfile = EnterpriseIT()
    
    /// Runs a simple chat session loop using Orchestrator.chat.
    public static func runChatSession(orchestrator: Orchestrator) async {
        print("""
        💬 Chat Mode (Acronym-aware)
        Type '/help' for commands. Type 'exit' to return to the main menu.
        """)
        
        // Show current domain and glossary summary
        let glossarySummary = await orchestrator.listGlossary().prefix(8).map { "\($0.acronym)=\($0.expansion)" }.joined(separator: ", ")
        print("Domain: product (default). Glossary: \(glossarySummary.isEmpty ? "none" : glossarySummary)")
        print("Options: enforcePRD=\(enforcePRD ? "on" : "off"), persona=\(currentPersona.name)")

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
                      /domain <product|engineering|design|marketing>
                      /glossary add <ACRONYM> <Expansion text...>
                      /glossary list
                      /enforce-prd <on|off>
                      /persona <enterprise|startup>
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
                case "/enforce-prd":
                    if parts.count >= 2 {
                        let val = parts[1].lowercased()
                        if val == "on" {
                            enforcePRD = true
                            print("✅ enforcePRD enabled")
                        } else if val == "off" {
                            enforcePRD = false
                            print("✅ enforcePRD disabled")
                        } else {
                            print("Usage: /enforce-prd on|off")
                        }
                    } else {
                        print("Usage: /enforce-prd on|off")
                    }
                case "/persona":
                    if parts.count >= 2 {
                        let val = parts[1].lowercased()
                        switch val {
                        case "enterprise":
                            currentPersona = EnterpriseIT()
                            print("✅ Persona set to Enterprise IT")
                        case "startup":
                            currentPersona = StartupMVP()
                            print("✅ Persona set to Startup MVP")
                        default:
                            print("Usage: /persona enterprise|startup")
                        }
                    } else {
                        print("Usage: /persona enterprise|startup")
                    }
                default:
                    print("❌ Unknown command. Type /help for commands.")
                }
                
                continue
            }
            
            // Normal chat
            do {
                let options = ChatOptions(
                    injectContext: true,
                    twoPassRefine: true,
                    enforcePRD: enforcePRD,
                    persona: currentPersona
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
}
