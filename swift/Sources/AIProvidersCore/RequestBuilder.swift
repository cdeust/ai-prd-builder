import Foundation
import CommonModels

public protocol RequestBuilder {
    func buildRequest(config: AIProviderConfig, messages: [ChatMessage]) -> URLRequest
}
