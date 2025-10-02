import Foundation

/// Protocol for codebase repository - defines the contract for codebase data persistence
/// Following Interface Segregation Principle with focused methods
public protocol CodebaseRepositoryProtocol: Sendable {
    // MARK: - Codebase Project Operations

    /// Save a new codebase project
    func saveProject(_ project: CodebaseProject) async throws -> CodebaseProject

    /// Find codebase project by ID
    func findProjectById(_ id: UUID) async throws -> CodebaseProject?

    /// Find codebase project by repository URL and branch
    func findProjectByRepository(url: String, branch: String) async throws -> CodebaseProject?

    /// Update codebase project
    func updateProject(_ project: CodebaseProject) async throws -> CodebaseProject

    /// Delete codebase project and all related data
    func deleteProject(_ id: UUID) async throws

    /// List all codebase projects (paginated)
    func listProjects(limit: Int, offset: Int) async throws -> [CodebaseProject]

    /// Create a new codebase
    func createCodebase(_ codebase: Codebase) async throws -> Codebase

    /// Get codebase by ID
    func getCodebase(by id: UUID) async throws -> Codebase?

    /// List all codebases for a user
    func listCodebases(forUser userId: UUID) async throws -> [Codebase]

    // MARK: - Code File Operations

    /// Save multiple code files (batch operation)
    func saveFiles(_ files: [CodeFile], projectId: UUID) async throws -> [CodeFile]

    /// Add a single file (convenience method)
    func addFile(_ file: CodeFile) async throws -> CodeFile

    /// Find files by project ID
    func findFilesByProject(_ projectId: UUID) async throws -> [CodeFile]

    /// Find file by path within a project
    func findFile(projectId: UUID, path: String) async throws -> CodeFile?

    /// Update file parse status
    func updateFileParsed(fileId: UUID, isParsed: Bool, error: String?) async throws

    // MARK: - Code Chunk Operations

    /// Save multiple code chunks (batch operation)
    func saveChunks(_ chunks: [CodeChunk], projectId: UUID) async throws -> [CodeChunk]

    /// Find chunks by project ID (paginated)
    func findChunksByProject(_ projectId: UUID, limit: Int, offset: Int) async throws -> [CodeChunk]

    /// Find chunks by file ID
    func findChunksByFile(_ fileId: UUID) async throws -> [CodeChunk]

    /// Delete chunks by project ID (for re-indexing)
    func deleteChunksByProject(_ projectId: UUID) async throws

    // MARK: - Code Embedding Operations

    /// Save multiple embeddings (batch operation)
    func saveEmbeddings(_ embeddings: [CodeEmbedding], projectId: UUID) async throws

    /// Find similar code chunks using vector similarity search
    func findSimilarChunks(
        projectId: UUID,
        queryEmbedding: [Float],
        limit: Int,
        similarityThreshold: Float
    ) async throws -> [SimilarCodeChunk]

    /// Search files using semantic similarity
    func searchFiles(
        in codebaseId: UUID,
        embedding: [Float],
        limit: Int,
        similarityThreshold: Float?
    ) async throws -> [(file: CodeFile, similarity: Float)]

    // MARK: - Merkle Tree Operations

    /// Save Merkle tree root hash
    func saveMerkleRoot(projectId: UUID, rootHash: String) async throws

    /// Get Merkle tree root hash
    func getMerkleRoot(projectId: UUID) async throws -> String?

    /// Save Merkle tree nodes (for change tracking)
    func saveMerkleNodes(_ nodes: [MerkleNode], projectId: UUID) async throws

    /// Get all Merkle nodes for a project (to rebuild tree)
    func getMerkleNodes(projectId: UUID) async throws -> [MerkleNode]
}

/// Protocol for linking PRD requests to codebase projects
public protocol PRDCodebaseLink: Sendable {
    /// Link a PRD request to a codebase project
    func linkPRDToCodebase(prdRequestId: UUID, codebaseProjectId: UUID) async throws

    /// Link a codebase to a PRD (alternative naming)
    func linkCodebaseToPRD(prdId: UUID, codebaseId: UUID) async throws

    /// Get codebase project linked to a PRD request
    func getCodebaseForPRD(prdRequestId: UUID) async throws -> CodebaseProject?

    /// Unlink PRD from codebase
    func unlinkPRDFromCodebase(prdRequestId: UUID, codebaseProjectId: UUID) async throws
}
