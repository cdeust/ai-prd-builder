import Foundation

/// Port for generating embeddings from text
/// Abstracts the embedding generation service (OpenAI, Cohere, local models, etc.)
public protocol EmbeddingGeneratorPort: Sendable {
    /// Generate embedding for a single text
    func generateEmbedding(text: String) async throws -> [Float]

    /// Generate embeddings for multiple texts (batch operation)
    func generateEmbeddings(texts: [String]) async throws -> [[Float]]

    /// Get the dimension size of embeddings produced by this generator
    var embeddingDimension: Int { get }

    /// Get the model name/identifier
    var modelName: String { get }
}

/// Errors that can occur during embedding generation
public enum EmbeddingError: Error, CustomStringConvertible {
    case invalidInput(String)
    case apiError(statusCode: Int, message: String)
    case rateLimitExceeded
    case modelNotAvailable
    case batchSizeExceeded(max: Int)

    public var description: String {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        case .rateLimitExceeded:
            return "Rate limit exceeded, please retry later"
        case .modelNotAvailable:
            return "Embedding model is not available"
        case .batchSizeExceeded(let max):
            return "Batch size exceeded maximum of \(max)"
        }
    }
}
