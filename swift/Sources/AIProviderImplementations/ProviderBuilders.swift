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

public struct OpenAIResponseParser: ResponseParser {
    public init() {}

    public func parseResponse(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIProviderError.invalidResponse
        }
        return content
    }
}

// MARK: - Anthropic

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

public struct AnthropicResponseParser: ResponseParser {
    public init() {}

    public func parseResponse(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw AIProviderError.invalidResponse
        }
        return text
    }
}

// MARK: - Gemini

public struct GeminiRequestBuilder: RequestBuilder {
    public init() {}

    public func buildRequest(config: AIProviderConfig, messages: [ChatMessage]) -> URLRequest {
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(config.model):generateContent?key=\(config.apiKey)"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let contents = messages.map { message -> [String: Any] in
            ["parts": [["text": message.content]]]
        }

        let body: [String: Any] = ["contents": contents]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return request
    }
}

public struct GeminiResponseParser: ResponseParser {
    public init() {}

    public func parseResponse(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw AIProviderError.invalidResponse
        }
        return text
    }
}