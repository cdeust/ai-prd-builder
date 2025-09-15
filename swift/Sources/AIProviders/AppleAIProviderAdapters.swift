import Foundation

// MARK: - Apple On-Device AIProvider Adapter

/// Adapter to make AppleOnDeviceProvider conform to AIProvider protocol
public final class AppleOnDeviceAIProvider: AIProvider {
    private let llmProvider = AppleOnDeviceProvider()

    public var name: String {
        return llmProvider.name
    }

    public init() {}

    public func sendMessages(_ messages: [ChatMessage]) async -> Result<String, AIProviderError> {
        // Check if available
        guard llmProvider.isAvailable() else {
            return .failure(.notConfigured)
        }

        // Convert ChatMessage to tuple format for LLMRequest
        let messagesTuples = messages.map { (role: $0.role.rawValue, content: $0.content) }

        // Create LLMRequest with correct parameters
        let request = LLMRequest(
            system: nil,
            messages: messagesTuples,
            jsonSchema: nil,
            temperature: 0.7,
            stream: false
        )

        do {
            let response = try await llmProvider.generate(request)
            return .success(response.text)
        } catch {
            return .failure(.executionFailed(error.localizedDescription))
        }
    }
}

// MARK: - Apple PCC AIProvider Adapter

/// Adapter to make ApplePCCProvider conform to AIProvider protocol
public final class ApplePCCAIProvider: AIProvider {
    private let llmProvider = ApplePCCProvider()

    public var name: String {
        return llmProvider.name
    }

    public init() {}

    public func sendMessages(_ messages: [ChatMessage]) async -> Result<String, AIProviderError> {
        // Check if available
        guard llmProvider.isAvailable() else {
            return .failure(.notConfigured)
        }

        // Convert ChatMessage to tuple format for LLMRequest
        let messagesTuples = messages.map { (role: $0.role.rawValue, content: $0.content) }

        // Create LLMRequest with correct parameters
        let request = LLMRequest(
            system: nil,
            messages: messagesTuples,
            jsonSchema: nil,
            temperature: 0.7,
            stream: false
        )

        do {
            let response = try await llmProvider.generate(request)
            return .success(response.text)
        } catch {
            return .failure(.executionFailed(error.localizedDescription))
        }
    }
}