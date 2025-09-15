import Foundation
import AIBridge

/// Decision tree builder for visualizing and managing complex decision paths
public class DecisionTree {

    private let orchestrator: Orchestrator
    private var rootNode: DecisionNode?
    private var currentPath: [DecisionNode] = []

    public init(orchestrator: Orchestrator) {
        self.orchestrator = orchestrator
    }

    /// A node in the decision tree
    public class DecisionNode {
        public let id: UUID
        public let question: String
        public let context: String
        public var options: [Option]
        public var selectedOption: Option?
        public var reasoning: String?
        public let depth: Int
        public weak var parent: DecisionNode?

        public init(
            question: String,
            context: String,
            depth: Int = 0,
            parent: DecisionNode? = nil
        ) {
            self.id = UUID()
            self.question = question
            self.context = context
            self.options = []
            self.depth = depth
            self.parent = parent
        }

        public struct Option {
            public let id: UUID
            public let description: String
            public let pros: [String]
            public let cons: [String]
            public let probability: Float
            public let risk: RiskLevel
            public var childNode: DecisionNode?

            public enum RiskLevel {
                case low
                case medium
                case high
                case critical
            }
        }

        /// Add an option to this decision node
        public func addOption(
            description: String,
            pros: [String],
            cons: [String],
            probability: Float,
            risk: Option.RiskLevel
        ) -> Option {
            let option = Option(
                id: UUID(),
                description: description,
                pros: pros,
                cons: cons,
                probability: probability,
                risk: risk,
                childNode: nil
            )
            options.append(option)
            return option
        }
    }

    /// Build a decision tree for a complex problem
    public func buildDecisionTree(
        for problem: String,
        context: String? = nil,
        maxDepth: Int = 5
    ) async throws -> DecisionNode {

        print("\n🌳 Building Decision Tree")
        print("Problem: \(problem)")

        // Create root node
        let rootQuestion = try await generateRootQuestion(problem: problem, context: context)
        rootNode = DecisionNode(
            question: rootQuestion,
            context: context ?? problem,
            depth: 0
        )

        // Build tree recursively
        try await buildNode(rootNode!, maxDepth: maxDepth)

        return rootNode!
    }

    /// Build a single node with its options
    private func buildNode(_ node: DecisionNode, maxDepth: Int) async throws {
        guard node.depth < maxDepth else { return }

        print("\n📍 Level \(node.depth): \(node.question)")

        // Generate options for this decision
        let options = try await generateOptions(for: node)

        for optionData in options {
            let option = node.addOption(
                description: optionData.description,
                pros: optionData.pros,
                cons: optionData.cons,
                probability: optionData.probability,
                risk: optionData.risk
            )

            print("  → Option: \(option.description) (p=\(option.probability))")

            // Generate follow-up question for this option
            if node.depth < maxDepth - 1 {
                let followUpQuestion = try await generateFollowUpQuestion(
                    parentQuestion: node.question,
                    selectedOption: option.description,
                    context: node.context
                )

                if !followUpQuestion.isEmpty {
                    let childNode = DecisionNode(
                        question: followUpQuestion,
                        context: "\(node.context) → \(option.description)",
                        depth: node.depth + 1,
                        parent: node
                    )

                    // Find the option in node.options and update its childNode
                    if let index = node.options.firstIndex(where: { $0.id == option.id }) {
                        node.options[index].childNode = childNode
                    }

                    // Recursively build child node
                    try await buildNode(childNode, maxDepth: maxDepth)
                }
            }
        }
    }

    /// Navigate the decision tree by making choices
    public func navigate(
        tree: DecisionNode,
        strategy: NavigationStrategy = .highestProbability
    ) async throws -> [DecisionNode] {

        print("\n🧭 Navigating Decision Tree with strategy: \(strategy)")

        var path: [DecisionNode] = [tree]
        var currentNode = tree

        while !currentNode.options.isEmpty {
            // Select option based on strategy
            let selectedOption = try await selectOption(
                from: currentNode,
                using: strategy
            )

            // Record reasoning
            currentNode.reasoning = try await explainChoice(
                node: currentNode,
                selected: selectedOption,
                strategy: strategy
            )

            currentNode.selectedOption = selectedOption

            print("✓ At '\(currentNode.question)' chose: \(selectedOption.description)")

            // Move to child node if exists
            if let childNode = selectedOption.childNode {
                path.append(childNode)
                currentNode = childNode
            } else {
                break // Leaf node reached
            }
        }

        self.currentPath = path
        return path
    }

    /// Select an option based on navigation strategy
    private func selectOption(
        from node: DecisionNode,
        using strategy: NavigationStrategy
    ) async throws -> DecisionNode.Option {

        guard !node.options.isEmpty else {
            throw DecisionError.noOptions
        }

        switch strategy {
        case .highestProbability:
            return node.options.max(by: { $0.probability < $1.probability })!

        case .lowestRisk:
            return node.options.min(by: { riskValue($0.risk) < riskValue($1.risk) })!

        case .balanced:
            // Balance between probability and risk
            return node.options.max(by: { opt1, opt2 in
                let score1 = opt1.probability * (1.0 - Float(riskValue(opt1.risk)) / 4.0)
                let score2 = opt2.probability * (1.0 - Float(riskValue(opt2.risk)) / 4.0)
                return score1 < score2
            })!

        case .aiRecommended:
            let recommendation = try await getAIRecommendation(node: node)
            return node.options.first { $0.description == recommendation } ?? node.options[0]

        case .interactive:
            // In real implementation, would prompt user
            return node.options[0]
        }
    }

