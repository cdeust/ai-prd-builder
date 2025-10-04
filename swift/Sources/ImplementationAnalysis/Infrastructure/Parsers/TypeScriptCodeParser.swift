import Foundation

/// TypeScript/JavaScript code parser with regex-based symbol extraction
/// Handles modern JS/TS syntax including classes, functions, arrow functions, etc.
public final class TypeScriptCodeParser: CodeParserPort, @unchecked Sendable {
    public let supportedLanguage: ProgrammingLanguage

    private let maxFileSize: Int
    private let maxChunkTokens: Int

    public init(
        language: ProgrammingLanguage = .typescript,
        maxFileSize: Int = 1_000_000,
        maxChunkTokens: Int = 1000
    ) {
        self.supportedLanguage = language
        self.maxFileSize = maxFileSize
        self.maxChunkTokens = maxChunkTokens
    }

    public func parseCode(_ code: String, filePath: String) async throws -> [ParsedCodeChunk] {
        guard code.utf8.count <= maxFileSize else {
            throw CodeParsingError.fileTooLarge(maxSize: maxFileSize)
        }

        let lines = code.components(separatedBy: .newlines)
        var chunks: [ParsedCodeChunk] = []

        // Extract symbols
        let symbols = try await extractSymbols(code, filePath: filePath)

        // Create chunks from symbols
        for symbol in symbols {
            let symbolLines = Array(lines[symbol.startLine - 1..<min(symbol.endLine, lines.count)])
            let content = symbolLines.joined(separator: "\n")
            let tokenCount = estimateTokenCount(content)

            if tokenCount > maxChunkTokens {
                let subChunks = splitLargeChunk(
                    content: content,
                    startLine: symbol.startLine,
                    chunkType: mapSymbolTypeToChunkType(symbol.symbolType),
                    symbolName: symbol.name
                )
                chunks.append(contentsOf: subChunks)
            } else {
                chunks.append(ParsedCodeChunk(
                    content: content,
                    startLine: symbol.startLine,
                    endLine: symbol.endLine,
                    chunkType: mapSymbolTypeToChunkType(symbol.symbolType),
                    symbolName: symbol.name,
                    tokenCount: tokenCount,
                    context: symbol.documentation
                ))
            }
        }

        // Extract imports and comments
        chunks.append(contentsOf: extractImports(from: lines))
        chunks.append(contentsOf: extractComments(from: lines))

        return chunks.sorted { $0.startLine < $1.startLine }
    }

    public func extractSymbols(_ code: String, filePath: String) async throws -> [CodeSymbol] {
        var symbols: [CodeSymbol] = []

        symbols.append(contentsOf: extractClasses(from: code))
        symbols.append(contentsOf: extractInterfaces(from: code))
        symbols.append(contentsOf: extractFunctions(from: code))
        symbols.append(contentsOf: extractArrowFunctions(from: code))
        symbols.append(contentsOf: extractTypes(from: code))
        symbols.append(contentsOf: extractEnums(from: code))

        return symbols.sorted { $0.startLine < $1.startLine }
    }

    public func estimateTokenCount(_ code: String) -> Int {
        return code.count / 4
    }

    // MARK: - Private Extraction Methods

