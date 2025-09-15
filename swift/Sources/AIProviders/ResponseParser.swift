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
                  let choices = json[AIProviderConstants.ResponseKeys.choices] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice[AIProviderConstants.ResponseKeys.message] as? [String: Any],
                  let content = message[AIProviderConstants.ResponseKeys.content] as? String else {
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
                  let content = json[AIProviderConstants.ResponseKeys.content] as? [[String: Any]],
                  let firstContent = content.first,
                  let text = firstContent[AIProviderConstants.ResponseKeys.text] as? String else {
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
                  let candidates = json[AIProviderConstants.ResponseKeys.candidates] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate[AIProviderConstants.ResponseKeys.content] as? [String: Any],
                  let parts = content[AIProviderConstants.ResponseKeys.parts] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart[AIProviderConstants.ResponseKeys.text] as? String else {
                return .failure(.invalidResponse)
            }
            return .success(text)
        } catch {
            return .failure(.invalidResponse)
        }
    }
}