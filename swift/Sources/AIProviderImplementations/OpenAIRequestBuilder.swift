import Foundation
import CommonModels
import AIProvidersCore

// MARK: - OpenAI

public struct OpenAIRequestBuilder: RequestBuilder {
    public init() {}

    public func buildRequest(config: AIProviderConfig, messages: [ChatMessage]) -> URLRequest {
        var request = URLRequest(url: URL(string: config.endpoint ?? "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": config.model,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] },
            "temperature": config.temperature,
            "max_tokens": config.maxTokens
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }
}