    private func riskValue(_ risk: DecisionNode.Option.RiskLevel) -> Int {
        switch risk {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }

    /// Get AI recommendation for best option
    private func getAIRecommendation(node: DecisionNode) async throws -> String {
        let optionsList = node.options.map { option in
            """
            Option: \(option.description)
            Pros: \(option.pros.joined(separator: ", "))
            Cons: \(option.cons.joined(separator: ", "))
            Probability: \(option.probability)
            Risk: \(option.risk)
            """
        }.joined(separator: "\n\n")

        let prompt = """
        Given this decision:
        Question: \(node.question)
        Context: \(node.context)

        Options:
        \(optionsList)

        Which option would you recommend and why?
        Return just the option description.
        """

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true
        )

        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Explain why a choice was made
    private func explainChoice(
        node: DecisionNode,
        selected: DecisionNode.Option,
        strategy: NavigationStrategy
    ) async throws -> String {

        let prompt = """
        Explain this decision:
        Question: \(node.question)
        Chosen: \(selected.description)
        Strategy: \(strategy)

        Why this choice makes sense given:
        - Probability: \(selected.probability)
        - Risk: \(selected.risk)
        - Pros: \(selected.pros.joined(separator: ", "))
        - Cons: \(selected.cons.joined(separator: ", "))

        Be concise but clear.
        """

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true
        )

        return response
    }

    // MARK: - Tree Generation Methods

    private func generateRootQuestion(problem: String, context: String?) async throws -> String {
        let prompt = """
        Create the first decision question for this problem:
        Problem: \(problem)
        \(context.map { "Context: \($0)" } ?? "")

        The question should:
        1. Address the most fundamental choice
        2. Be clear and binary/multiple choice
        3. Lead to meaningful different paths

        Return just the question.
        """

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true
        )

        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func generateOptions(for node: DecisionNode) async throws -> [OptionData] {
        let prompt = """
        Generate 2-4 options for this decision:
        Question: \(node.question)
        Context: \(node.context)

        For each option provide:
        OPTION: [description]
        PROS: [comma-separated benefits]
        CONS: [comma-separated drawbacks]
        PROBABILITY: [0.0-1.0 success chance]
        RISK: [LOW/MEDIUM/HIGH/CRITICAL]

        Make options distinct and meaningful.
        """

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true
        )

        return parseOptions(from: response)
    }

    private func generateFollowUpQuestion(
        parentQuestion: String,
        selectedOption: String,
        context: String
    ) async throws -> String {

        let prompt = """
        Given this decision path:
        Previous question: \(parentQuestion)
        Selected: \(selectedOption)
        Context: \(context)

        What's the next decision that needs to be made?

        Return a follow-up question, or empty string if this is a final decision.
        """

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true
        )

        let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.lowercased().contains("final") || cleaned.lowercased().contains("none") ? "" : cleaned
    }

    private func parseOptions(from response: String) -> [OptionData] {
        var options: [OptionData] = []
        let sections = response.split(separator: "OPTION:")

        for section in sections.dropFirst() {
            let lines = section.split(separator: "\n")
            var data = OptionData()

            for line in lines {
                let lineStr = String(line).trimmingCharacters(in: .whitespaces)

                if lineStr.starts(with: "PROS:") {
                    let prosStr = lineStr.replacingOccurrences(of: "PROS:", with: "").trimmingCharacters(in: .whitespaces)
                    data.pros = prosStr.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                } else if lineStr.starts(with: "CONS:") {
                    let consStr = lineStr.replacingOccurrences(of: "CONS:", with: "").trimmingCharacters(in: .whitespaces)
                    data.cons = consStr.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                } else if lineStr.starts(with: "PROBABILITY:") {
                    let probStr = lineStr.replacingOccurrences(of: "PROBABILITY:", with: "").trimmingCharacters(in: .whitespaces)
                    data.probability = Float(probStr) ?? 0.5
                } else if lineStr.starts(with: "RISK:") {
                    let riskStr = lineStr.replacingOccurrences(of: "RISK:", with: "").trimmingCharacters(in: .whitespaces)
                    data.risk = riskStr.contains("CRITICAL") ? .critical :
                               riskStr.contains("HIGH") ? .high :
                               riskStr.contains("LOW") ? .low : .medium
                } else if data.description.isEmpty && !lineStr.isEmpty {
                    data.description = lineStr
                }
            }

            if !data.description.isEmpty {
                options.append(data)
            }
        }

        return options
    }

    private struct OptionData {
        var description: String = ""
        var pros: [String] = []
        var cons: [String] = []
        var probability: Float = 0.5
        var risk: DecisionNode.Option.RiskLevel = .medium
    }

    /// Visualize the decision tree as text
    public func visualize(_ node: DecisionNode, indent: String = "") -> String {
        var output = "\(indent)\(node.depth == 0 ? "🌳" : "📍") \(node.question)\n"

        for option in node.options {
            let selected = node.selectedOption?.id == option.id
            let marker = selected ? "✅" : "○"
            output += "\(indent)  \(marker) \(option.description) (p=\(option.probability), risk=\(option.risk))\n"

            if let child = option.childNode {
                output += visualize(child, indent: indent + "    ")
            }
        }

        return output
    }

    /// Navigation strategies for traversing the tree
    public enum NavigationStrategy {
        case highestProbability
        case lowestRisk
        case balanced
        case aiRecommended
        case interactive
    }

    /// Errors that can occur in decision tree operations
    public enum DecisionError: Error {
        case noOptions
        case invalidNode
        case maxDepthReached
    }
}