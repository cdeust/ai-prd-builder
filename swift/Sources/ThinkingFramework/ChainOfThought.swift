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

    /// Represents a single thought in the reasoning chain
    public struct Thought {
        public let id: UUID
        public let content: String
        public let type: ThoughtType
        public let confidence: Float
        public let timestamp: Date
        public let parent: UUID?
        public let children: [UUID]

        public enum ThoughtType {
            case observation      // What I see
            case assumption      // What I assume
            case reasoning       // How I connect ideas
            case question       // What I need to know
            case conclusion     // What I decide
            case warning       // Potential issues
            case alternative   // Other possibilities
        }
    }

    /// A complete chain of thoughts leading to a conclusion
    public struct ThoughtChain {
        public let id: UUID
        public let problem: String
        public let thoughts: [Thought]
        public let conclusion: String
        public let confidence: Float
        public let alternatives: [Alternative]
        public let assumptions: [Assumption]
        public let timestamp: Date

        public struct Alternative {
            public let description: String
            public let probability: Float
            public let pros: [String]
            public let cons: [String]
        }
    }

    /// An assumption made during reasoning
    public struct Assumption {
        public let id: UUID
        public let statement: String
        public let confidence: Float
        public let verified: Bool
        public let impact: ImpactLevel
        public let context: String

        public enum ImpactLevel {
            case critical   // Wrong assumption breaks everything
            case high      // Significant impact on outcome
            case medium    // Some impact
            case low       // Minor impact
        }
    }

    /// A pattern detected in thinking or code
    public struct DetectedPattern {
        public let name: String
        public let description: String
        public let isAntiPattern: Bool
        public let occurrences: Int
        public let recommendation: String
        public let examples: [String]
    }

    /// Think through a problem step by step
    public func thinkThrough(
        problem: String,
        context: String? = nil,
        constraints: [String] = []
    ) async throws -> ThoughtChain {

        print("\n🧠 Chain of Thought: Starting reasoning process")
        print("Problem: \(problem)")

        var thoughts: [Thought] = []
        var currentAssumptions: [Assumption] = []

        // Step 1: Break down the problem
        let breakdown = try await breakdownProblem(problem, context: context)
        thoughts.append(Thought(
            id: UUID(),
            content: breakdown,
            type: .observation,
            confidence: 0.9,
            timestamp: Date(),
            parent: nil,
            children: []
        ))
        print("📊 Breakdown: \(breakdown)")

        // Step 2: Identify assumptions
        let assumptionsList = try await identifyAssumptions(problem, breakdown: breakdown)
        for assumption in assumptionsList {
            thoughts.append(Thought(
                id: UUID(),
                content: "Assuming: \(assumption.statement)",
                type: .assumption,
                confidence: assumption.confidence,
                timestamp: Date(),
                parent: thoughts.last?.id,
                children: []
            ))
            currentAssumptions.append(assumption)
        }
        print("💭 Assumptions: \(assumptionsList.count) identified")

        // Step 3: Generate reasoning steps
        let reasoningSteps = try await generateReasoningSteps(
            problem: problem,
            assumptions: currentAssumptions,
            constraints: constraints
        )

        for step in reasoningSteps {
            thoughts.append(Thought(
                id: UUID(),
                content: step,
                type: .reasoning,
                confidence: 0.8,
                timestamp: Date(),
                parent: thoughts.last?.id,
                children: []
            ))
            print("🔗 Reasoning: \(step)")
        }

        // Step 4: Identify potential issues
        let warnings = try await identifyPotentialIssues(
            problem: problem,
            reasoning: reasoningSteps
        )

        for warning in warnings {
            thoughts.append(Thought(
                id: UUID(),
                content: warning,
                type: .warning,
                confidence: 0.7,
                timestamp: Date(),
                parent: thoughts.last?.id,
                children: []
            ))
            print("⚠️ Warning: \(warning)")
        }

        // Step 5: Generate alternatives
        let alternatives = try await generateAlternatives(
            problem: problem,
            mainPath: reasoningSteps
        )

        // Step 6: Form conclusion
        let conclusion = try await formConclusion(
            problem: problem,
            thoughts: thoughts,
            alternatives: alternatives
        )

        thoughts.append(Thought(
            id: UUID(),
            content: conclusion,
            type: .conclusion,
            confidence: 0.85,
            timestamp: Date(),
            parent: thoughts.last?.id,
            children: []
        ))

        print("✅ Conclusion: \(conclusion)")

        let chain = ThoughtChain(
            id: UUID(),
            problem: problem,
            thoughts: thoughts,
            conclusion: conclusion,
            confidence: calculateOverallConfidence(thoughts),
            alternatives: alternatives,
            assumptions: currentAssumptions,
            timestamp: Date()
        )

        thoughtHistory.append(chain)
        return chain
    }

    // MARK: - Private Methods

    private func breakdownProblem(_ problem: String, context: String?) async throws -> String {
        let prompt = """
        Break down this problem into its core components:
        Problem: \(problem)
        \(context.map { "Context: \($0)" } ?? "")

        Identify:
        1. What we're trying to achieve
        2. What we know
        3. What we don't know
        4. Key challenges

        Be specific and analytical.
        """

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true
        )

        return response
    }

    private func identifyAssumptions(_ problem: String, breakdown: String) async throws -> [Assumption] {
        let prompt = """
        Based on this problem and breakdown:
        Problem: \(problem)
        Breakdown: \(breakdown)

        List all assumptions we're making. For each:
        ASSUMPTION: [what we're assuming]
        CONFIDENCE: [0.0-1.0]
        IMPACT: [CRITICAL/HIGH/MEDIUM/LOW]
        IF_WRONG: [what happens if this assumption is incorrect]
        """

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true
        )

        return parseAssumptions(from: response, context: problem)
    }

    private func generateReasoningSteps(
        problem: String,
        assumptions: [Assumption],
        constraints: [String]
    ) async throws -> [String] {
        let assumptionsList = assumptions.map { "- \($0.statement) (confidence: \($0.confidence))" }.joined(separator: "\n")
        let constraintsList = constraints.isEmpty ? "None" : constraints.joined(separator: "\n")

        let prompt = """
        Generate step-by-step reasoning for solving:
        Problem: \(problem)

        Given assumptions:
        \(assumptionsList)

        Constraints:
        \(constraintsList)

        Provide logical steps that:
        1. Build on each other
        2. Check assumptions when possible
        3. Stay within constraints
        4. Lead to a solution

        Format: One step per line, numbered.
        """

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true
        )

        return response.split(separator: "\n").map { String($0) }
    }

    private func identifyPotentialIssues(
        problem: String,
        reasoning: [String]
    ) async throws -> [String] {
        let prompt = """
        Review this reasoning chain for potential issues:
        Problem: \(problem)
        Reasoning steps:
        \(reasoning.joined(separator: "\n"))

        Identify:
        1. Logic flaws
        2. Missing edge cases
        3. Incorrect assumptions
        4. Anti-patterns
        5. Performance concerns

        List each issue clearly.
        """

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true
        )

        return response.split(separator: "\n")
            .filter { !$0.isEmpty }
            .map { String($0) }
    }

    private func generateAlternatives(
        problem: String,
        mainPath: [String]
    ) async throws -> [ThoughtChain.Alternative] {
        let prompt = """
        Given this solution approach:
        Problem: \(problem)
        Main approach:
        \(mainPath.joined(separator: "\n"))

        Generate 2-3 alternative approaches.

        For each alternative provide:
        APPROACH: [description]
        PROBABILITY: [0.0-1.0 success likelihood]
        PROS: [advantages]
        CONS: [disadvantages]
        """

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true
        )

        return parseAlternatives(from: response)
    }

    private func formConclusion(
        problem: String,
        thoughts: [Thought],
        alternatives: [ThoughtChain.Alternative]
    ) async throws -> String {
        let thoughtSummary = thoughts.suffix(5).map { $0.content }.joined(separator: "\n")

        let prompt = """
        Form a conclusion based on this reasoning:
        Problem: \(problem)

        Recent thoughts:
        \(thoughtSummary)

        Alternatives considered: \(alternatives.count)

        Provide a clear, actionable conclusion that:
        1. Addresses the original problem
        2. Acknowledges key assumptions
        3. Suggests next steps
        4. Notes any risks

        Keep it concise but complete.
        """

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true
        )

        return response
    }

    private func parseAssumptions(from response: String, context: String) -> [Assumption] {
        var assumptions: [Assumption] = []
        let lines = response.split(separator: "\n")

        var currentAssumption: String?
        var currentConfidence: Float = 0.5
        var currentImpact: Assumption.ImpactLevel = .medium

        for line in lines {
            let lineStr = String(line)

            if lineStr.starts(with: "ASSUMPTION:") {
                currentAssumption = lineStr.replacingOccurrences(of: "ASSUMPTION:", with: "").trimmingCharacters(in: .whitespaces)
            } else if lineStr.starts(with: "CONFIDENCE:") {
                let confStr = lineStr.replacingOccurrences(of: "CONFIDENCE:", with: "").trimmingCharacters(in: .whitespaces)
                currentConfidence = Float(confStr) ?? 0.5
            } else if lineStr.starts(with: "IMPACT:") {
                let impactStr = lineStr.replacingOccurrences(of: "IMPACT:", with: "").trimmingCharacters(in: .whitespaces)
                currentImpact = impactStr.contains("CRITICAL") ? .critical :
                                impactStr.contains("HIGH") ? .high :
                                impactStr.contains("LOW") ? .low : .medium

                // Create assumption when we have all parts
                if let assumption = currentAssumption {
                    assumptions.append(Assumption(
                        id: UUID(),
                        statement: assumption,
                        confidence: currentConfidence,
                        verified: false,
                        impact: currentImpact,
                        context: context
                    ))
                }
            }
        }

        return assumptions
    }

    private func parseAlternatives(from response: String) -> [ThoughtChain.Alternative] {
        // Simplified parsing - would be more robust in production
        var alternatives: [ThoughtChain.Alternative] = []

        let sections = response.split(separator: "APPROACH:")
        for section in sections.dropFirst() {
            let lines = section.split(separator: "\n")

            var description = ""
            var probability: Float = 0.5
            var pros: [String] = []
            var cons: [String] = []

            for line in lines {
                let lineStr = String(line).trimmingCharacters(in: .whitespaces)

                if lineStr.starts(with: "PROBABILITY:") {
                    let probStr = lineStr.replacingOccurrences(of: "PROBABILITY:", with: "").trimmingCharacters(in: .whitespaces)
                    probability = Float(probStr) ?? 0.5
                } else if lineStr.starts(with: "PROS:") {
                    pros = [lineStr.replacingOccurrences(of: "PROS:", with: "").trimmingCharacters(in: .whitespaces)]
                } else if lineStr.starts(with: "CONS:") {
                    cons = [lineStr.replacingOccurrences(of: "CONS:", with: "").trimmingCharacters(in: .whitespaces)]
                } else if description.isEmpty {
                    description = lineStr
                }
            }

            if !description.isEmpty {
                alternatives.append(ThoughtChain.Alternative(
                    description: description,
                    probability: probability,
                    pros: pros,
                    cons: cons
                ))
            }
        }

        return alternatives
    }

    private func calculateOverallConfidence(_ thoughts: [Thought]) -> Float {
        guard !thoughts.isEmpty else { return 0.0 }

        let totalConfidence = thoughts.reduce(0.0) { $0 + $1.confidence }
        return totalConfidence / Float(thoughts.count)
    }

    /// Detect patterns in thinking to avoid anti-patterns
    public func detectPatterns(in chains: [ThoughtChain]) -> [DetectedPattern] {
        var patterns: [DetectedPattern] = []

        // Check for common anti-patterns
        let hasOverconfidence = chains.filter { $0.confidence > 0.95 }.count > chains.count / 2
        if hasOverconfidence {
            patterns.append(DetectedPattern(
                name: "Overconfidence Pattern",
                description: "Too many high-confidence conclusions without verification",
                isAntiPattern: true,
                occurrences: chains.filter { $0.confidence > 0.95 }.count,
                recommendation: "Add more verification steps and consider alternatives",
                examples: []
            ))
        }

        // Check for assumption-heavy reasoning
        let avgAssumptions = chains.reduce(0) { $0 + $1.assumptions.count } / max(chains.count, 1)
        if avgAssumptions > 5 {
            patterns.append(DetectedPattern(
                name: "Assumption Overload",
                description: "Too many unverified assumptions in reasoning",
                isAntiPattern: true,
                occurrences: avgAssumptions,
                recommendation: "Verify assumptions before proceeding",
                examples: []
            ))
        }

        self.patterns = patterns
        return patterns
    }
}