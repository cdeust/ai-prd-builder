import Foundation

/// Helper utilities for working with thinking modes
public enum ThinkingModeHelper {

    /// Parse thinking mode from user input
    public static func parseThinkingMode(_ input: String) -> Orchestrator.ThinkingMode? {
        let lowercased = input.lowercased()

        if lowercased.contains("chain") { return .chainOfThought }
        if lowercased.contains("parallel") { return .parallelExploration }
        if lowercased.contains("divergent") || lowercased.contains("creative") { return .divergentThinking }
        if lowercased.contains("convergent") || lowercased.contains("narrow") { return .convergentThinking }
        if lowercased.contains("critical") || lowercased.contains("analyze") { return .criticalAnalysis }
        if lowercased.contains("analog") || lowercased.contains("similar") { return .analogicalReasoning }
        if lowercased.contains("reverse") || lowercased.contains("backward") { return .reverseEngineering }
        if lowercased.contains("socratic") || lowercased.contains("question") { return .socraticMethod }
        if lowercased.contains("first") || lowercased.contains("principle") { return .firstPrinciples }
        if lowercased.contains("system") || lowercased.contains("holistic") { return .systemsThinking }
        if lowercased.contains("auto") { return .automatic }

        return nil
    }

    /// Describe what a thinking mode does
    public static func describeThinkingMode(_ mode: Orchestrator.ThinkingMode) -> String {
        switch mode {
        case .chainOfThought:
            return "📝 Sequential step-by-step reasoning through the problem"
        case .parallelExploration:
            return "🔀 Explores multiple solution paths simultaneously"
        case .divergentThinking:
            return "💡 Creative, unconventional approaches and wild ideas"
        case .convergentThinking:
            return "🎯 Narrows down options to find the best solution"
        case .criticalAnalysis:
            return "🔍 Finds flaws, risks, and hidden issues"
        case .analogicalReasoning:
            return "🔗 Uses patterns and similarities from other domains"
        case .reverseEngineering:
            return "⏪ Works backwards from the desired outcome"
        case .socraticMethod:
            return "❓ Solves through systematic questioning"
        case .firstPrinciples:
            return "🏗️ Breaks down to fundamental truths and rebuilds"
        case .systemsThinking:
            return "🌐 Considers the whole system and interactions"
        case .automatic:
            return "🤖 AI selects the best thinking mode for each query"
        }
    }

    /// Get a short alias for a thinking mode (for CLI usage)
    public static func getShortAlias(_ mode: Orchestrator.ThinkingMode) -> String {
        switch mode {
        case .chainOfThought: return "chain"
        case .parallelExploration: return "parallel"
        case .divergentThinking: return "divergent"
        case .convergentThinking: return "convergent"
        case .criticalAnalysis: return "critical"
        case .analogicalReasoning: return "analogy"
        case .reverseEngineering: return "reverse"
        case .socraticMethod: return "socratic"
        case .firstPrinciples: return "first"
        case .systemsThinking: return "systems"
        case .automatic: return "auto"
        }
    }

    /// Get detailed explanation of when to use each mode
    public static func getUsageGuide(_ mode: Orchestrator.ThinkingMode) -> String {
        switch mode {
        case .chainOfThought:
            return """
            Use for: Step-by-step problem solving, debugging, explaining processes
            Best when: You need clear logical progression
            Example: "Explain how authentication works"
            """

        case .parallelExploration:
            return """
            Use for: Comparing options, evaluating trade-offs
            Best when: Multiple valid approaches exist
            Example: "Compare microservices vs monolith"
            """

        case .divergentThinking:
            return """
            Use for: Brainstorming, creative solutions, innovation
            Best when: Conventional approaches aren't working
            Example: "Creative ways to improve user engagement"
            """

        case .convergentThinking:
            return """
            Use for: Decision making, selecting best option
            Best when: You have many options and need to choose
            Example: "Which database is best for our needs?"
            """

        case .criticalAnalysis:
            return """
            Use for: Finding problems, security review, risk assessment
            Best when: You need to identify weaknesses
            Example: "What could go wrong with this design?"
            """

        case .analogicalReasoning:
            return """
            Use for: Learning from similar problems, pattern recognition
            Best when: Similar problems have been solved before
            Example: "How do other systems handle this?"
            """

        case .reverseEngineering:
            return """
            Use for: Goal-oriented design, working from requirements
            Best when: You know the end goal clearly
            Example: "Design a system that never loses data"
            """

        case .socraticMethod:
            return """
            Use for: Deep understanding, uncovering assumptions
            Best when: You need to question fundamentals
            Example: "Why do we need this feature?"
            """

        case .firstPrinciples:
            return """
            Use for: Fundamental redesign, removing complexity
            Best when: Current solution is too complex
            Example: "Simplify this architecture"
            """

        case .systemsThinking:
            return """
            Use for: Understanding interactions, holistic view
            Best when: Changes affect multiple components
            Example: "How will caching impact the system?"
            """

        case .automatic:
            return """
            Use for: General queries, let AI decide
            Best when: You're not sure which mode fits
            Example: Any general question
            """
        }
    }

    /// Format thinking process for display
    public static func formatThoughtProcess(_ process: Orchestrator.ThoughtProcess) -> String {
        var output = """
        ╔════════════════════════════════════════╗
        ║         💭 THINKING PROCESS            ║
        ╚════════════════════════════════════════╝

        Mode: \(process.mode.rawValue)

        """

        if !process.struggles.isEmpty {
            output += "🔴 Struggles (\(process.struggles.count)):\n"
            for (index, struggle) in process.struggles.enumerated() {
                output += "   \(index + 1). \(struggle)\n"
            }
            output += "\n"
        }

        if !process.uncertainties.isEmpty {
            output += "🟡 Uncertainties (\(process.uncertainties.count)):\n"
            for (index, uncertainty) in process.uncertainties.enumerated() {
                output += "   \(index + 1). \(uncertainty)\n"
            }
            output += "\n"
        }

        if !process.assumptions.isEmpty {
            output += "🔵 Assumptions (\(process.assumptions.count)):\n"
            for (index, assumption) in process.assumptions.enumerated() {
                output += "   \(index + 1). \(assumption)\n"
            }
            output += "\n"
        }

        if !process.breakthroughs.isEmpty {
            output += "🟢 Breakthroughs (\(process.breakthroughs.count)):\n"
            for (index, breakthrough) in process.breakthroughs.enumerated() {
                output += "   \(index + 1). ✨ \(breakthrough)\n"
            }
            output += "\n"
        }

        if !process.reasoning.isEmpty {
            output += "📝 Reasoning:\n\(process.reasoning)\n"
        }

        return output
    }
}
