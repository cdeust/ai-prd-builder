import Foundation

/// Manages thinking modes and thought processes for transparent AI reasoning
public class ThinkingModeManager {

    // MARK: - Properties

    private var currentThinkingMode: ThinkingMode = .chainOfThought
    private var thoughtProcess: ThoughtProcess = ThoughtProcess()

    // MARK: - Thinking Mode Enum

    public enum ThinkingMode: String, CaseIterable {
        case automatic = "automatic"
        case chainOfThought = "chain-of-thought"
        case parallelExploration = "parallel-exploration"
        case divergentThinking = "divergent-thinking"
        case convergentThinking = "convergent-thinking"
        case criticalAnalysis = "critical-analysis"
        case analogicalReasoning = "analogical-reasoning"
        case reverseEngineering = "reverse-engineering"
        case socraticMethod = "socratic-method"
        case firstPrinciples = "first-principles"
        case systemsThinking = "systems-thinking"

        public var description: String {
            switch self {
            case .automatic:
                return "Automatic mode selection based on context"
            case .chainOfThought:
                return "Breaking down problems step-by-step"
            case .parallelExploration:
                return "Exploring multiple solution paths simultaneously"
            case .divergentThinking:
                return "Generating creative alternatives and possibilities"
            case .convergentThinking:
                return "Narrowing down to the best solution"
            case .criticalAnalysis:
                return "Evaluating ideas critically for weaknesses"
            case .analogicalReasoning:
                return "Drawing parallels from similar problems"
            case .reverseEngineering:
                return "Working backward from desired outcomes"
            case .socraticMethod:
                return "Using questions to uncover deeper truths"
            case .firstPrinciples:
                return "Breaking down to fundamental truths"
            case .systemsThinking:
                return "Understanding interconnected relationships"
            }
        }

        public var emoji: String {
            switch self {
            case .automatic: return "🤖"
            case .chainOfThought: return "🔗"
            case .parallelExploration: return "🔀"
            case .divergentThinking: return "💡"
            case .convergentThinking: return "🎯"
            case .criticalAnalysis: return "🔍"
            case .analogicalReasoning: return "🔄"
            case .reverseEngineering: return "⏪"
            case .socraticMethod: return "❓"
            case .firstPrinciples: return "🏗️"
            case .systemsThinking: return "🌐"
            }
        }
    }

    // MARK: - Thought Process Structure

    public struct ThoughtProcess {
        public var mode: ThinkingMode = .automatic
        public var struggles: [String] = []
        public var uncertainties: [String] = []
        public var assumptions: [String] = []
        public var breakthroughs: [String] = []
        public var reasoning: String = ""

        public init() {}

        public mutating func reset() {
            struggles.removeAll()
            uncertainties.removeAll()
            assumptions.removeAll()
            breakthroughs.removeAll()
            reasoning = ""
        }

        public mutating func addStruggle(_ struggle: String) {
            struggles.append(struggle)
        }

        public mutating func addUncertainty(_ uncertainty: String) {
            uncertainties.append(uncertainty)
        }

        public mutating func addAssumption(_ assumption: String) {
            assumptions.append(assumption)
        }

        public mutating func addBreakthrough(_ breakthrough: String) {
            breakthroughs.append(breakthrough)
        }

        public mutating func appendReasoning(_ text: String) {
            if !reasoning.isEmpty {
                reasoning += "\n"
            }
            reasoning += text
        }

        public func getSummary() -> String {
            var parts: [String] = []
            if !struggles.isEmpty {
                parts.append("Struggles: \(struggles.count)")
            }
            if !uncertainties.isEmpty {
                parts.append("Uncertainties: \(uncertainties.count)")
            }
            if !assumptions.isEmpty {
                parts.append("Assumptions: \(assumptions.count)")
            }
            if !breakthroughs.isEmpty {
                parts.append("Breakthroughs: \(breakthroughs.count)")
            }
            return parts.isEmpty ? "No thought process" : parts.joined(separator: ", ")
        }

        public var summary: String {
            var parts: [String] = []

            if !struggles.isEmpty {
                parts.append("Struggles: \(struggles.count)")
            }
            if !uncertainties.isEmpty {
                parts.append("Uncertainties: \(uncertainties.count)")
            }
            if !assumptions.isEmpty {
                parts.append("Assumptions: \(assumptions.count)")
            }
            if !breakthroughs.isEmpty {
                parts.append("Breakthroughs: \(breakthroughs.count)")
            }

            return parts.isEmpty ? "No thought process" : parts.joined(separator: ", ")
        }
    }

