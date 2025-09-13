import Foundation
import AIBridge

public enum PRDWorkflow {
    /// Runs a detailed interactive PRD flow. For now, this stub just prompts the user
    /// for a few inputs and calls Orchestrator.generatePRD, then prints the result.
    public static func runDetailedInteractivePRD(orchestrator: Orchestrator) async {
        print("🧩 PRD Workflow - Interactive")
        
        func readNonEmpty(prompt: String) -> String {
            while true {
                print(prompt, terminator: "")
                if let line = readLine(), !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return line
                }
                print("Please enter a value.")
            }
        }
        
        let feature = readNonEmpty(prompt: "Feature: ")
        print("Context (optional): ", terminator: "")
        let context = readLine() ?? ""
        print("Priority [critical/high/medium/low] (default: medium): ", terminator: "")
        let priorityRaw = (readLine() ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let priority = priorityRaw.isEmpty ? "medium" : priorityRaw
        
        var requirements: [String] = []
        print("Enter requirements (one per line). Leave empty line to finish.")
        while true {
            print("- ", terminator: "")
            let line = readLine() ?? ""
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { break }
            requirements.append(line)
        }
        
        print("\n⚙️ Generating PRD...")
        do {
            let (content, provider, quality) = try await orchestrator.generatePRD(
                feature: feature,
                context: context,
                priority: priority,
                requirements: requirements,
                useAppleIntelligence: true,
                useEnhancedGeneration: true
            )
            print("\n✅ PRD Generated using \(provider.rawValue)")
            print("\n📊 Quality Assessment:")
            print(quality.summary)
            print("\n" + String(repeating: "=", count: 60))
            print(content)
            print(String(repeating: "=", count: 60))
        } catch {
            CommandLineInterface.displayError("Failed to generate PRD: \(error)")
        }
    }
}
