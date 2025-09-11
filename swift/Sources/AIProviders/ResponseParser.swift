import Foundation

/// Protocol for parsing API responses (Single Responsibility)
public protocol ResponseParser {
    func parseResponse(_ data: Data) -> Result<String, AIProviderError>
}

/// OpenAI response parser
public struct OpenAIResponseParser: ResponseParser {
    public init() {}
    
    public func parseResponse(_ data: Data) -> Result<String, AIProviderError> {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                return .failure(.invalidResponse)
            }
            return .success(content)
        } catch {
            return .failure(.invalidResponse)
        }
    }
}

/// Anthropic response parser
public struct AnthropicResponseParser: ResponseParser {
    public init() {}
    
    public func parseResponse(_ data: Data) -> Result<String, AIProviderError> {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]],
                  let firstContent = content.first,
                  let text = firstContent["text"] as? String else {
                return .failure(.invalidResponse)
            }
            return .success(text)
        } catch {
            return .failure(.invalidResponse)
        }
    }
}

/// Gemini response parser
public struct GeminiResponseParser: ResponseParser {
    public init() {}
    
    public func parseResponse(_ data: Data) -> Result<String, AIProviderError> {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart["text"] as? String else {
                return .failure(.invalidResponse)
            }
            return .success(text)
        } catch {
            return .failure(.invalidResponse)
        }
    }
}