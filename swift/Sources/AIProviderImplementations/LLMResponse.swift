import Foundation
import CommonModels
import AIProvidersCore

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
