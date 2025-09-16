import Foundation
import AIBridge

/// Chain of Thought framework for structured reasoning with Apple Intelligence
/// Makes AI thinking transparent and helps avoid incorrect patterns
public class ChainOfThought {

    private let orchestrator: Orchestrator
    private var thoughtHistory: [ThoughtChain] = []
    private var assumptions: [Assumption] = []
    private var patterns: [DetectedPattern] = []

    public init(orchestrator: Orchestrator) {
        self.orchestrator = orchestrator
    }

    /// Think through a problem step by step using 2025 best practices
    public func thinkThrough(
        problem: String,
        context: String? = nil,
        constraints: [String] = [],
        useSelfConsistency: Bool = false,
        numPaths: Int = 3
    ) async throws -> ThoughtChain {

        print(ChainOfThoughtConstants.reasoningProcessStart)
        print("\(ChainOfThoughtConstants.problemPrefix)\(problem)")

        // Use self-consistency for better results (2025 best practice)
        if useSelfConsistency && numPaths > 1 {
            return try await thinkWithSelfConsistency(
                problem: problem,
                context: context,
                constraints: constraints,
                numPaths: numPaths
            )
        }

        // Single path reasoning with structured approach
        var thoughts: [Thought] = []

        // Use zero-shot CoT with "Let's think step by step" (2025 research shows this is most effective)
        let structuredPrompt = buildStructuredPrompt(
            problem: problem,
            context: context,
            constraints: constraints
        )

        // Generate comprehensive reasoning in one structured pass (avoiding over-engineering)
        let reasoningResponse = try await generateStructuredReasoning(
            prompt: structuredPrompt
        )

        // Parse the structured response into thought components
        thoughts = parseStructuredResponse(reasoningResponse)

        // Extract assumptions from reasoning
        let extractedAssumptions = await extractAssumptionsFromThoughts(thoughts)
        assumptions.append(contentsOf: extractedAssumptions)

        // Extract conclusion with higher confidence calculation
        let conclusion = extractConclusionFromThoughts(thoughts)
        let confidence = calculateEnhancedConfidence(thoughts: thoughts, assumptions: extractedAssumptions)

        // Create thought chain
        let chain = ThoughtChain(
            id: UUID(),
            problem: problem,
            thoughts: thoughts,
            conclusion: conclusion,  // conclusion is already a String
            confidence: confidence,    // use the calculated enhanced confidence
            alternatives: [],  // Simplified for now
            assumptions: extractedAssumptions,
            timestamp: Date()
        )

        thoughtHistory.append(chain)

        print(ChainOfThoughtConstants.reasoningComplete)
        print("\(ChainOfThoughtConstants.conclusionPrefix)\(chain.conclusion)")
        print("\(ChainOfThoughtConstants.confidencePrefix)\(chain.confidence)")

        return chain
    }

    /// Generate structured reasoning using 2025 best practices
    private func generateStructuredReasoning(
        prompt: String
    ) async throws -> String {
        // Don't over-instruct the model (2025 finding)
        // Let it naturally generate reasoning without explicit "think step by step" instructions
        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: .chainOfThought
            // Note: temperature parameter not available in current orchestrator
        )

