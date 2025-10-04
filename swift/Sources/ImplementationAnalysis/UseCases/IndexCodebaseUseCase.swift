import Foundation

/// Use case for indexing a codebase: parsing files, creating chunks, and generating embeddings
/// Follows Clean Architecture - orchestrates domain logic without implementation details
public struct IndexCodebaseUseCase {
    private let repository: CodebaseRepositoryProtocol
    private let embeddingGenerator: EmbeddingGeneratorPort
    private let parserFactory: CodeParserFactory

    public init(
        repository: CodebaseRepositoryProtocol,
        embeddingGenerator: EmbeddingGeneratorPort,
        parserFactory: CodeParserFactory
    ) {
        self.repository = repository
        self.embeddingGenerator = embeddingGenerator
        self.parserFactory = parserFactory
    }

    public struct Input {
        public let projectId: UUID
        public let files: [CodeFileInput]
        public let batchSize: Int

        public init(
            projectId: UUID,
            files: [CodeFileInput],
            batchSize: Int = 50
        ) {
            self.projectId = projectId
            self.files = files
            self.batchSize = batchSize
        }
    }

    public struct CodeFileInput {
        public let filePath: String
        public let content: String
        public let fileHash: String
        public let fileSize: Int

        public init(filePath: String, content: String, fileHash: String, fileSize: Int) {
            self.filePath = filePath
            self.content = content
            self.fileHash = fileHash
            self.fileSize = fileSize
        }
    }

    public struct Output {
        public let totalFiles: Int
        public let totalChunks: Int
        public let totalEmbeddings: Int
        public let processedFiles: [UUID]
        public let failedFiles: [(filePath: String, error: String)]

        public init(
            totalFiles: Int,
            totalChunks: Int,
            totalEmbeddings: Int,
            processedFiles: [UUID],
            failedFiles: [(filePath: String, error: String)]
        ) {
            self.totalFiles = totalFiles
            self.totalChunks = totalChunks
            self.totalEmbeddings = totalEmbeddings
            self.processedFiles = processedFiles
            self.failedFiles = failedFiles
        }
    }

    public func execute(_ input: Input) async throws -> Output {
        var allChunks: [CodeChunk] = []
        var processedFiles: [UUID] = []
        var failedFiles: [(filePath: String, error: String)] = []

        // Step 1: Save files to repository
        let codeFiles = input.files.map { fileInput in
            let language = ProgrammingLanguage.from(extension: (fileInput.filePath as NSString).pathExtension)
            return CodeFile(
                codebaseProjectId: input.projectId,
                filePath: fileInput.filePath,
                fileHash: fileInput.fileHash,
                fileSize: fileInput.fileSize,
                language: language,
                isParsed: false
            )
        }

        let savedFiles = try await repository.saveFiles(codeFiles, projectId: input.projectId)

        // Step 2: Parse each file and create chunks
        for (index, savedFile) in savedFiles.enumerated() {
            guard index < input.files.count else { continue }

            do {
                let fileInput = input.files[index]

                // Get appropriate parser for the language
                guard let parser = parserFactory.parser(for: savedFile.language ?? .swift) else {
                    failedFiles.append((fileInput.filePath, "No parser available for language"))
                    continue
                }

                // Parse file into chunks
                let parsedChunks = try await parser.parseCode(fileInput.content, filePath: fileInput.filePath)

                // Convert ParsedCodeChunk to CodeChunk (domain model)
                let codeChunks = parsedChunks.map { parsed -> CodeChunk in
                    // Extract symbols from content if symbolName is present
                    let symbols = parsed.symbolName.map { [$0] } ?? []

                    // Extract imports (parser specific - for now use basic extraction)
                    let imports = extractImports(from: parsed.content, language: savedFile.language ?? .swift)

                    return CodeChunk(
                        codebaseProjectId: input.projectId,
                        fileId: savedFile.id,
                        filePath: savedFile.filePath,
                        startLine: parsed.startLine,
                        endLine: parsed.endLine,
                        content: parsed.content,
                        contentHash: CodeChunk.calculateHash(content: parsed.content),
                        chunkType: parsed.chunkType,
                        language: savedFile.language ?? .swift,
                        symbols: symbols,
                        imports: imports,
                        tokenCount: parsed.tokenCount
                    )
                }

                allChunks.append(contentsOf: codeChunks)
                processedFiles.append(savedFile.id)

                // Mark file as parsed
                try await repository.updateFileParsed(fileId: savedFile.id, isParsed: true, error: nil)
            } catch {
                failedFiles.append((savedFiles[index].filePath, error.localizedDescription))
                try? await repository.updateFileParsed(fileId: savedFiles[index].id, isParsed: false, error: error.localizedDescription)
            }
        }

        // Step 3: Save chunks in batches
        var savedChunks: [CodeChunk] = []
        for chunkBatch in allChunks.chunked(into: input.batchSize) {
            let saved = try await repository.saveChunks(chunkBatch, projectId: input.projectId)
            savedChunks.append(contentsOf: saved)
        }

        // Step 4: Generate embeddings for chunks in batches
        var totalEmbeddings = 0
        for chunkBatch in savedChunks.chunked(into: input.batchSize) {
            // Generate embeddings
            let texts = chunkBatch.map { $0.content }
            let embeddings = try await embeddingGenerator.generateEmbeddings(texts: texts)

            // Create CodeEmbedding objects
            let codeEmbeddings = zip(chunkBatch, embeddings).map { chunk, embedding in
                CodeEmbedding(
                    chunkId: chunk.id,
                    codebaseProjectId: input.projectId,
                    embedding: embedding,
                    model: embeddingGenerator.modelName,
                    embeddingVersion: 1
                )
            }

            // Save embeddings
            try await repository.saveEmbeddings(codeEmbeddings, projectId: input.projectId)
            totalEmbeddings += codeEmbeddings.count
        }

        return Output(
            totalFiles: savedFiles.count,
            totalChunks: savedChunks.count,
            totalEmbeddings: totalEmbeddings,
            processedFiles: processedFiles,
            failedFiles: failedFiles
        )
    }

    // MARK: - Helper Methods

    private func extractImports(from content: String, language: ProgrammingLanguage) -> [String] {
        let lines = content.components(separatedBy: .newlines)
        var imports: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            switch language {
            case .swift:
                if trimmed.hasPrefix("import ") {
                    imports.append(String(trimmed.dropFirst(7)).trimmingCharacters(in: .whitespaces))
                }
            case .typescript, .javascript:
                if trimmed.hasPrefix("import ") || trimmed.hasPrefix("from ") {
                    imports.append(trimmed)
                }
            case .python:
                if trimmed.hasPrefix("import ") || trimmed.hasPrefix("from ") {
                    imports.append(trimmed)
                }
            default:
                break
            }
        }

        return imports
    }
}

// MARK: - Array Extension for Chunking

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

/// Factory for creating language-specific code parsers
/// Follows Open/Closed Principle - new parsers can be added without modifying existing code
public struct CodeParserFactory {
    private let parsers: [ProgrammingLanguage: CodeParserPort]

    public init() {
        self.parsers = [
            .swift: SwiftCodeParser(),
            .typescript: TypeScriptCodeParser(),
            .python: PythonCodeParser()
        ]
    }

    public init(customParsers: [ProgrammingLanguage: CodeParserPort]) {
        self.parsers = customParsers
    }

    public func parser(for language: ProgrammingLanguage) -> CodeParserPort? {
        return parsers[language]
    }

    public func supportedLanguages() -> [ProgrammingLanguage] {
        return Array(parsers.keys)
    }
}