    private func extractClasses(from code: String) -> [CodeSymbol] {
        let pattern = #"""
        (?:/\*\*[^*]*\*+(?:[^/*][^*]*\*+)*/\s*)?(?:export\s+)?(?:abstract\s+)?class\s+(\w+)(?:<[^>]+>)?(?:\s+extends\s+\w+)?(?:\s+implements\s+[^\{]+)?\s*\{
        """#

        return extractSymbolsWithPattern(
            pattern: pattern,
            code: code,
            symbolType: .class,
            nameGroupIndex: 1
        )
    }

    private func extractInterfaces(from code: String) -> [CodeSymbol] {
        let pattern = #"""
        (?:/\*\*[^*]*\*+(?:[^/*][^*]*\*+)*/\s*)?(?:export\s+)?interface\s+(\w+)(?:<[^>]+>)?(?:\s+extends\s+[^\{]+)?\s*\{
        """#

        return extractSymbolsWithPattern(
            pattern: pattern,
            code: code,
            symbolType: .interface,
            nameGroupIndex: 1
        )
    }

    private func extractFunctions(from code: String) -> [CodeSymbol] {
        let pattern = #"""
        (?:/\*\*[^*]*\*+(?:[^/*][^*]*\*+)*/\s*)?(?:export\s+)?(?:async\s+)?function\s+(\w+)\s*(?:<[^>]+>)?\s*\([^\)]*\)(?:\s*:\s*[^\{]+)?\s*\{
        """#

        return extractSymbolsWithPattern(
            pattern: pattern,
            code: code,
            symbolType: .function,
            nameGroupIndex: 1
        )
    }

    private func extractArrowFunctions(from code: String) -> [CodeSymbol] {
        let pattern = #"""
        (?:/\*\*[^*]*\*+(?:[^/*][^*]*\*+)*/\s*)?(?:export\s+)?(?:const|let|var)\s+(\w+)\s*(?::\s*[^=]+)?\s*=\s*(?:async\s*)?\([^\)]*\)\s*=>\s*\{
        """#

        return extractSymbolsWithPattern(
            pattern: pattern,
            code: code,
            symbolType: .function,
            nameGroupIndex: 1
        )
    }

    private func extractTypes(from code: String) -> [CodeSymbol] {
        let pattern = #"""
        (?:export\s+)?type\s+(\w+)(?:<[^>]+>)?\s*=
        """#

        return extractSymbolsWithPattern(
            pattern: pattern,
            code: code,
            symbolType: .type,
            nameGroupIndex: 1
        )
    }

    private func extractEnums(from code: String) -> [CodeSymbol] {
        let pattern = #"""
        (?:export\s+)?(?:const\s+)?enum\s+(\w+)\s*\{
        """#

        return extractSymbolsWithPattern(
            pattern: pattern,
            code: code,
            symbolType: .enum,
            nameGroupIndex: 1
        )
    }

    private func extractSymbolsWithPattern(
        pattern: String,
        code: String,
        symbolType: SymbolType,
        nameGroupIndex: Int
    ) -> [CodeSymbol] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return []
        }

        let nsString = code as NSString
        let matches = regex.matches(in: code, range: NSRange(location: 0, length: nsString.length))

        return matches.compactMap { match -> CodeSymbol? in
            guard match.numberOfRanges > nameGroupIndex,
                  match.range(at: nameGroupIndex).location != NSNotFound else {
                return nil
            }

            let nameRange = match.range(at: nameGroupIndex)
            let name = nsString.substring(with: nameRange)

            let matchRange = match.range
            let beforeMatch = nsString.substring(to: matchRange.location)
            let startLine = beforeMatch.components(separatedBy: .newlines).count

            let endLine = findClosingBrace(in: code, startingAt: matchRange.location + matchRange.length)
            let documentation = extractJSDoc(before: matchRange.location, in: code)

            return CodeSymbol(
                name: name,
                symbolType: symbolType,
                startLine: startLine,
                endLine: endLine ?? startLine + 10,
                signature: nsString.substring(with: matchRange),
                documentation: documentation,
                modifiers: []
            )
        }
    }

    private func findClosingBrace(in code: String, startingAt offset: Int) -> Int? {
        var braceCount = 1
        var currentLine = code.prefix(offset).components(separatedBy: .newlines).count

        let remainingCode = String(code.dropFirst(offset))
        for char in remainingCode {
            if char == "{" {
                braceCount += 1
            } else if char == "}" {
                braceCount -= 1
                if braceCount == 0 {
                    return currentLine
                }
            } else if char == "\n" {
                currentLine += 1
            }
        }

        return nil
    }

    private func extractJSDoc(before offset: Int, in code: String) -> String? {
        let beforeCode = String(code.prefix(offset))

        // Match JSDoc comment: /** ... */
        let pattern = #"/\*\*([^*]*\*+(?:[^/*][^*]*\*+)*)/\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: beforeCode, range: NSRange(location: 0, length: beforeCode.utf16.count)),
              match.numberOfRanges > 1 else {
            return nil
        }

        let nsString = beforeCode as NSString
        let docRange = match.range(at: 1)
        let docString = nsString.substring(with: docRange)

        // Clean up JSDoc formatting
        let cleaned = docString
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .map { $0.hasPrefix("*") ? String($0.dropFirst()).trimmingCharacters(in: .whitespaces) : $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return cleaned.isEmpty ? nil : cleaned
    }

    private func extractImports(from lines: [String]) -> [ParsedCodeChunk] {
        var chunks: [ParsedCodeChunk] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("import ") || trimmed.hasPrefix("export ") {
                chunks.append(ParsedCodeChunk(
                    content: trimmed,
                    startLine: index + 1,
                    endLine: index + 1,
                    chunkType: .import,
                    symbolName: nil,
                    tokenCount: estimateTokenCount(trimmed)
                ))
            }
        }

        return chunks
    }

    private func extractComments(from lines: [String]) -> [ParsedCodeChunk] {
        var chunks: [ParsedCodeChunk] = []
        var currentCommentLines: [Int] = []
        var currentCommentContent: [String] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("//") {
                currentCommentLines.append(index + 1)
                currentCommentContent.append(trimmed)
            } else if !currentCommentLines.isEmpty {
                let content = currentCommentContent.joined(separator: "\n")
                if estimateTokenCount(content) > 50 {
                    chunks.append(ParsedCodeChunk(
                        content: content,
                        startLine: currentCommentLines.first!,
                        endLine: currentCommentLines.last!,
                        chunkType: .comment,
                        symbolName: nil,
                        tokenCount: estimateTokenCount(content)
                    ))
                }
                currentCommentLines = []
                currentCommentContent = []
            }
        }

        return chunks
    }

    private func splitLargeChunk(
        content: String,
        startLine: Int,
        chunkType: ChunkType,
        symbolName: String?
    ) -> [ParsedCodeChunk] {
        let lines = content.components(separatedBy: .newlines)
        var chunks: [ParsedCodeChunk] = []
        var currentChunk: [String] = []
        var currentStartLine = startLine
        var currentTokenCount = 0

        for (offset, line) in lines.enumerated() {
            let lineTokenCount = estimateTokenCount(line)

            if currentTokenCount + lineTokenCount > maxChunkTokens && !currentChunk.isEmpty {
                let chunkContent = currentChunk.joined(separator: "\n")
                chunks.append(ParsedCodeChunk(
                    content: chunkContent,
                    startLine: currentStartLine,
                    endLine: startLine + offset - 1,
                    chunkType: chunkType,
                    symbolName: symbolName,
                    tokenCount: currentTokenCount
                ))

                currentChunk = []
                currentStartLine = startLine + offset
                currentTokenCount = 0
            }

            currentChunk.append(line)
            currentTokenCount += lineTokenCount
        }

        if !currentChunk.isEmpty {
            let chunkContent = currentChunk.joined(separator: "\n")
            chunks.append(ParsedCodeChunk(
                content: chunkContent,
                startLine: currentStartLine,
                endLine: startLine + lines.count - 1,
                chunkType: chunkType,
                symbolName: symbolName,
                tokenCount: currentTokenCount
            ))
        }

        return chunks
    }

    private func mapSymbolTypeToChunkType(_ symbolType: SymbolType) -> ChunkType {
        switch symbolType {
        case .function: return .function
        case .class: return .class
        case .method: return .method
        case .struct: return .struct
        case .enum: return .enum
        case .protocol: return .protocol
        case .interface: return .interface
        case .property: return .property
        case .variable, .constant, .type: return .other
        }
    }
}
