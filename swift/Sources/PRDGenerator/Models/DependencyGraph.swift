import Foundation

/// Represents dependencies between components/features
/// Single Responsibility: Only manages dependency relationships
public struct DependencyGraph: Codable {
    public let nodes: Set<DependencyNode>
    public let edges: [DependencyEdge]
    public let analysisDate: Date

    public init(
        nodes: Set<DependencyNode>,
        edges: [DependencyEdge],
        analysisDate: Date = Date()
    ) {
        self.nodes = nodes
        self.edges = edges
        self.analysisDate = analysisDate
    }

    /// Find all cycles in the dependency graph
    public var cycles: [DependencyCycle] {
        // This would be computed using graph algorithms
        // Keeping it simple for now - would use DFS/Tarjan's algorithm
        return []
    }

    /// Find the critical path through dependencies
    public var criticalPath: [String] {
        // Would use topological sort to find longest path
        return []
    }

    /// Check if graph has circular dependencies
    public var hasCircularDependencies: Bool {
        !cycles.isEmpty
    }

    /// Get all external dependencies
    public var externalDependencies: [DependencyNode] {
        nodes.filter { $0.external }
    }

    /// Get dependency count for a specific node
    public func dependencyCount(for nodeId: String) -> Int {
        edges.filter { $0.to == nodeId }.count
    }

    /// Get dependent count for a specific node
    public func dependentCount(for nodeId: String) -> Int {
        edges.filter { $0.from == nodeId }.count
    }
}

// MARK: - Dependency Node

extension DependencyGraph {
    public struct DependencyNode: Codable, Hashable, Identifiable {
        public let id: String
        public let name: String
        public let type: NodeType
        public let external: Bool
        public let optional: Bool
        public let metadata: NodeMetadata?

        public enum NodeType: String, Codable {
            case feature = "Feature"
            case service = "Service"
            case infrastructure = "Infrastructure"
            case library = "Library"
            case api = "API"
            case database = "Database"
            case configuration = "Configuration"
        }

        public struct NodeMetadata: Codable, Hashable {
            public let version: String?
            public let provider: String?
            public let criticalityLevel: Int // 1-5
            public let estimatedSetupComplexity: Int // Story points
        }

        public init(
            id: String,
            name: String,
            type: NodeType,
            external: Bool = false,
            optional: Bool = false,
            metadata: NodeMetadata? = nil
        ) {
            self.id = id
            self.name = name
            self.type = type
            self.external = external
            self.optional = optional
            self.metadata = metadata
        }
    }
}

// MARK: - Dependency Edge

extension DependencyGraph {
    public struct DependencyEdge: Codable, Identifiable {
        public let id: UUID
        public let from: String
        public let to: String
        public let type: EdgeType
        public let strength: Strength

        public enum EdgeType: String, Codable {
            case requires = "Requires"
            case uses = "Uses"
            case extends = "Extends"
            case implements = "Implements"
            case optionallyUses = "Optionally Uses"
        }

        public enum Strength: String, Codable {
            case strong = "Strong"    // Cannot function without
            case moderate = "Moderate" // Degraded functionality without
            case weak = "Weak"        // Nice to have
        }

        public init(
            id: UUID = UUID(),
            from: String,
            to: String,
            type: EdgeType,
            strength: Strength = .strong
        ) {
            self.id = id
            self.from = from
            self.to = to
            self.type = type
            self.strength = strength
        }
    }
}

// MARK: - Dependency Cycle

extension DependencyGraph {
    public struct DependencyCycle: Codable {
        public let nodes: [String]
        public let severity: Severity
        public let impact: String
        public let suggestedBreakpoint: String?

        public enum Severity: String, Codable {
            case warning = "Warning"   // Can work but not ideal
            case error = "Error"       // Will cause problems
            case critical = "Critical" // Cannot work at all

            public var icon: String {
                switch self {
                case .warning: return "⚠️"
                case .error: return "❌"
                case .critical: return "🚨"
                }
            }
        }

        public init(
            nodes: [String],
            severity: Severity,
            impact: String,
            suggestedBreakpoint: String? = nil
        ) {
            self.nodes = nodes
            self.severity = severity
            self.impact = impact
            self.suggestedBreakpoint = suggestedBreakpoint
        }

        public var cycleDescription: String {
            nodes.joined(separator: " → ") + " → " + (nodes.first ?? "")
        }
    }
}