import Foundation
import AIProvidersCore
import CommonModels

/// Routes requests to appropriate AI providers based on privacy settings and request characteristics
public class ProviderRouter {

    private let coordinator: AIProviderCoordinator
    private let privacyConfig: ProviderManager.PrivacyConfiguration

    /// Represents a routing decision
    public struct Route {
        public let provider: String
        public let reason: String
        public let isExternal: Bool

        public init(provider: String, reason: String, isExternal: Bool) {
            self.provider = provider
            self.reason = reason
            self.isExternal = isExternal
        }
    }

    public init(coordinator: AIProviderCoordinator, privacyConfig: ProviderManager.PrivacyConfiguration) {
        self.coordinator = coordinator
        self.privacyConfig = privacyConfig
    }

    /// Get routing options for messages
    public func route(messages: [ChatMessage]) -> [Route] {
        var routes: [Route] = []

        // Primary route - based on message analysis
        let requirement = analyzeRequirement(from: messages)

        // Always prioritize Apple provider first
        routes.append(Route(
            provider: AIProviderConstants.ProviderKeys.apple,
            reason: "Privacy-first default",
            isExternal: false
        ))

        // Add MLX as secondary option
        routes.append(Route(
            provider: AIProviderConstants.ProviderKeys.mlx,
            reason: "On-device fallback",
            isExternal: false
        ))

        // Only add external providers if allowed
        if privacyConfig.allowExternalProviders {
            if requirement == .quality || requirement == .general {
                routes.append(Route(
                    provider: AIProviderConstants.ProviderKeys.anthropic,
                    reason: "High-quality external provider",
                    isExternal: true
                ))
            }

            routes.append(Route(
                provider: AIProviderConstants.ProviderKeys.openAI,
                reason: "External fallback provider",
                isExternal: true
            ))
        }

        return routes
    }

    /// Route a message to the appropriate provider and get response
    public func routeAndExecute(messages: [ChatMessage]) async -> Result<String, AIProviderError> {
        // Determine provider based on message characteristics
        let requirement = analyzeRequirement(from: messages)

        // Check privacy constraints
        if !privacyConfig.allowExternalProviders && isExternalRequired(for: requirement) {
            return .failure(.configurationError("External providers disabled by privacy settings"))
        }

        // Get appropriate provider
        guard let provider = coordinator.selectProvider(for: requirement) else {
            return .failure(.configurationError("No suitable provider available"))
        }

        // Log if required
        if privacyConfig.logExternalCalls && isExternal(provider: provider) {
            logExternalCall(provider: provider, messages: messages)
        }

        // Send messages to provider
        return await provider.sendMessages(messages)
    }

    /// Analyze messages to determine provider requirement
    private func analyzeRequirement(from messages: [ChatMessage]) -> ProviderRequirement {
        // Simple analysis based on message content
        let lastMessage = messages.last?.content ?? ""

        if lastMessage.contains("private") || lastMessage.contains("sensitive") {
            return .privacy
        } else if lastMessage.contains("quick") || lastMessage.contains("fast") {
            return .speed
        } else if lastMessage.contains("accurate") || lastMessage.contains("detailed") {
            return .quality
        } else if lastMessage.contains("budget") || lastMessage.contains("cheap") {
            return .cost
        }

        return .general
    }

    /// Check if requirement needs external provider
    private func isExternalRequired(for requirement: ProviderRequirement) -> Bool {
        // External providers are never required - we can always use Apple/MLX
        return false
    }

    /// Check if provider is external
    private func isExternal(provider: AIProvider) -> Bool {
        // Check if provider is not local/on-device
        return provider.name != "MLX On-Device" && provider.name != "Apple Foundation Models"
    }

    /// Log external API calls
    private func logExternalCall(provider: AIProvider, messages: [ChatMessage]) {
        print("[ProviderRouter] External API call to \(provider.name)")
        if privacyConfig.logExternalCalls {
            // Could write to a log file or analytics service
            print("[ProviderRouter] Message count: \(messages.count)")
        }
    }
}