        return response
    }

    /// Build structured prompt following 2025 best practices
    private func buildStructuredPrompt(
        problem: String,
        context: String?,
        constraints: [String]
    ) -> String {
        // Start simple with zero-shot approach (2025 best practice)
        var prompt = problem

        // Add context if available
        if let context = context, !context.isEmpty {
            prompt = "Context: \(context)\n\nProblem: \(prompt)"
        }

        // Add constraints in structured format
        if !constraints.isEmpty {
            prompt += "\n\nConsiderations:\n"
            for constraint in constraints {
                prompt += "• \(constraint)\n"
            }
        }

        // Simple trigger for reasoning (research shows this is most effective)
        prompt += "\n\nLet's think step by step."

        return prompt
    }

    /// Parse structured response into thoughts
    private func parseStructuredResponse(_ response: String) -> [Thought] {
        var thoughts: [Thought] = []
        let sections = response.components(separatedBy: "\n\n")

        for (index, section) in sections.enumerated() {
            let type = determineThoughtType(from: section, index: index)
            let confidence = extractSectionConfidence(from: section)

            thoughts.append(Thought(
                id: UUID(),
                content: section,
                type: type,
                confidence: confidence,
                timestamp: Date(),
                parent: index > 0 ? thoughts[index - 1].id : nil,
                children: []
            ))
        }

        return thoughts
    }

    /// Determine thought type from content
    private func determineThoughtType(from content: String, index: Int) -> Thought.ThoughtType {
        let lowercased = content.lowercased()

        if lowercased.contains("observ") || index == 0 {
            return .observation
        } else if lowercased.contains("question") || lowercased.contains("?") {
            return .question
        } else if lowercased.contains("assum") {
            return .assumption
        } else if lowercased.contains("alternative") || lowercased.contains("another") {
            return .alternative
        } else if lowercased.contains("risk") || lowercased.contains("warning") || lowercased.contains("concern") {
            return .warning
        } else if lowercased.contains("conclusion") || lowercased.contains("therefore") || lowercased.contains("final") {
            return .conclusion
        } else {
            return .reasoning
        }
    }

    /// Extract confidence from section content
    private func extractSectionConfidence(from content: String) -> Float {
        // Look for confidence indicators
        let highConfidenceTerms = ["certain", "clear", "definite", "obvious", "confirmed"]
        let mediumConfidenceTerms = ["likely", "probable", "suggests", "indicates"]
        let lowConfidenceTerms = ["uncertain", "unclear", "possible", "might", "could"]

        let lowercased = content.lowercased()

        if highConfidenceTerms.contains(where: lowercased.contains) {
            return 0.85
        } else if lowConfidenceTerms.contains(where: lowercased.contains) {
            return 0.4
        } else if mediumConfidenceTerms.contains(where: lowercased.contains) {
            return 0.65
        }

        return ChainOfThoughtConstants.defaultConfidence
    }

    private func buildThoughtPrompt(type: Thought.ThoughtType, prompt: String, context: String?) -> String {
        var fullPrompt = ChainOfThoughtConstants.thoughtTypePrefix

        switch type {
        case .observation:
            fullPrompt += ChainOfThoughtConstants.observationPrompt
        case .assumption:
            fullPrompt += ChainOfThoughtConstants.assumptionPrompt
        case .reasoning:
            fullPrompt += ChainOfThoughtConstants.reasoningPrompt
        case .question:
            fullPrompt += ChainOfThoughtConstants.questionPrompt
        case .conclusion:
            fullPrompt += ChainOfThoughtConstants.conclusionPrompt
        case .warning:
            fullPrompt += ChainOfThoughtConstants.warningPrompt
        case .alternative:
            fullPrompt += ChainOfThoughtConstants.alternativePrompt
        }

        fullPrompt += "\n\n\(prompt)"

        if let context = context {
            fullPrompt += "\n\nContext: \(context)"
        }

        return fullPrompt
    }

    /// Extract assumptions from text
    private func extractAssumptions(from text: String) async -> [Assumption] {
        let prompt = String(format: ChainOfThoughtConstants.extractAssumptionsTemplate, text)

        do {
            let (response, _) = try await orchestrator.chat(
                message: prompt,
                useAppleIntelligence: true,
                thinkingMode: .chainOfThought
            )

            // Parse response and create assumptions
            return ChainOfThoughtParser.parseAssumptions(from: response, context: text)
        } catch {
            print("Failed to extract assumptions: \(error)")
            return []
        }
    }

    /// Calculate enhanced confidence using 2025 methods
    private func calculateEnhancedConfidence(thoughts: [Thought], assumptions: [Assumption]) -> Float {
        guard !thoughts.isEmpty else { return ChainOfThoughtConstants.minimumConfidence }

        // Base confidence from thoughts
        let thoughtConfidence = thoughts.reduce(0) { $0 + $1.confidence } / Float(thoughts.count)

        // Penalty for too many unverified assumptions
        let assumptionPenalty: Float = assumptions.isEmpty ? 0 :
            Float(assumptions.filter { $0.confidence < 0.7 }.count) / Float(assumptions.count) * 0.2

        // Bonus for having conclusion and reasoning
        let hasConclusion = thoughts.contains { $0.type == .conclusion }
        let hasReasoning = thoughts.contains { $0.type == .reasoning }
        let structureBonus: Float = (hasConclusion && hasReasoning) ? 0.1 : 0

        // Calculate final confidence
        let confidence = thoughtConfidence - assumptionPenalty + structureBonus
        return max(ChainOfThoughtConstants.minimumConfidence, min(1.0, confidence))
    }

    /// Extract conclusion from thoughts
    private func extractConclusionFromThoughts(_ thoughts: [Thought]) -> String {
        // Find explicit conclusion
        if let conclusionThought = thoughts.last(where: { $0.type == .conclusion }) {
            return conclusionThought.content
        }

        // Fallback to last reasoning thought
        if let lastReasoning = thoughts.last(where: { $0.type == .reasoning }) {
            return lastReasoning.content
        }

        // Final fallback
        return thoughts.last?.content ?? "No conclusion reached"
    }

    /// Extract assumptions from thoughts
    private func extractAssumptionsFromThoughts(_ thoughts: [Thought]) async -> [Assumption] {
        var extractedAssumptions: [Assumption] = []

        for thought in thoughts where thought.type == .assumption || thought.type == .reasoning {
            let assumptions = await extractAssumptions(from: thought.content)
            extractedAssumptions.append(contentsOf: assumptions)
        }

        return extractedAssumptions
    }

    /// Think with self-consistency (2025 best practice)
    private func thinkWithSelfConsistency(
        problem: String,
        context: String?,
        constraints: [String],
        numPaths: Int
    ) async throws -> ThoughtChain {
        print("🔄 Using self-consistency with \(numPaths) reasoning paths...")

        var chains: [ThoughtChain] = []

        // Generate multiple reasoning paths
        for i in 1...numPaths {
            print("  Path \(i)/\(numPaths)...")

            let structuredPrompt = buildStructuredPrompt(
                problem: problem,
                context: context,
                constraints: constraints
            )

            // Generate diverse reasoning paths
            let reasoningResponse = try await generateStructuredReasoning(
                prompt: structuredPrompt
            )

            let thoughts = parseStructuredResponse(reasoningResponse)
            let extractedAssumptions = await extractAssumptionsFromThoughts(thoughts)
            let conclusion = extractConclusionFromThoughts(thoughts)
            let confidence = calculateEnhancedConfidence(thoughts: thoughts, assumptions: extractedAssumptions)

            let chain = ThoughtChain(
                id: UUID(),
                problem: problem,
                thoughts: thoughts,
                conclusion: conclusion,
                confidence: confidence,
                alternatives: [],
                assumptions: extractedAssumptions,
                timestamp: Date()
            )

            chains.append(chain)
        }

        // Select most consistent conclusion
        return selectMostConsistent(chains: chains)
    }

    /// Select the most consistent chain from multiple paths
    private func selectMostConsistent(chains: [ThoughtChain]) -> ThoughtChain {
        // Group by similar conclusions
        var conclusionGroups: [String: [ThoughtChain]] = [:]

        for chain in chains {
            let normalizedConclusion = normalizeConclusion(chain.conclusion)
            conclusionGroups[normalizedConclusion, default: []].append(chain)
        }

        // Find the largest group (most consistent)
        let largestGroup = conclusionGroups.max { $0.value.count < $1.value.count }

        // Return the highest confidence chain from the most consistent group
        if let group = largestGroup?.value {
            let bestChain = group.max { $0.confidence < $1.confidence }

            // Boost confidence based on consistency
            if let best = bestChain {
                let consistencyBonus = Float(group.count) / Float(chains.count) * 0.2
                return ThoughtChain(
                    id: best.id,
                    problem: best.problem,
                    thoughts: best.thoughts,
                    conclusion: best.conclusion,
                    confidence: min(1.0, best.confidence + consistencyBonus),
                    alternatives: best.alternatives,
                    assumptions: best.assumptions,
                    timestamp: best.timestamp
                )
            }
        }

        // Fallback to highest confidence
        return chains.max { $0.confidence < $1.confidence } ?? chains.first!
    }

    /// Normalize conclusion for comparison
    private func normalizeConclusion(_ conclusion: String) -> String {
        return conclusion
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Detect patterns in thought chains
    public func detectPatterns(in chains: [ThoughtChain]) -> [DetectedPattern] {
        var detectedPatterns: [DetectedPattern] = []

        // Look for repeated assumption patterns
        let assumptionFrequency = calculateAssumptionFrequency(chains: chains)
        for (assumption, count) in assumptionFrequency where count > ChainOfThoughtConstants.patternThreshold {
            detectedPatterns.append(DetectedPattern(
                name: ChainOfThoughtConstants.repeatedAssumptionPattern,
                description: "Assumption '\(assumption)' appears in \(count) chains",
                isAntiPattern: count > ChainOfThoughtConstants.antiPatternThreshold,
                occurrences: count,
                recommendation: ChainOfThoughtConstants.assumptionRecommendation,
                examples: [assumption]
            ))
        }

        // Look for low confidence patterns
        let lowConfidenceChains = chains.filter {
            $0.confidence < ChainOfThoughtConstants.lowConfidenceThreshold
        }
        if lowConfidenceChains.count > ChainOfThoughtConstants.patternThreshold {
            detectedPatterns.append(DetectedPattern(
                name: ChainOfThoughtConstants.lowConfidencePattern,
                description: "\(lowConfidenceChains.count) chains have low confidence",
                isAntiPattern: true,
                occurrences: lowConfidenceChains.count,
                recommendation: ChainOfThoughtConstants.confidenceRecommendation,
                examples: lowConfidenceChains.prefix(ChainOfThoughtConstants.maxExamples).map { $0.problem }
            ))
        }

        patterns = detectedPatterns
        return detectedPatterns
    }

    private func calculateAssumptionFrequency(chains: [ThoughtChain]) -> [String: Int] {
        var frequency: [String: Int] = [:]

        for chain in chains {
            for assumption in chain.assumptions {
                frequency[assumption.statement, default: 0] += 1
            }
        }

        return frequency
    }

    /// Generate a reasoning summary
    public func generateSummary() -> String {
        var summary = ChainOfThoughtConstants.summaryHeader

        summary += String(format: ChainOfThoughtConstants.thoughtHistoryFormat, thoughtHistory.count)
        summary += String(format: ChainOfThoughtConstants.assumptionCountFormat, assumptions.count)

        if !patterns.isEmpty {
            summary += ChainOfThoughtConstants.patternsDetectedHeader
            for pattern in patterns.prefix(ChainOfThoughtConstants.maxPatternDisplay) {
                summary += "  - \(pattern.name): \(pattern.description)\n"
            }
        }

        let avgConfidence = thoughtHistory.isEmpty ? 0 :
            thoughtHistory.reduce(0) { $0 + $1.confidence } / Float(thoughtHistory.count)
        summary += String(format: ChainOfThoughtConstants.avgConfidenceFormat, avgConfidence)

        return summary
    }

    /// Analyze a specific thought chain
    public func analyze(chain: ThoughtChain) -> String {
        var analysis = ChainOfThoughtConstants.analysisHeader
        analysis += String(format: ChainOfThoughtConstants.analysisProblemFormat, chain.problem)
        analysis += String(format: ChainOfThoughtConstants.analysisConclusionFormat, chain.conclusion)
        analysis += String(format: ChainOfThoughtConstants.analysisConfidenceFormat, chain.confidence)
        analysis += String(format: ChainOfThoughtConstants.analysisThoughtCountFormat, chain.thoughts.count)

        if !chain.assumptions.isEmpty {
            analysis += ChainOfThoughtConstants.analysisAssumptionsHeader
            for assumption in chain.assumptions {
                analysis += String(format: ChainOfThoughtConstants.analysisAssumptionFormat, assumption.statement, assumption.confidence)
            }
        }

        return analysis
    }

    /// Clear all history
    public func reset() {
        thoughtHistory.removeAll()
        assumptions.removeAll()
        patterns.removeAll()
    }
}