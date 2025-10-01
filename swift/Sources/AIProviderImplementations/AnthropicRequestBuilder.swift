import Foundation
import CommonModels
import AIProvidersCore

public struct AnthropicRequestBuilder: RequestBuilder {
    public init() {}

    public func buildRequest(config: AIProviderConfig, messages: [ChatMessage]) -> URLRequest {
        var request = URLRequest(url: URL(string: config.endpoint ?? "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": config.model,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] },
            "max_tokens": config.maxTokens
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }
}
