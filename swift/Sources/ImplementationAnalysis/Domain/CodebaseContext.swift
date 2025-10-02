import Foundation

// MARK: - Codebase Project

/// Represents an indexed codebase project
public struct CodebaseProject {
    public let id: UUID
    public let repositoryUrl: String
    public let repositoryBranch: String
    public let repositoryType: RepositoryType

    // Indexing metadata
    public let merkleRootHash: String?
    public let totalFiles: Int
    public let indexedFiles: Int
    public let totalChunks: Int

    // Status
    public let indexingStatus: IndexingStatus
    public let indexingProgress: Int  // 0-100
    public let lastIndexedAt: Date?

    // Tech stack detection
    public let detectedLanguages: [String: Int]  // {"Swift": 45, "TypeScript": 30}
    public let detectedFrameworks: [String]
    public let architecturePatterns: [ArchitecturePattern]

    // Timestamps
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        repositoryUrl: String,
        repositoryBranch: String = "main",
        repositoryType: RepositoryType = .github,
        merkleRootHash: String? = nil,
        totalFiles: Int = 0,
        indexedFiles: Int = 0,
        totalChunks: Int = 0,
        indexingStatus: IndexingStatus = .pending,
        indexingProgress: Int = 0,
        lastIndexedAt: Date? = nil,
        detectedLanguages: [String: Int] = [:],
        detectedFrameworks: [String] = [],
        architecturePatterns: [ArchitecturePattern] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.repositoryUrl = repositoryUrl
        self.repositoryBranch = repositoryBranch
        self.repositoryType = repositoryType
        self.merkleRootHash = merkleRootHash
        self.totalFiles = totalFiles
        self.indexedFiles = indexedFiles
        self.totalChunks = totalChunks
        self.indexingStatus = indexingStatus
        self.indexingProgress = indexingProgress
        self.lastIndexedAt = lastIndexedAt
        self.detectedLanguages = detectedLanguages
        self.detectedFrameworks = detectedFrameworks
        self.architecturePatterns = architecturePatterns
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Repository Type

public enum RepositoryType: String, Codable {
    case github
    case gitlab
    case bitbucket
}

// MARK: - Indexing Status

public enum IndexingStatus: String, Codable {
    case pending
    case indexing
    case completed
    case failed
}

// MARK: - Architecture Pattern

public struct ArchitecturePattern: Codable {
    public let name: String  // "Clean Architecture", "MVVM", "MVI"
    public let confidence: Double  // 0.0-1.0
    public let evidence: [String]  // File paths that indicate this pattern

    public init(name: String, confidence: Double, evidence: [String]) {
        self.name = name
        self.confidence = confidence
        self.evidence = evidence
    }
}

// MARK: - Code File

/// Represents a file in the codebase
public struct CodeFile {
    public let id: UUID
    public let codebaseProjectId: UUID
    public let filePath: String
    public let fileHash: String  // SHA-256
    public let fileSize: Int
    public let language: ProgrammingLanguage?
    public let isParsed: Bool
    public let parseError: String?
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        codebaseProjectId: UUID,
        filePath: String,
        fileHash: String,
        fileSize: Int,
        language: ProgrammingLanguage? = nil,
        isParsed: Bool = false,
        parseError: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.codebaseProjectId = codebaseProjectId
        self.filePath = filePath
        self.fileHash = fileHash
        self.fileSize = fileSize
        self.language = language
        self.isParsed = isParsed
        self.parseError = parseError
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Programming Language

public enum ProgrammingLanguage: String, Codable {
    case swift
    case kotlin
    case java
    case typescript
    case javascript
    case python
    case go
    case rust
    case cpp = "cpp"
    case c = "c"
    case objc = "objc"
    case ruby
    case php
    case csharp = "csharp"
    case html
    case css
    case markdown = "markdown"
    case json
    case yaml
    case xml

