import Foundation

/// Monte Carlo Tree Search for OpenAPI validation
/// Based on 2025 MCTS-RAG research
public class MCTSValidator {

    private var root: MCTSNode?
    private let explorationConstant: Double

    public init(explorationConstant: Double = OpenAPIValidationConstants.MCTS.explorationConstant) {
        self.explorationConstant = explorationConstant
    }

    // MARK: - Public Interface

    public func search(
        initialState: OpenAPIState,
        maxIterations: Int = OpenAPIValidationConstants.MCTS.defaultMaxIterations,
        simulationHandler: (MCTSNode) async throws -> Double
    ) async throws -> MCTSNode {

        root = MCTSNode(state: initialState)
        guard let root = root else {
            throw ValidationError.initializationFailed
        }

        for iteration in 1...maxIterations {
            // Core MCTS loop
            let selectedNode = selection(root)
            let expandedNode = expansion(selectedNode)
            let reward = try await simulationHandler(expandedNode)
            backpropagation(expandedNode, reward: reward)

            if shouldTerminateEarly(reward: reward, iteration: iteration) {
                break
            }

            reportProgress(iteration: iteration)
        }

        return try getBestPath()
    }

    // MARK: - MCTS Core Operations

    private func selection(_ node: MCTSNode) -> MCTSNode {
        var current = node

        while !current.isLeaf && current.isFullyExpanded {
            current = selectBestChild(of: current)
        }

        return current
    }

    private func expansion(_ node: MCTSNode) -> MCTSNode {
        if node.canExpand {
            let child = MCTSNode(state: node.state, parent: node)
            node.addChild(child)
            return child
        }
        return node
    }

    private func backpropagation(_ node: MCTSNode, reward: Double) {
        var current: MCTSNode? = node

        while let node = current {
            node.update(reward: reward)
            current = node.parent
        }
    }

    // MARK: - Helper Methods

    private func selectBestChild(of node: MCTSNode) -> MCTSNode {
        guard let bestChild = node.children.max(by: {
            ucb1Score(for: $0) < ucb1Score(for: $1)
        }) else {
            return node
        }
        return bestChild
    }

    private func ucb1Score(for node: MCTSNode) -> Double {
        guard node.visits > 0, let parent = node.parent else {
            return Double.infinity
        }

        let exploitation = node.averageReward
        let exploration = explorationConstant * sqrt(log(Double(parent.visits)) / Double(node.visits))
        let score = exploitation + exploration
        return score
    }

    private func shouldTerminateEarly(reward: Double, iteration: Int) -> Bool {
        if reward > OpenAPIValidationConstants.MCTS.highQualityThreshold {
            print(String(format: OpenAPIValidationConstants.MCTS.successMessage, iteration))
            return true
        }
        return false
    }

    private func reportProgress(iteration: Int) {
        if iteration % OpenAPIValidationConstants.MCTS.progressReportInterval == 0 {
            let bestReward = root?.bestChild?.averageReward ?? 0
            print(String(format: OpenAPIValidationConstants.MCTS.iterationMessage, iteration, bestReward))
        }
    }

    private func getBestPath() throws -> MCTSNode {
        guard let root = root, let bestNode = root.bestPath else {
            throw ValidationError.noValidPathFound
        }
        return bestNode
    }
}


