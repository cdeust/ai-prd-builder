import Foundation

/// Protocol for building API requests (Single Responsibility)
public protocol RequestBuilder {
    func buildRequest(for messages: [ChatMessage], config: AIProviderConfig) -> Result<URLRequest, AIProviderError>
}

/// OpenAI request builder
public struct OpenAIRequestBuilder: RequestBuilder {
    public init() {}
    
    public func buildRequest(for messages: [ChatMessage], config: AIProviderConfig) -> Result<URLRequest, AIProviderError> {
        let endpoint = config.endpoint ?? AIProviderConstants.Endpoints.openAI
        
        guard let url = URL(string: endpoint) else {
            return .failure(.invalidResponse)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: AIProviderConstants.Headers.authorization)
        request.setValue(AIProviderConstants.Headers.applicationJSON, forHTTPHeaderField: AIProviderConstants.Headers.contentType)
        
        let body: [String: Any] = [
            "model": config.model,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] },
            "max_tokens": config.maxTokens,
            "temperature": config.temperature
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            return .success(request)
        } catch {
            return .failure(.invalidResponse)
        }
    }
}

/// Anthropic request builder
public struct AnthropicRequestBuilder: RequestBuilder {
    public init() {}
    
    public func buildRequest(for messages: [ChatMessage], config: AIProviderConfig) -> Result<URLRequest, AIProviderError> {
        let endpoint = config.endpoint ?? AIProviderConstants.Endpoints.anthropic
        
        guard let url = URL(string: endpoint) else {
            return .failure(.invalidResponse)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(config.apiKey, forHTTPHeaderField: AIProviderConstants.Headers.anthropicAPIKey)
        request.setValue(AIProviderConstants.Headers.applicationJSON, forHTTPHeaderField: AIProviderConstants.Headers.contentType)
        request.setValue(AIProviderConstants.Defaults.anthropicVersion, forHTTPHeaderField: AIProviderConstants.Headers.anthropicVersion)
        
        let anthropicMessages = messages.compactMap { message -> [String: String]? in
            guard message.role != .system else { return nil }
            return [
                "role": message.role == .assistant ? "assistant" : "user",
                "content": message.content
            ]
        }
        
        let systemMessage = messages.first { $0.role == .system }?.content
        
        var body: [String: Any] = [
            "model": config.model,
            "messages": anthropicMessages,
            "max_tokens": config.maxTokens,
            "temperature": config.temperature
        ]
        
        if let systemMessage = systemMessage {
            body["system"] = systemMessage
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            return .success(request)
        } catch {
            return .failure(.invalidResponse)
        }
    }
}

/// Gemini request builder
public struct GeminiRequestBuilder: RequestBuilder {
    public init() {}
    
    public func buildRequest(for messages: [ChatMessage], config: AIProviderConfig) -> Result<URLRequest, AIProviderError> {
        let endpoint = "\(AIProviderConstants.Endpoints.geminiBase)/\(config.model):generateContent?key=\(config.apiKey)"
        
        guard let url = URL(string: endpoint) else {
            return .failure(.invalidResponse)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(AIProviderConstants.Headers.applicationJSON, forHTTPHeaderField: AIProviderConstants.Headers.contentType)
        
        let contents = messages.map { message -> [String: Any] in
            let role = message.role == .assistant ? "model" : "user"
            return [
                "role": role,
                "parts": [["text": message.content]]
            ]
        }
        
        let body: [String: Any] = [
            "contents": contents,
            "generationConfig": [
                "temperature": config.temperature,
                "maxOutputTokens": config.maxTokens
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            return .success(request)
        } catch {
            return .failure(.invalidResponse)
        }
    }
}