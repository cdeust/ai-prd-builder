import Foundation

public struct ModelPreferences: Codable {
    public let temperature: Double
    public let maxTokens: Int
    public let topP: Double

    public init(
        temperature: Double = 0.7,
        maxTokens: Int = 50000,  // Default to 50K for comprehensive outputs
        topP: Double = 0.95
    ) {
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
    }
}