    // MARK: - Initialization

    public init() {}

    // MARK: - Mode Management

    /// Gets the current thinking mode
    public var currentMode: ThinkingMode {
        return currentThinkingMode
    }

    /// Sets the thinking mode
    public func setThinkingMode(_ mode: ThinkingMode) {
        currentThinkingMode = mode
        thoughtProcess.mode = mode
    }

    /// Resets the thought process
    public func resetThoughtProcess() {
        thoughtProcess.reset()
    }

    /// Gets the current thought process
    public func getThoughtProcess() -> ThoughtProcess {
        return thoughtProcess
    }

    // MARK: - Mode Selection

    /// Selects the best thinking mode for a given message
    public func selectBestMode(for message: String) async throws -> ThinkingMode {
        // Analyze message characteristics
        let analysis = analyzeMessage(message)

        // Select mode based on analysis
        return selectModeFromAnalysis(analysis)
    }

    // MARK: - Thought Process Management

    /// Records a struggle in the thought process
    public func recordStruggle(_ struggle: String) {
        thoughtProcess.addStruggle(struggle)
    }

    /// Records an uncertainty
    public func recordUncertainty(_ uncertainty: String) {
        thoughtProcess.addUncertainty(uncertainty)
    }

    /// Records an assumption
    public func recordAssumption(_ assumption: String) {
        thoughtProcess.addAssumption(assumption)
    }

    /// Records a breakthrough
    public func recordBreakthrough(_ breakthrough: String) {
        thoughtProcess.addBreakthrough(breakthrough)
    }

    /// Appends to reasoning
    public func appendReasoning(_ reasoning: String) {
        thoughtProcess.appendReasoning(reasoning)
    }

    // MARK: - Analysis Methods

    private func analyzeMessage(_ message: String) -> MessageAnalysis {
        let wordCount = message.split(separator: " ").count
        let hasQuestion = message.contains("?")
        let hasComparison = containsComparisonWords(message)
        let hasCreativeRequest = containsCreativeWords(message)
        let hasTechnicalTerms = containsTechnicalTerms(message)
        let hasMultipleParts = message.contains(" and ") || message.contains(",")

        return MessageAnalysis(
            wordCount: wordCount,
            hasQuestion: hasQuestion,
            hasComparison: hasComparison,
            hasCreativeRequest: hasCreativeRequest,
            hasTechnicalTerms: hasTechnicalTerms,
            hasMultipleParts: hasMultipleParts
        )
    }

    private func selectModeFromAnalysis(_ analysis: MessageAnalysis) -> ThinkingMode {
        // Creative requests
        if analysis.hasCreativeRequest {
            return .divergentThinking
        }

        // Comparison or pattern matching
        if analysis.hasComparison {
            return .analogicalReasoning
        }

        // Multiple parts suggest parallel exploration
        if analysis.hasMultipleParts && analysis.wordCount > 50 {
            return .parallelExploration
        }

        // Questions suggest Socratic method
        if analysis.hasQuestion && analysis.wordCount < 30 {
            return .socraticMethod
        }

        // Technical terms suggest systematic analysis
        if analysis.hasTechnicalTerms {
            return .systemsThinking
        }

        // Default to chain of thought
        return .chainOfThought
    }

    private func containsComparisonWords(_ text: String) -> Bool {
        let comparisonWords = ["compare", "contrast", "difference", "similarity", "versus", "vs", "better", "worse"]
        let lowercased = text.lowercased()
        return comparisonWords.contains { lowercased.contains($0) }
    }

    private func containsCreativeWords(_ text: String) -> Bool {
        let creativeWords = ["create", "design", "imagine", "innovate", "invent", "brainstorm", "generate", "develop"]
        let lowercased = text.lowercased()
        return creativeWords.contains { lowercased.contains($0) }
    }

    private func containsTechnicalTerms(_ text: String) -> Bool {
        let technicalTerms = ["algorithm", "api", "database", "framework", "architecture", "implementation", "optimize", "refactor"]
        let lowercased = text.lowercased()
        return technicalTerms.contains { lowercased.contains($0) }
    }

    // MARK: - Display Methods

    /// Displays the current thinking mode if not standard
    public func displayCurrentMode() {
        if currentThinkingMode != .chainOfThought && currentThinkingMode != .automatic {
            print("🤔 Thinking Mode: \(currentThinkingMode.rawValue)")
        }
    }

    /// Gets a formatted summary of the thought process
    public func getFormattedSummary() -> String {
        return thoughtProcess.getSummary()
    }
}

// MARK: - Supporting Types


