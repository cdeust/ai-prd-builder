import Foundation
import CommonModels

public struct Configuration: Codable {
    public let anthropicAPIKey: String?
    public let openAIAPIKey: String?
    public let geminiAPIKey: String?
    public let maxPrivacyLevel: PrivacyLevel
    public let preferredProvider: String?
    public let modelPreferences: ModelPreferences
    public let debugMode: Bool
    public let enableClarificationPrompts: Bool
    public let useChainOfThought: Bool
    public let useSelfConsistency: Bool

    public init(
        anthropicAPIKey: String? = nil,
        openAIAPIKey: String? = nil,
        geminiAPIKey: String? = nil,
        maxPrivacyLevel: PrivacyLevel = .onDevice,
        preferredProvider: String? = nil,
        modelPreferences: ModelPreferences = ModelPreferences(),
        debugMode: Bool = false,
        enableClarificationPrompts: Bool = true,
        useChainOfThought: Bool = false,
        useSelfConsistency: Bool = false
    ) {
        self.anthropicAPIKey = anthropicAPIKey
        self.openAIAPIKey = openAIAPIKey
        self.geminiAPIKey = geminiAPIKey
        self.maxPrivacyLevel = maxPrivacyLevel
        self.preferredProvider = preferredProvider
        self.modelPreferences = modelPreferences
        self.debugMode = debugMode
        self.enableClarificationPrompts = enableClarificationPrompts
        self.useChainOfThought = useChainOfThought
        self.useSelfConsistency = useSelfConsistency
    }
}

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