import Foundation

/// Port for parsing code into semantic chunks
/// Abstracts language-specific parsing implementations
public protocol CodeParserPort: Sendable {
    /// The programming language this parser supports
    var supportedLanguage: ProgrammingLanguage { get }

    /// Parse code into semantic chunks
    /// - Parameters:
    ///   - code: The source code to parse
    ///   - filePath: The file path (used for context and error messages)
    /// - Returns: Array of code chunks with metadata
    func parseCode(_ code: String, filePath: String) async throws -> [ParsedCodeChunk]

    /// Extract symbols (functions, classes, methods) from code
    /// - Parameters:
    ///   - code: The source code to analyze
    ///   - filePath: The file path
    /// - Returns: Array of extracted symbols
    func extractSymbols(_ code: String, filePath: String) async throws -> [CodeSymbol]

    /// Calculate token count for a code chunk
    /// - Parameter code: The code to analyze
    /// - Returns: Estimated token count
    func estimateTokenCount(_ code: String) -> Int
}

/// Parsed code chunk with metadata
public struct ParsedCodeChunk: Sendable, Codable {
    public let content: String
    public let startLine: Int
    public let endLine: Int
    public let chunkType: ChunkType
    public let symbolName: String?
    public let tokenCount: Int
    public let context: String?  // Surrounding context for better understanding

    public init(
        content: String,
        startLine: Int,
        endLine: Int,
        chunkType: ChunkType,
        symbolName: String?,
        tokenCount: Int,
        context: String? = nil
    ) {
        self.content = content
        self.startLine = startLine
        self.endLine = endLine
        self.chunkType = chunkType
        self.symbolName = symbolName
        self.tokenCount = tokenCount
        self.context = context
    }
}

/// Code symbol (function, class, method, etc.)
public struct CodeSymbol: Sendable, Codable {
    public let name: String
    public let symbolType: SymbolType
    public let startLine: Int
    public let endLine: Int
    public let signature: String?
    public let documentation: String?
    public let modifiers: [String]  // public, private, static, async, etc.

    public init(
        name: String,
        symbolType: SymbolType,
        startLine: Int,
        endLine: Int,
        signature: String? = nil,
        documentation: String? = nil,
        modifiers: [String] = []
    ) {
        self.name = name
        self.symbolType = symbolType
        self.startLine = startLine
        self.endLine = endLine
        self.signature = signature
        self.documentation = documentation
        self.modifiers = modifiers
    }
}

/// Type of code symbol
public enum SymbolType: String, Sendable, Codable {
    case function
    case `class`
    case method
    case `struct`
    case `enum`
    case `protocol`
    case interface
    case property
    case variable
    case constant
    case type
}

/// Errors that can occur during code parsing
public enum CodeParsingError: Error, CustomStringConvertible {
    case unsupportedLanguage(ProgrammingLanguage)
    case syntaxError(line: Int, message: String)
    case parsingFailed(reason: String)
    case fileTooLarge(maxSize: Int)
    case invalidInput(String)

    public var description: String {
        switch self {
        case .unsupportedLanguage(let lang):
            return "Unsupported language: \(lang.rawValue)"
        case .syntaxError(let line, let message):
            return "Syntax error at line \(line): \(message)"
        case .parsingFailed(let reason):
            return "Parsing failed: \(reason)"
        case .fileTooLarge(let maxSize):
            return "File too large (max: \(maxSize) bytes)"
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        }
    }
}
