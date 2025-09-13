import Foundation

// MARK: - Core Types matching Apple's pattern

public struct LLMRequest {
    public var system: String?
    public var messages: [(role: String, content: String)]
    public var jsonSchema: String?    // optional schema for JSON responses
    public var temperature: Double = 0.4
    public var stream: Bool = false
    
    public init(
        system: String? = nil,
        messages: [(role: String, content: String)] = [],
        jsonSchema: String? = nil,
        temperature: Double = 0.4,
        stream: Bool = false
    ) {
        self.system = system
        self.messages = messages
        self.jsonSchema = jsonSchema
        self.temperature = temperature
        self.stream = stream
    }
}

public struct LLMResponse {
    public var text: String
    public var raw: Data?
    public var provider: String?
    public var tokensUsed: Int?
    public var latencyMs: Int?
    
    public init(text: String, raw: Data? = nil, provider: String? = nil, tokensUsed: Int? = nil, latencyMs: Int? = nil) {
        self.text = text
        self.raw = raw
        self.provider = provider
        self.tokensUsed = tokensUsed
        self.latencyMs = latencyMs
    }
}

public protocol LLMProvider {
    var name: String { get }
    func generate(_ req: LLMRequest) async throws -> LLMResponse
    func isAvailable() -> Bool
}
