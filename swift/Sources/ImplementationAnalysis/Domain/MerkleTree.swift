import Foundation

// MARK: - Merkle Tree

/// Merkle tree for efficient incremental change detection
/// Used to quickly identify which files have changed without re-scanning entire codebase
public struct MerkleTree: Sendable {
    public let rootHash: String
    public let nodes: [String: MerkleNode]  // Hash -> Node

    public init(rootHash: String, nodes: [String: MerkleNode]) {
        self.rootHash = rootHash
        self.nodes = nodes
    }

    /// Build a Merkle tree from a list of files
    public static func build(from files: [GitHubFileNode]) -> MerkleTree {
        guard !files.isEmpty else {
            return MerkleTree(rootHash: "empty", nodes: [:])
        }

        var nodes: [String: MerkleNode] = [:]

        // 1. Create leaf nodes (one per file)
        var currentLevel = files.map { file in
            let hash = file.sha  // Use GitHub's provided SHA
            let node = MerkleNode(
                hash: hash,
                path: file.path,
                isLeaf: true,
                fileId: nil,  // Will be set after file creation
                children: []
            )
            nodes[hash] = node
            return node
        }

        // 2. Build tree bottom-up until we reach the root
        while currentLevel.count > 1 {
            var nextLevel: [MerkleNode] = []

            // Process pairs of nodes
            for i in stride(from: 0, to: currentLevel.count, by: 2) {
                let left = currentLevel[i]
                let right = i + 1 < currentLevel.count ? currentLevel[i + 1] : left

                // Combine hashes to create parent
                let combinedHash = (left.hash + right.hash).sha256Hash
                let combinedPath = "\(left.path)_\(right.path)"

                let parent = MerkleNode(
                    hash: combinedHash,
                    path: combinedPath,
                    isLeaf: false,
                    fileId: nil,
                    children: [left, right]
                )

                nodes[combinedHash] = parent
                nextLevel.append(parent)
            }

            currentLevel = nextLevel
        }

        // Root is the only node left
        let root = currentLevel.first!
        return MerkleTree(rootHash: root.hash, nodes: nodes)
    }

    /// Find files that have changed by comparing this tree with another
    /// Returns paths of changed files
    public func diff(other: MerkleTree) -> [String] {
        // If root hashes match, nothing changed
        guard rootHash != other.rootHash else {
            return []
        }

        var changedFiles: [String] = []

        // Traverse both trees to find differences
        func traverse(currentHash: String, otherHash: String?) {
            // If hashes match, no change in this subtree
            guard currentHash != otherHash else { return }

            // Get nodes
            guard let currentNode = nodes[currentHash] else { return }
            let otherNode = otherHash.flatMap { other.nodes[$0] }

            // If leaf node, it's a changed file
            if currentNode.isLeaf {
                changedFiles.append(currentNode.path)
                return
            }

            // Not a leaf, check children
            for (index, child) in currentNode.children.enumerated() {
                let otherChild = otherNode?.children[safe: index]
                traverse(currentHash: child.hash, otherHash: otherChild?.hash)
            }
        }

        traverse(currentHash: rootHash, otherHash: other.rootHash)

        return changedFiles
    }

    /// Find new files that don't exist in the other tree
    public func findNewFiles(comparedTo other: MerkleTree) -> [String] {
        let currentFiles = Set(getAllFilePaths())
        let otherFiles = Set(other.getAllFilePaths())
        return Array(currentFiles.subtracting(otherFiles))
    }

    /// Find deleted files that exist in other tree but not in this one
    public func findDeletedFiles(comparedTo other: MerkleTree) -> [String] {
        let currentFiles = Set(getAllFilePaths())
        let otherFiles = Set(other.getAllFilePaths())
        return Array(otherFiles.subtracting(currentFiles))
    }

    /// Get all file paths in this tree
    private func getAllFilePaths() -> [String] {
        nodes.values
            .filter { $0.isLeaf }
            .map { $0.path }
    }

    /// Calculate tree statistics
    public var statistics: TreeStatistics {
        let leafNodes = nodes.values.filter { $0.isLeaf }
        let internalNodes = nodes.values.filter { !$0.isLeaf }

        return TreeStatistics(
            totalNodes: nodes.count,
            leafNodes: leafNodes.count,
            internalNodes: internalNodes.count,
            treeHeight: calculateHeight()
        )
    }

    /// Calculate tree height
    private func calculateHeight() -> Int {
        guard let root = nodes[rootHash] else { return 0 }

        func height(of node: MerkleNode) -> Int {
            if node.isLeaf { return 0 }
            let childHeights = node.children.map { height(of: $0) }
            return (childHeights.max() ?? 0) + 1
        }

        return height(of: root)
    }
}

// MARK: - Merkle Node

/// A node in the Merkle tree
public struct MerkleNode: Sendable {
    public let hash: String
    public let path: String
    public let isLeaf: Bool
    public let fileId: UUID?  // Only set for leaf nodes
    public let children: [MerkleNode]

    public init(
        hash: String,
        path: String,
        isLeaf: Bool,
        fileId: UUID?,
        children: [MerkleNode]
    ) {
        self.hash = hash
        self.path = path
        self.isLeaf = isLeaf
        self.fileId = fileId
        self.children = children
    }
}

// MARK: - Tree Statistics

public struct TreeStatistics: Sendable {
    public let totalNodes: Int
    public let leafNodes: Int
    public let internalNodes: Int
    public let treeHeight: Int

    public init(
        totalNodes: Int,
        leafNodes: Int,
        internalNodes: Int,
        treeHeight: Int
    ) {
        self.totalNodes = totalNodes
        self.leafNodes = leafNodes
        self.internalNodes = internalNodes
        self.treeHeight = treeHeight
    }

    /// Theoretical maximum comparisons needed = O(log n)
    public var maxComparisons: Int {
        return treeHeight + 1
    }
}

// MARK: - GitHub File Node

/// Represents a file from GitHub's tree API
public struct GitHubFileNode: Sendable {
    public let path: String
    public let mode: String  // File permissions
    public let type: GitHubFileType
    public let sha: String  // Git object SHA
    public let size: Int?
    public let url: String

    public init(
        path: String,
        mode: String,
        type: GitHubFileType,
        sha: String,
        size: Int?,
        url: String
    ) {
        self.path = path
        self.mode = mode
        self.type = type
        self.sha = sha
        self.size = size
        self.url = url
    }
}

public enum GitHubFileType: String, Codable, Sendable {
    case blob  // File
    case tree  // Directory
}

// MARK: - Change Detection Result

/// Result of comparing two Merkle trees
public struct ChangeDetectionResult: Sendable {
    public let changedFiles: [String]
    public let newFiles: [String]
    public let deletedFiles: [String]
    public let unchangedFiles: Int

    public init(
        changedFiles: [String],
        newFiles: [String],
        deletedFiles: [String],
        unchangedFiles: Int
    ) {
        self.changedFiles = changedFiles
        self.newFiles = newFiles
        self.deletedFiles = deletedFiles
        self.unchangedFiles = unchangedFiles
    }

    /// Total number of files that need processing
    public var filesToProcess: Int {
        return changedFiles.count + newFiles.count
    }

    /// Files that can be skipped (unchanged)
    public var filesSkipped: Int {
        return unchangedFiles
    }

    /// Efficiency ratio (0-1)
    public var efficiencyRatio: Double {
        let total = filesToProcess + filesSkipped
        guard total > 0 else { return 0 }
        return Double(filesSkipped) / Double(total)
    }
}

// MARK: - Helper Extensions

extension Array {
    /// Safe array subscripting
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
