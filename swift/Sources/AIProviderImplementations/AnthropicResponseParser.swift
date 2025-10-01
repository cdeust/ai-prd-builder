import Foundation
import CommonModels
import AIProvidersCore

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
