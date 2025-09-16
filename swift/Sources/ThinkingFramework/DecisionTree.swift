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

    /// Build a decision tree for a complex problem
    public func buildDecisionTree(
        for problem: String,
        context: String? = nil,
        maxDepth: Int = 5
    ) async throws -> DecisionNode {

        print(DecisionTreeConstants.buildingTreeMessage)
        print("\(DecisionTreeConstants.problemPrefixMessage)\(problem)")

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

    /// Build a node and its children recursively
    private func buildNode(_ node: DecisionNode, maxDepth: Int) async throws {
        guard node.depth < maxDepth else { return }

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

            // Should this option lead to another decision?
            if shouldExpand(option: option, depth: node.depth) {
                let childQuestion = try await generateChildQuestion(
                    parentNode: node,
                    selectedOption: option
                )

                let childNode = DecisionNode(
                    question: childQuestion,
                    context: "\(node.context)\(DecisionTreeConstants.contextSeparator)\(option.description)",
                    depth: node.depth + 1,
                    parent: node
                )

                // Update option to point to child
                if let index = node.options.firstIndex(where: { $0.id == option.id }) {
                    node.options[index].childNode = childNode
                }

                // Recursively build the child
                try await buildNode(childNode, maxDepth: maxDepth)
            }
        }
    }

    /// Generate the root question from the problem
    private func generateRootQuestion(problem: String, context: String?) async throws -> String {
        let prompt = buildRootQuestionPrompt(problem: problem, context: context)

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: .criticalAnalysis
        )

        return response
    }

    private func buildRootQuestionPrompt(problem: String, context: String?) -> String {
        var prompt = String(format: DecisionTreeConstants.rootQuestionPromptTemplate, problem)
        if let context = context {
            prompt += String(format: DecisionTreeConstants.contextAdditionTemplate, context)
        }
        return prompt
    }

    /// Generate options for a decision node
    private func generateOptions(for node: DecisionNode) async throws -> [OptionData] {
        let prompt = buildOptionsPrompt(node: node)

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: .divergentThinking
        )

        // Convert from parser's OptionData to internal OptionData
        let parserOptions = DecisionTreeParser.parseOptions(from: response)
        return parserOptions.map { parserOption in
            OptionData(
                description: parserOption.description,
                pros: parserOption.pros,
                cons: parserOption.cons,
                probability: parserOption.probability,
                risk: parserOption.risk
            )
        }
    }

    private func buildOptionsPrompt(node: DecisionNode) -> String {
        return String(format: DecisionTreeConstants.generateOptionsPromptTemplate,
                     node.question,
                     node.context)
    }

    /// Determine if an option should lead to another decision
    private func shouldExpand(option: DecisionNode.Option, depth: Int) -> Bool {
        // Don't expand low probability or high risk options
        if option.probability < DecisionTreeConstants.expansionProbabilityThreshold {
            return false
        }

        if option.risk == .critical {
            return false
        }

        // Expand if there's complexity indicated
        return option.cons.count > DecisionTreeConstants.complexityThreshold ||
               depth < DecisionTreeConstants.minExpansionDepth
    }

    /// Generate a child question based on selected option
    private func generateChildQuestion(
        parentNode: DecisionNode,
        selectedOption: DecisionNode.Option
    ) async throws -> String {

        let prompt = buildChildQuestionPrompt(parentNode: parentNode, selectedOption: selectedOption)

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: .convergentThinking
        )

        return response
    }

    private func buildChildQuestionPrompt(parentNode: DecisionNode, selectedOption: DecisionNode.Option) -> String {
        return String(format: DecisionTreeConstants.childQuestionPromptTemplate,
                     parentNode.question,
                     selectedOption.description,
                     selectedOption.pros.joined(separator: DecisionTreeConstants.listSeparator),
                     selectedOption.cons.joined(separator: DecisionTreeConstants.listSeparator))
    }

    /// Navigate through the decision tree interactively or automatically
    public func navigate(
        tree: DecisionNode,
        strategy: NavigationStrategy = .highestProbability
    ) async throws -> [DecisionNode] {

        print(DecisionTreeConstants.navigationStart)
        currentPath = []

        var currentNode = tree
        currentPath.append(currentNode)

        while !currentNode.options.isEmpty {
            print(String(format: DecisionTreeConstants.currentNodeFormat, currentNode.question))

            // Display options
            for (index, option) in currentNode.options.enumerated() {
                print(String(format: DecisionTreeConstants.optionDisplayFormat,
                           index + 1,
                           option.description,
                           option.probability))
            }

            // Select option based on strategy
            guard let selectedOption = try await selectOption(
                from: currentNode.options,
                strategy: strategy
            ) else {
                break
            }

            currentNode.selectedOption = selectedOption
            print(String(format: DecisionTreeConstants.selectedFormat, selectedOption.description))

            // Move to child node if exists
            if let childNode = selectedOption.childNode {
                currentNode = childNode
                currentPath.append(currentNode)
            } else {
                break // Leaf node reached
            }
        }

        print(DecisionTreeConstants.navigationComplete)
        return currentPath
    }

    /// Select an option based on navigation strategy
    private func selectOption(
        from options: [DecisionNode.Option],
        strategy: NavigationStrategy
    ) async throws -> DecisionNode.Option? {

        guard !options.isEmpty else {
            throw DecisionError.noOptions
        }

        switch strategy {
        case .highestProbability:
            return options.max { $0.probability < $1.probability }

        case .lowestRisk:
            return options.min { riskValue($0.risk) < riskValue($1.risk) }

        case .balanced:
            return options.max { balancedScore($0) < balancedScore($1) }

        case .aiRecommended:
            return try await getAIRecommendation(options: options)

        case .interactive:
            return try await getUserSelection(options: options)
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

    private func balancedScore(_ option: DecisionNode.Option) -> Float {
        let riskPenalty = Float(riskValue(option.risk)) * DecisionTreeConstants.riskPenaltyMultiplier
        return option.probability - riskPenalty
    }

    private func riskDescription(_ risk: DecisionNode.Option.RiskLevel) -> String {
        switch risk {
        case .low: return DecisionTreeConstants.lowRiskDescription
        case .medium: return DecisionTreeConstants.mediumRiskDescription
        case .high: return DecisionTreeConstants.highRiskDescription
        case .critical: return DecisionTreeConstants.criticalRiskDescription
        }
    }

    /// Get AI recommendation for best option
    private func getAIRecommendation(options: [DecisionNode.Option]) async throws -> DecisionNode.Option? {
        let prompt = buildRecommendationPrompt(options: options)

        let (response, _) = try await orchestrator.chat(
            message: prompt,
            useAppleIntelligence: true,
            thinkingMode: .criticalAnalysis
        )

        // Parse the response to get the selected option
        if let selectedIndex = Int(response.trimmingCharacters(in: .whitespacesAndNewlines)),
           selectedIndex > 0 && selectedIndex <= options.count {
            return options[selectedIndex - 1]
        }

        return options.first // Fallback
    }

    private func buildRecommendationPrompt(options: [DecisionNode.Option]) -> String {
        var optionsDescription = DecisionTreeConstants.emptyString
        for (index, option) in options.enumerated() {
            optionsDescription += String(format: DecisionTreeConstants.optionDescriptionFormat,
                                        index + 1,
                                        option.description,
                                        option.pros.joined(separator: DecisionTreeConstants.listSeparator),
                                        option.cons.joined(separator: DecisionTreeConstants.listSeparator),
                                        option.probability,
                                        riskDescription(option.risk))
        }

        return String(format: DecisionTreeConstants.recommendationPromptTemplate, optionsDescription)
    }

    /// Get user selection interactively
    private func getUserSelection(options: [DecisionNode.Option]) async throws -> DecisionNode.Option? {
        print(DecisionTreeConstants.selectOptionPrompt)

        guard let input = readLine(),
              let selectedIndex = Int(input),
              selectedIndex > 0 && selectedIndex <= options.count else {
            throw DecisionError.invalidSelection
        }

        return options[selectedIndex - 1]
    }

    /// Visualize the decision tree
    public func visualize(_ node: DecisionNode, indent: Int = 0) {
        let indentation = String(repeating: DecisionTreeConstants.treeIndent, count: indent)

        print("\(indentation)\(DecisionTreeConstants.nodeEmoji) \(node.question)")

        if let selected = node.selectedOption {
            print("\(indentation)  \(DecisionTreeConstants.selectedEmoji) Selected: \(selected.description)")
        }

        for option in node.options {
            let symbol = option.childNode != nil ?
                DecisionTreeConstants.branchSymbol : DecisionTreeConstants.leafSymbol

            print("\(indentation)  \(symbol) \(option.description)\(String(format: DecisionTreeConstants.probabilityFormat, option.probability))")

            if let childNode = option.childNode {
                visualize(childNode, indent: indent + 1)
            }
        }
    }

    /// Generate a summary of the decision path
    public func generateSummary() -> String {
        var summary = DecisionTreeConstants.summaryHeader

        for (index, node) in currentPath.enumerated() {
            summary += String(format: DecisionTreeConstants.stepFormat, index + 1, node.question)

            if let selected = node.selectedOption {
                summary += String(format: DecisionTreeConstants.decisionFormat, selected.description)
            }
        }

        return summary
    }

    /// Clear the current path
    public func reset() {
        currentPath.removeAll()
        rootNode = nil
    }

    /// Helper structure for option data
    private struct OptionData {
        let description: String
        let pros: [String]
        let cons: [String]
        let probability: Float
        let risk: DecisionNode.Option.RiskLevel
    }
}