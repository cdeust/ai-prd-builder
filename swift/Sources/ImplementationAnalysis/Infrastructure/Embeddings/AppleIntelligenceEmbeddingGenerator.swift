import Foundation
#if canImport(NaturalLanguage)
import NaturalLanguage
#endif
#if canImport(CoreML)
import CoreML
#endif

/// Apple Intelligence embedding generator using on-device ML
/// Provides privacy-first, local embedding generation
/// Falls back to NLEmbedding when CoreML models are unavailable
public final class AppleIntelligenceEmbeddingGenerator: EmbeddingGeneratorPort, @unchecked Sendable {
    private let modelType: ModelType
    private let dimension: Int

    public var embeddingDimension: Int { dimension }
    public var modelName: String { "apple-intelligence-\(modelType.rawValue)" }

    public enum ModelType: String, Sendable {
        case word = "word"
        case sentence = "sentence"
        case document = "document"
    }

    public init(modelType: ModelType = .sentence) {
        self.modelType = modelType
        // Apple NLEmbedding dimensions vary by language, typically 300-768
        // We'll standardize to 768 for compatibility
        self.dimension = 768
    }

    public func generateEmbedding(text: String) async throws -> [Float] {
        guard !text.isEmpty else {
            throw EmbeddingError.invalidInput("Cannot generate embedding for empty text")
        }

        #if canImport(NaturalLanguage)
        guard let embedding = await generateNLEmbedding(text: text) else {
            throw EmbeddingError.modelNotAvailable
        }
        return embedding
        #else
        throw EmbeddingError.modelNotAvailable
        #endif
    }

    public func generateEmbeddings(texts: [String]) async throws -> [[Float]] {
        guard !texts.isEmpty else {
            throw EmbeddingError.invalidInput("Cannot generate embeddings for empty text array")
        }

        // Process in parallel for better performance
        return try await withThrowingTaskGroup(of: (Int, [Float]).self) { group in
            for (index, text) in texts.enumerated() {
                group.addTask {
                    let embedding = try await self.generateEmbedding(text: text)
                    return (index, embedding)
                }
            }

            var results: [(Int, [Float])] = []
            for try await result in group {
                results.append(result)
            }

            // Sort by index to maintain order
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }

    #if canImport(NaturalLanguage)
    private func generateNLEmbedding(text: String) async -> [Float]? {
        // NLEmbedding is available on iOS 13+, macOS 10.15+
        guard #available(iOS 13.0, macOS 10.15, *) else {
            return nil
        }

        // Use task to run on background thread
        return await Task.detached {
            // Get embedding for the specified language (defaults to English)
            guard let embedding = NLEmbedding.wordEmbedding(for: .english) else {
                return nil
            }

            // For sentence-level embeddings, we'll average word embeddings
            // This is a simple but effective approach
            let tokens = text.split(separator: " ").map(String.init)
            guard !tokens.isEmpty else { return nil }

            var sumVector: [Double] = Array(repeating: 0.0, count: embedding.dimension)
            var count = 0

            for token in tokens {
                if let vector = embedding.vector(for: token) {
                    for (index, value) in vector.enumerated() where index < sumVector.count {
                        sumVector[index] += value
                    }
                    count += 1
                }
            }

            guard count > 0 else { return nil }

            // Average the vectors
            let avgVector = sumVector.map { Float($0) / Float(count) }

            // Pad or truncate to standard dimension (768)
            return self.normalizeVectorDimension(avgVector, targetDimension: 768)
        }.value
    }
    #endif

    /// Normalize vector to target dimension by padding with zeros or truncating
    private func normalizeVectorDimension(_ vector: [Float], targetDimension: Int) -> [Float] {
        if vector.count == targetDimension {
            return vector
        } else if vector.count < targetDimension {
            // Pad with zeros
            return vector + Array(repeating: 0.0, count: targetDimension - vector.count)
        } else {
            // Truncate
            return Array(vector.prefix(targetDimension))
        }
    }
}

/// Hybrid embedding generator that tries Apple Intelligence first, falls back to OpenAI
/// This is the recommended production implementation
public final class HybridEmbeddingGenerator: EmbeddingGeneratorPort, @unchecked Sendable {
    private let appleGenerator: AppleIntelligenceEmbeddingGenerator
    private let openAIGenerator: OpenAIEmbeddingGenerator?

    public var embeddingDimension: Int {
        openAIGenerator?.embeddingDimension ?? appleGenerator.embeddingDimension
    }

    public var modelName: String {
        "hybrid-apple-openai"
    }

    public init(
        appleModelType: AppleIntelligenceEmbeddingGenerator.ModelType = .sentence,
        openAIApiKey: String?
    ) {
        self.appleGenerator = AppleIntelligenceEmbeddingGenerator(modelType: appleModelType)
        if let apiKey = openAIApiKey {
            self.openAIGenerator = OpenAIEmbeddingGenerator(apiKey: apiKey)
        } else {
            self.openAIGenerator = nil
        }
    }

    public func generateEmbedding(text: String) async throws -> [Float] {
        // Try Apple Intelligence first (local, private, free)
        do {
            return try await appleGenerator.generateEmbedding(text: text)
        } catch {
            // Fall back to OpenAI if Apple Intelligence fails
            if let openAI = openAIGenerator {
                return try await openAI.generateEmbedding(text: text)
            }
            throw error
        }
    }

    public func generateEmbeddings(texts: [String]) async throws -> [[Float]] {
        // Try Apple Intelligence first
        do {
            return try await appleGenerator.generateEmbeddings(texts: texts)
        } catch {
            // Fall back to OpenAI if Apple Intelligence fails
            if let openAI = openAIGenerator {
                return try await openAI.generateEmbeddings(texts: texts)
            }
            throw error
        }
    }
}
