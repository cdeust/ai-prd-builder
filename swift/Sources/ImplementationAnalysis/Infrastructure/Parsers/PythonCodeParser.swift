import Foundation

/// Python code parser with regex-based symbol extraction
/// Handles Python 3.x syntax including classes, functions, decorators, etc.
public final class PythonCodeParser: CodeParserPort, @unchecked Sendable {
    public let supportedLanguage: ProgrammingLanguage = .python

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

        // Extract imports and docstrings
        chunks.append(contentsOf: extractImports(from: lines))
        chunks.append(contentsOf: extractComments(from: lines))

        return chunks.sorted { $0.startLine < $1.startLine }
    }

    public func extractSymbols(_ code: String, filePath: String) async throws -> [CodeSymbol] {
        var symbols: [CodeSymbol] = []

        symbols.append(contentsOf: extractClasses(from: code))
        symbols.append(contentsOf: extractFunctions(from: code))
        symbols.append(contentsOf: extractMethods(from: code))

        return symbols.sorted { $0.startLine < $1.startLine }
    }

    public func estimateTokenCount(_ code: String) -> Int {
        return code.count / 4
    }

    // MARK: - Private Extraction Methods

    private func extractClasses(from code: String) -> [CodeSymbol] {
        // Match: class ClassName(Base):
        // With optional docstring
        let pattern = #"""
        ^(?:[ \t]*)class\s+(\w+)(?:\([^\)]*\))?:
        """#

        return extractSymbolsWithPattern(
            pattern: pattern,
            code: code,
            symbolType: .class,
            nameGroupIndex: 1,
            options: [.anchorsMatchLines]
        )
    }

    private func extractFunctions(from code: String) -> [CodeSymbol] {
        // Match top-level functions (not indented)
        // With optional decorators
        let pattern = #"""
        ^(?:@\w+(?:\([^\)]*\))?\s*\n)*(?:async\s+)?def\s+(\w+)\s*\([^\)]*\)(?:\s*->\s*[^:]+)?:
        """#

        return extractSymbolsWithPattern(
            pattern: pattern,
            code: code,
            symbolType: .function,
            nameGroupIndex: 1,
            options: [.anchorsMatchLines]
        )
    }

    private func extractMethods(from code: String) -> [CodeSymbol] {
        // Match indented methods (class methods)
        let pattern = #"""
        ^[ \t]+(?:@\w+(?:\([^\)]*\))?\s*\n)*[ \t]+(?:async\s+)?def\s+(\w+)\s*\([^\)]*\)(?:\s*->\s*[^:]+)?:
        """#

        return extractSymbolsWithPattern(
            pattern: pattern,
            code: code,
            symbolType: .method,
            nameGroupIndex: 1,
            options: [.anchorsMatchLines]
        )
    }

    private func extractSymbolsWithPattern(
        pattern: String,
        code: String,
        symbolType: SymbolType,
        nameGroupIndex: Int,
        options: NSRegularExpression.Options = []
    ) -> [CodeSymbol] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
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

            // Find end of definition by detecting next unindented line or EOF
            let endLine = findPythonBlockEnd(
                in: code,
                startingAt: matchRange.location + matchRange.length,
                baseIndentation: getIndentation(at: matchRange.location, in: code)
            )

            // Extract docstring
            let documentation = extractDocstring(
                after: matchRange.location + matchRange.length,
                in: code,
                indentation: getIndentation(at: matchRange.location, in: code)
            )

            // Extract decorators
            let modifiers = extractDecorators(before: matchRange.location, in: code)

            return CodeSymbol(
                name: name,
                symbolType: symbolType,
                startLine: startLine,
                endLine: endLine ?? startLine + 10,
                signature: nsString.substring(with: matchRange).trimmingCharacters(in: .whitespacesAndNewlines),
                documentation: documentation,
                modifiers: modifiers
            )
        }
    }

    private func getIndentation(at offset: Int, in code: String) -> Int {
        let beforeCode = String(code.prefix(offset))
        guard let lastNewline = beforeCode.lastIndex(of: "\n") else {
            return 0
        }

        let lineStart = code.index(after: lastNewline)
        let line = String(code[lineStart...])

        var spaces = 0
        for char in line {
            if char == " " {
                spaces += 1
            } else if char == "\t" {
                spaces += 4  // Treat tab as 4 spaces
            } else {
                break
            }
        }

        return spaces
    }

    private func findPythonBlockEnd(in code: String, startingAt offset: Int, baseIndentation: Int) -> Int? {
        let remainingCode = String(code.dropFirst(offset))
        let lines = remainingCode.components(separatedBy: .newlines)

        var currentLine = code.prefix(offset).components(separatedBy: .newlines).count + 1

        for line in lines {
            // Skip empty lines
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                currentLine += 1
                continue
            }

            // Check indentation
            var spaces = 0
            for char in line {
                if char == " " {
                    spaces += 1
                } else if char == "\t" {
                    spaces += 4
                } else {
                    break
                }
            }

            // If we hit a line with same or less indentation (and it's not empty),
            // the previous line was the end
            if spaces <= baseIndentation {
                return currentLine - 1
            }

            currentLine += 1
        }

        return currentLine - 1
    }

    private func extractDocstring(after offset: Int, in code: String, indentation: Int) -> String? {
        let remainingCode = String(code.dropFirst(offset))

        // Match docstring: """...""" or '''...'''
        let pattern = #"""
        ^\s*("""|\'\'\')(.*?)\1
        """#

        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: remainingCode, range: NSRange(location: 0, length: remainingCode.utf16.count)),
              match.numberOfRanges > 2 else {
            return nil
        }

        let nsString = remainingCode as NSString
        let docRange = match.range(at: 2)
        let docString = nsString.substring(with: docRange)

        // Clean up docstring formatting
        let cleaned = docString
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return cleaned.isEmpty ? nil : cleaned
    }

    private func extractDecorators(before offset: Int, in code: String) -> [String] {
        let beforeCode = String(code.prefix(offset))
        let lines = beforeCode.components(separatedBy: .newlines).reversed()

        var decorators: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("@") {
                decorators.insert(trimmed, at: 0)
            } else if !trimmed.isEmpty {
                break
            }
        }

        return decorators
    }

    private func extractImports(from lines: [String]) -> [ParsedCodeChunk] {
        var chunks: [ParsedCodeChunk] = []

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("import ") || trimmed.hasPrefix("from ") {
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
            if trimmed.hasPrefix("#") {
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