    public var fileExtensions: [String] {
        switch self {
        case .swift: return ["swift"]
        case .kotlin: return ["kt", "kts"]
        case .java: return ["java"]
        case .typescript: return ["ts", "tsx"]
        case .javascript: return ["js", "jsx", "mjs"]
        case .python: return ["py"]
        case .go: return ["go"]
        case .rust: return ["rs"]
        case .cpp: return ["cpp", "cc", "cxx", "hpp", "hh", "hxx"]
        case .c: return ["c", "h"]
        case .objc: return ["m", "mm"]
        case .ruby: return ["rb"]
        case .php: return ["php"]
        case .csharp: return ["cs"]
        case .html: return ["html", "htm"]
        case .css: return ["css", "scss", "sass", "less"]
        case .markdown: return ["md", "markdown"]
        case .json: return ["json"]
        case .yaml: return ["yaml", "yml"]
        case .xml: return ["xml"]
        }
    }

    /// Detect language from file extension
    public static func from(extension ext: String) -> ProgrammingLanguage? {
        let lowercased = ext.lowercased()
        for language in ProgrammingLanguage.allCases {
            if language.fileExtensions.contains(lowercased) {
                return language
            }
        }
        return nil
    }
}

extension ProgrammingLanguage: CaseIterable {}

// MARK: - Code Chunk

/// Represents a parsed code chunk (function, class, module)
public struct CodeChunk {
    public let id: UUID
    public let codebaseProjectId: UUID
    public let fileId: UUID
    public let filePath: String
    public let startLine: Int
    public let endLine: Int
    public let content: String
    public let contentHash: String  // SHA-256 for deduplication
    public let chunkType: ChunkType
    public let language: ProgrammingLanguage
    public let symbols: [String]  // Function names, class names
    public let imports: [String]  // Dependencies
    public let tokenCount: Int
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        codebaseProjectId: UUID,
        fileId: UUID,
        filePath: String,
        startLine: Int,
        endLine: Int,
        content: String,
        contentHash: String,
        chunkType: ChunkType,
        language: ProgrammingLanguage,
        symbols: [String] = [],
        imports: [String] = [],
        tokenCount: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.codebaseProjectId = codebaseProjectId
        self.fileId = fileId
        self.filePath = filePath
        self.startLine = startLine
        self.endLine = endLine
        self.content = content
        self.contentHash = contentHash
        self.chunkType = chunkType
        self.language = language
        self.symbols = symbols
        self.imports = imports
        self.tokenCount = tokenCount
        self.createdAt = createdAt
    }

    /// Calculate content hash
    public static func calculateHash(content: String) -> String {
        return content.sha256Hash
    }
}

// MARK: - Chunk Type

public enum ChunkType: String, Codable {
    case function
    case `class`
    case `struct`
    case `enum`
    case `interface`
    case module
    case comment
    case declaration
    case other
}

// MARK: - Code Embedding

/// Represents a vector embedding for a code chunk
public struct CodeEmbedding {
    public let id: UUID
    public let chunkId: UUID
    public let codebaseProjectId: UUID
    public let embedding: [Float]  // 1536 dimensions
    public let model: String
    public let embeddingVersion: Int
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        chunkId: UUID,
        codebaseProjectId: UUID,
        embedding: [Float],
        model: String = "text-embedding-3-small",
        embeddingVersion: Int = 1,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.chunkId = chunkId
        self.codebaseProjectId = codebaseProjectId
        self.embedding = embedding
        self.model = model
        self.embeddingVersion = embeddingVersion
        self.createdAt = createdAt
    }
}

// MARK: - Similar Code Chunk

/// Result from similarity search
public struct SimilarCodeChunk {
    public let chunk: CodeChunk
    public let similarity: Double  // 0.0-1.0

    public init(chunk: CodeChunk, similarity: Double) {
        self.chunk = chunk
        self.similarity = similarity
    }
}

// NOTE: MerkleNode is now defined in MerkleTree.swift to avoid duplication

// MARK: - String Extensions

extension String {
    /// Calculate SHA-256 hash
    var sha256Hash: String {
        guard let data = self.data(using: .utf8) else { return "" }

        let hash = data.withUnsafeBytes { buffer in
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &digest)
            return digest
        }

        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

import CommonCrypto
