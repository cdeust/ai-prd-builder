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
                return OrchestratorConstants.ThinkingModeDescriptions.automatic
            case .chainOfThought:
                return OrchestratorConstants.ThinkingModeDescriptions.chainOfThought
            case .parallelExploration:
                return OrchestratorConstants.ThinkingModeDescriptions.parallelExploration
            case .divergentThinking:
                return OrchestratorConstants.ThinkingModeDescriptions.divergentThinking
            case .convergentThinking:
                return OrchestratorConstants.ThinkingModeDescriptions.convergentThinking
            case .criticalAnalysis:
                return OrchestratorConstants.ThinkingModeDescriptions.criticalAnalysis
            case .analogicalReasoning:
                return OrchestratorConstants.ThinkingModeDescriptions.analogicalReasoning
            case .reverseEngineering:
                return OrchestratorConstants.ThinkingModeDescriptions.reverseEngineering
            case .socraticMethod:
                return OrchestratorConstants.ThinkingModeDescriptions.socraticMethod
            case .firstPrinciples:
                return OrchestratorConstants.ThinkingModeDescriptions.firstPrinciples
            case .systemsThinking:
                return OrchestratorConstants.ThinkingModeDescriptions.systemsThinking
            }
        }

        public var emoji: String {
            switch self {
            case .automatic: return OrchestratorConstants.ThinkingModeEmojis.automatic
            case .chainOfThought: return OrchestratorConstants.ThinkingModeEmojis.chainOfThought
            case .parallelExploration: return OrchestratorConstants.ThinkingModeEmojis.parallelExploration
            case .divergentThinking: return OrchestratorConstants.ThinkingModeEmojis.divergentThinking
            case .convergentThinking: return OrchestratorConstants.ThinkingModeEmojis.convergentThinking
            case .criticalAnalysis: return OrchestratorConstants.ThinkingModeEmojis.criticalAnalysis
            case .analogicalReasoning: return OrchestratorConstants.ThinkingModeEmojis.analogicalReasoning
            case .reverseEngineering: return OrchestratorConstants.ThinkingModeEmojis.reverseEngineering
            case .socraticMethod: return OrchestratorConstants.ThinkingModeEmojis.socraticMethod
            case .firstPrinciples: return OrchestratorConstants.ThinkingModeEmojis.firstPrinciples
            case .systemsThinking: return OrchestratorConstants.ThinkingModeEmojis.systemsThinking
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
                reasoning += OrchestratorConstants.Formatting.newline
            }
            reasoning += text
        }

        public var summary: String {
            var parts: [String] = []

            if !struggles.isEmpty {
                parts.append(String(format: OrchestratorConstants.ThinkingModeAnalysis.strugglesLabel, struggles.count))
            }
            if !uncertainties.isEmpty {
                parts.append(String(format: OrchestratorConstants.ThinkingModeAnalysis.uncertaintiesLabel, uncertainties.count))
            }
            if !assumptions.isEmpty {
                parts.append(String(format: OrchestratorConstants.ThinkingModeAnalysis.assumptionsLabel, assumptions.count))
            }
            if !breakthroughs.isEmpty {
                parts.append(String(format: OrchestratorConstants.ThinkingModeAnalysis.breakthroughsLabel, breakthroughs.count))
            }

            return parts.isEmpty ? OrchestratorConstants.ThinkingModeAnalysis.noThoughtProcess : parts.joined(separator: OrchestratorConstants.Formatting.comma)
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
        let hasQuestion = message.contains(OrchestratorConstants.Formatting.questionMark)
        let hasComparison = containsComparisonWords(message)
        let hasCreativeRequest = containsCreativeWords(message)
        let hasTechnicalTerms = containsTechnicalTerms(message)
        let hasMultipleParts = message.contains(OrchestratorConstants.Formatting.and) || message.contains(OrchestratorConstants.Formatting.comma)

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
        let comparisonWords = OrchestratorConstants.ThinkingModeAnalysis.comparisonWords
        let lowercased = text.lowercased()
        return comparisonWords.contains { lowercased.contains($0) }
    }

    private func containsCreativeWords(_ text: String) -> Bool {
        let creativeWords = OrchestratorConstants.ThinkingModeAnalysis.creativeWords
        let lowercased = text.lowercased()
        return creativeWords.contains { lowercased.contains($0) }
    }

    private func containsTechnicalTerms(_ text: String) -> Bool {
        let technicalTerms = OrchestratorConstants.ThinkingModeAnalysis.technicalTerms
        let lowercased = text.lowercased()
        return technicalTerms.contains { lowercased.contains($0) }
    }

    // MARK: - Display Methods

    /// Displays the current thinking mode if not standard
    public func displayCurrentMode() {
        if currentThinkingMode != .chainOfThought && currentThinkingMode != .automatic {
            print("\(OrchestratorConstants.SystemMessages.thinkingModePrefix)\(currentThinkingMode.rawValue)")
        }
    }

    /// Gets a formatted summary of the thought process
    public func getFormattedSummary() -> String {
        return ThinkingModeHelper.formatThoughtProcess(thoughtProcess)
    }
}

// MARK: - Supporting Types

private struct MessageAnalysis {
    let wordCount: Int
    let hasQuestion: Bool
    let hasComparison: Bool
    let hasCreativeRequest: Bool
    let hasTechnicalTerms: Bool
    let hasMultipleParts: Bool
}