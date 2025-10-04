import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// OpenAI implementation of EmbeddingGeneratorPort
/// Uses OpenAI's text-embedding-3-small model (1536 dimensions)
/// Fallback provider for when Apple Intelligence is unavailable
public final class OpenAIEmbeddingGenerator: EmbeddingGeneratorPort, @unchecked Sendable {
    private let apiKey: String
    private let baseURL: String
    private let model: String
    private let maxBatchSize: Int
    private let session: URLSession

    public var embeddingDimension: Int { 1536 }
    public var modelName: String { model }

    public init(
        apiKey: String,
        baseURL: String = "https://api.openai.com/v1",
        model: String = "text-embedding-3-small",
        maxBatchSize: Int = 100,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model
        self.maxBatchSize = maxBatchSize
        self.session = session
    }

    public func generateEmbedding(text: String) async throws -> [Float] {
        let embeddings = try await generateEmbeddings(texts: [text])
        guard let embedding = embeddings.first else {
            throw EmbeddingError.invalidInput("No embedding returned from API")
        }
        return embedding
    }

    public func generateEmbeddings(texts: [String]) async throws -> [[Float]] {
        guard !texts.isEmpty else {
            throw EmbeddingError.invalidInput("Cannot generate embeddings for empty text array")
        }

        guard texts.count <= maxBatchSize else {
            throw EmbeddingError.batchSizeExceeded(max: maxBatchSize)
        }

        let requestBody = OpenAIEmbeddingRequest(
            input: texts,
            model: model,
            encoding_format: "float"
        )

        let url = URL(string: "\(baseURL)/embeddings")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmbeddingError.apiError(statusCode: 0, message: "Invalid response type")
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                throw EmbeddingError.rateLimitExceeded
            }

            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw EmbeddingError.apiError(
                statusCode: httpResponse.statusCode,
                message: errorMessage
            )
        }

        let embeddingResponse = try JSONDecoder().decode(OpenAIEmbeddingResponse.self, from: data)

        // Sort by index to ensure correct order
        let sortedEmbeddings = embeddingResponse.data
            .sorted { $0.index < $1.index }
            .map { $0.embedding }

        return sortedEmbeddings
    }
}

// MARK: - OpenAI API Models

private struct OpenAIEmbeddingRequest: Codable {
    let input: [String]
    let model: String
    let encoding_format: String
}

private struct OpenAIEmbeddingResponse: Codable {
    let data: [OpenAIEmbeddingData]
    let model: String
    let usage: OpenAIUsage
}

private struct OpenAIEmbeddingData: Codable {
    let embedding: [Float]
    let index: Int
}

private struct OpenAIUsage: Codable {
    let prompt_tokens: Int
    let total_tokens: Int
}
