import Foundation
import CommonModels
import AIProvidersCore

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
