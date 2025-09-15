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
        request.httpMethod = AIProviderConstants.HTTPMethods.post
        request.setValue(AIProviderConstants.Authorization.bearerPrefix + config.apiKey, forHTTPHeaderField: AIProviderConstants.Headers.authorization)
        request.setValue(AIProviderConstants.Headers.applicationJSON, forHTTPHeaderField: AIProviderConstants.Headers.contentType)
        
        let body: [String: Any] = [
            AIProviderConstants.RequestKeys.model: config.model,
            AIProviderConstants.RequestKeys.messages: messages.map { [
                AIProviderConstants.RequestKeys.role: $0.role.rawValue,
                AIProviderConstants.RequestKeys.content: $0.content
            ] },
            AIProviderConstants.RequestKeys.maxTokens: config.maxTokens,
            AIProviderConstants.RequestKeys.temperature: config.temperature
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
        request.httpMethod = AIProviderConstants.HTTPMethods.post
        request.setValue(config.apiKey, forHTTPHeaderField: AIProviderConstants.Headers.anthropicAPIKey)
        request.setValue(AIProviderConstants.Headers.applicationJSON, forHTTPHeaderField: AIProviderConstants.Headers.contentType)
        request.setValue(AIProviderConstants.Defaults.anthropicVersion, forHTTPHeaderField: AIProviderConstants.Headers.anthropicVersion)
        
        let anthropicMessages = messages.compactMap { message -> [String: String]? in
            guard message.role != .system else { return nil }
            return [
                AIProviderConstants.RequestKeys.role: message.role == .assistant ? AIProviderConstants.RoleValues.assistant : AIProviderConstants.RoleValues.user,
                AIProviderConstants.RequestKeys.content: message.content
            ]
        }
        
        let systemMessage = messages.first { $0.role == .system }?.content
        
        var body: [String: Any] = [
            AIProviderConstants.RequestKeys.model: config.model,
            AIProviderConstants.RequestKeys.messages: anthropicMessages,
            AIProviderConstants.RequestKeys.maxTokens: config.maxTokens,
            AIProviderConstants.RequestKeys.temperature: config.temperature
        ]
        
        if let systemMessage = systemMessage {
            body[AIProviderConstants.RequestKeys.system] = systemMessage
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
        let endpoint = "\(AIProviderConstants.Endpoints.geminiBase)/\(config.model)\(AIProviderConstants.URLQuery.generateContentPath)?\(AIProviderConstants.URLQuery.keyParameter)=\(config.apiKey)"
        
        guard let url = URL(string: endpoint) else {
            return .failure(.invalidResponse)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = AIProviderConstants.HTTPMethods.post
        request.setValue(AIProviderConstants.Headers.applicationJSON, forHTTPHeaderField: AIProviderConstants.Headers.contentType)
        
        let contents = messages.map { message -> [String: Any] in
            let role = message.role == .assistant ? AIProviderConstants.RoleValues.model : AIProviderConstants.RoleValues.user
            return [
                AIProviderConstants.RequestKeys.role: role,
                AIProviderConstants.RequestKeys.parts: [[AIProviderConstants.RequestKeys.text: message.content]]
            ]
        }
        
        let body: [String: Any] = [
            AIProviderConstants.RequestKeys.contents: contents,
            AIProviderConstants.RequestKeys.generationConfig: [
                AIProviderConstants.RequestKeys.temperature: config.temperature,
                AIProviderConstants.RequestKeys.maxOutputTokens: config.maxTokens
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