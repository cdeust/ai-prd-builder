import Foundation

// MARK: - MCTS Node

public class MCTSNode {
    public let state: OpenAPIState
    public private(set) weak var parent: MCTSNode?
    public private(set) var children: [MCTSNode] = []
    public private(set) var visits: Int = 0
    public private(set) var totalReward: Double = 0.0

    public init(state: OpenAPIState, parent: MCTSNode? = nil) {
        self.state = state
        self.parent = parent
    }

    public var averageReward: Double {
        guard visits > 0 else { return 0 }
        return totalReward / Double(visits)
    }

    public var isLeaf: Bool {
        children.isEmpty
    }

    public var isFullyExpanded: Bool {
        children.count >= state.availableActions.count
    }

    public var canExpand: Bool {
        !isFullyExpanded && !state.isTerminal
    }

    public var bestChild: MCTSNode? {
        children.max(by: { $0.averageReward < $1.averageReward })
    }

    public var bestPath: MCTSNode? {
        var current = self
        while !current.children.isEmpty {
            guard let best = current.bestChild else { break }
            current = best
        }
        return current
    }

    public func addChild(_ child: MCTSNode) {
        children.append(child)
    }

    public func update(reward: Double) {
        visits += 1
        totalReward += reward
    }
}

// MARK: - OpenAPI State

public struct OpenAPIState {
    public var specification: String
    public var validationIssues: [String]
    public var fixedIssues: [String]
    public let depth: Int
    public var confidence: Double

    public init(
        specification: String,
        validationIssues: [String] = [],
        fixedIssues: [String] = [],
        depth: Int = 0,
        confidence: Double = 0.0
    ) {
        self.specification = specification
        self.validationIssues = validationIssues
        self.fixedIssues = fixedIssues
        self.depth = depth
        self.confidence = confidence
    }

    public var isTerminal: Bool {
        validationIssues.isEmpty || depth >= OpenAPIValidationConstants.MCTS.maxSimulationDepth
    }

    public var isValid: Bool {
        validationIssues.isEmpty && confidence > Double(OpenAPIValidationConstants.Validation.minConfidenceThreshold)
    }

    public var availableActions: [OpenAPIAction] {
        guard !isTerminal else { return [] }

        var actions: [OpenAPIAction] = []

        // Generate fix actions for each issue
        for issue in validationIssues.prefix(OpenAPIValidationConstants.MCTS.maxActionsPerNode) {
            actions.append(OpenAPIAction(type: .fix, target: issue))
        }

        // Add enhancement actions if mostly fixed
        if validationIssues.count <= 2 {
            actions.append(OpenAPIAction(type: .enhance, target: "schemas"))
            actions.append(OpenAPIAction(type: .enhance, target: "examples"))
        }

        // Add validation action
        actions.append(OpenAPIAction(type: .validate, target: "full"))

        return actions
    }

    public func apply(action: OpenAPIAction) -> OpenAPIState {
        var newIssues = validationIssues
        var newFixed = fixedIssues

        switch action.type {
        case .fix:
            // Remove the fixed issue
            if let index = newIssues.firstIndex(of: action.target) {
                newIssues.remove(at: index)
                newFixed.append(action.target)
            }
        case .enhance:
            // Enhancements don't change issues but improve quality
            break
        case .validate:
            // Validation might discover new issues (simulated here)
            break
        }

        // Calculate new confidence
        let baseConfidence = Double(newFixed.count) / Double(newFixed.count + newIssues.count + 1)
        let depthPenalty = Double(depth) * 0.01
        let newConfidence = min(1.0, baseConfidence - depthPenalty)

        return OpenAPIState(
            specification: specification, // In real implementation, this would be modified
            validationIssues: newIssues,
            fixedIssues: newFixed,
            depth: depth + 1,
            confidence: newConfidence
        )
    }

    public var reward: Double {
        // Reward based on progress and validity
        let progressReward = Double(fixedIssues.count) / Double(fixedIssues.count + validationIssues.count + 1)
        let depthPenalty = Double(depth) * 0.02
        let validityBonus = isValid ? 0.5 : 0.0

        return max(0, progressReward - depthPenalty + validityBonus)
    }
}

// MARK: - OpenAPI Action

public struct OpenAPIAction {
    public let type: ActionType
    public let target: String

    public enum ActionType {
        case fix
        case enhance
        case validate
    }

    public init(type: ActionType, target: String) {
        self.type = type
        self.target = target
    }
}