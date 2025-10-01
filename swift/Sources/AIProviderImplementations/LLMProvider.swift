import Foundation
import CommonModels
import AIProvidersCore

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
