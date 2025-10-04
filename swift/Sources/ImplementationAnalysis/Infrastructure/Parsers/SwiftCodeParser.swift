import Foundation

/// Swift code parser with AST-based symbol extraction
/// Uses regex patterns for parsing (SwiftSyntax would be ideal but requires additional dependencies)
public final class SwiftCodeParser: CodeParserPort, @unchecked Sendable {
    public let supportedLanguage: ProgrammingLanguage = .swift

    private let maxFileSize: Int
    private let maxChunkTokens: Int

    public init(maxFileSize: Int = 1_000_000, maxChunkTokens: Int = 1000) {
        self.maxFileSize = maxFileSize
        self.maxChunkTokens = maxChunkTokens
    }

    public func parseCode(_ code: String, filePath: String) async throws -> [ParsedCodeChunk] {
        guard code.utf8.count <= maxFileSize else {
            throw CodeParsingError.fileTooLarge(maxSize: maxFileSize)
        }

        let lines = code.components(separatedBy: .newlines)
        var chunks: [ParsedCodeChunk] = []

        // Extract symbols first
        let symbols = try await extractSymbols(code, filePath: filePath)

        // Create chunks from symbols
        for symbol in symbols {
            let symbolLines = Array(lines[symbol.startLine - 1..<min(symbol.endLine, lines.count)])
            let content = symbolLines.joined(separator: "\n")
            let tokenCount = estimateTokenCount(content)

            // Split large symbols into smaller chunks
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

        // Extract standalone comments and imports
        chunks.append(contentsOf: extractComments(from: lines))
        chunks.append(contentsOf: extractImports(from: lines))

        return chunks.sorted { $0.startLine < $1.startLine }
    }

    public func extractSymbols(_ code: String, filePath: String) async throws -> [CodeSymbol] {
        var symbols: [CodeSymbol] = []

        // Extract classes
        symbols.append(contentsOf: extractClasses(from: code))

        // Extract structs
        symbols.append(contentsOf: extractStructs(from: code))

        // Extract enums
        symbols.append(contentsOf: extractEnums(from: code))

        // Extract protocols
        symbols.append(contentsOf: extractProtocols(from: code))

        // Extract functions (top-level and methods)
        symbols.append(contentsOf: extractFunctions(from: code))

        return symbols.sorted { $0.startLine < $1.startLine }
    }

    public func estimateTokenCount(_ code: String) -> Int {
        // Rough estimation: ~4 characters per token for code
        return code.count / 4
    }

    // MARK: - Private Extraction Methods

    private func extractClasses(from code: String) -> [CodeSymbol] {
        let pattern = #"""
        (?:///[^\n]*\n)*\s*(?:(public|private|internal|open|fileprivate)\s+)?(?:(final|open)\s+)?class\s+(\w+)(?:<[^>]+>)?(?:\s*:\s*([^\{]+))?\s*\{
        """#

        return extractSymbolsWithPattern(
            pattern: pattern,
            code: code,
            symbolType: .class,
            nameGroupIndex: 3
        )
    }

    private func extractStructs(from code: String) -> [CodeSymbol] {
        let pattern = #"""
        (?:///[^\n]*\n)*\s*(?:(public|private|internal|fileprivate)\s+)?struct\s+(\w+)(?:<[^>]+>)?(?:\s*:\s*([^\{]+))?\s*\{
        """#

        return extractSymbolsWithPattern(
            pattern: pattern,
            code: code,
            symbolType: .struct,
            nameGroupIndex: 2
        )
    }

    private func extractEnums(from code: String) -> [CodeSymbol] {
        let pattern = #"""
        (?:///[^\n]*\n)*\s*(?:(public|private|internal|fileprivate)\s+)?enum\s+(\w+)(?:<[^>]+>)?(?:\s*:\s*([^\{]+))?\s*\{
        """#

        return extractSymbolsWithPattern(
            pattern: pattern,
            code: code,
            symbolType: .enum,
            nameGroupIndex: 2
        )
    }

    private func extractProtocols(from code: String) -> [CodeSymbol] {
        let pattern = #"""
        (?:///[^\n]*\n)*\s*(?:(public|private|internal|fileprivate)\s+)?protocol\s+(\w+)(?:<[^>]+>)?(?:\s*:\s*([^\{]+))?\s*\{
        """#

        return extractSymbolsWithPattern(
            pattern: pattern,
            code: code,
            symbolType: .protocol,
            nameGroupIndex: 2
        )
    }

    private func extractFunctions(from code: String) -> [CodeSymbol] {
        let pattern = #"""
        (?:///[^\n]*\n)*\s*(?:(public|private|internal|fileprivate|open)\s+)?(?:(static|class)\s+)?func\s+(\w+)\s*(?:<[^>]+>)?\s*\([^\)]*\)(?:\s*(?:async|throws|rethrows))?\s*(?:->\s*[^\{]+)?\s*\{
        """#

        return extractSymbolsWithPattern(
            pattern: pattern,
            code: code,
            symbolType: .function,
            nameGroupIndex: 3
        )
    }

    private func extractSymbolsWithPattern(
        pattern: String,
        code: String,
        symbolType: SymbolType,
        nameGroupIndex: Int
    ) -> [CodeSymbol] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
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

            // Extract modifiers
            var modifiers: [String] = []
            if match.numberOfRanges > 1, match.range(at: 1).location != NSNotFound {
                let modifier = nsString.substring(with: match.range(at: 1))
                modifiers.append(modifier)
            }

            // Find line numbers
            let matchRange = match.range
            let beforeMatch = nsString.substring(to: matchRange.location)
            let startLine = beforeMatch.components(separatedBy: .newlines).count

            // Find end of symbol (closing brace)
            let endLine = findClosingBrace(in: code, startingAt: matchRange.location + matchRange.length)

            // Extract documentation
            let documentation = extractDocumentation(before: matchRange.location, in: code)

            return CodeSymbol(
                name: name,
                symbolType: symbolType,
                startLine: startLine,
                endLine: endLine ?? startLine + 10,  // Fallback
                signature: nsString.substring(with: matchRange),
                documentation: documentation,
                modifiers: modifiers
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

    private func extractDocumentation(before offset: Int, in code: String) -> String? {
        let beforeCode = String(code.prefix(offset))
        let lines = beforeCode.components(separatedBy: .newlines)

        var docLines: [String] = []
        for line in lines.reversed() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("///") {
                let doc = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                docLines.insert(doc, at: 0)
            } else if !trimmed.isEmpty {
                break
            }
        }

        return docLines.isEmpty ? nil : docLines.joined(separator: " ")
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
                // End of comment block
                let content = currentCommentContent.joined(separator: "\n")
                if estimateTokenCount(content) > 50 {  // Only significant comments
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

    private func extractImports(from lines: [String]) -> [ParsedCodeChunk] {
        var chunks: [ParsedCodeChunk] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("import ") {
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
                // Save current chunk
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

        // Add remaining chunk
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
