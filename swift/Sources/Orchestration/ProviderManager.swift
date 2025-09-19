import Foundation
import AIProvidersCore
import CommonModels

/// Manages AI provider initialization, selection, and routing
public class ProviderManager {

    // MARK: - Properties

    private let coordinator: AIProviderCoordinator
    private let router: ProviderRouter
    private let privacyConfig: PrivacyConfiguration

    // MARK: - Privacy Configuration

    public struct PrivacyConfiguration {
        public let allowExternalProviders: Bool
        public let requireUserConsent: Bool
        public let logExternalCalls: Bool

        public init(
            allowExternalProviders: Bool = false,
            requireUserConsent: Bool = true,
            logExternalCalls: Bool = true
        ) {
            self.allowExternalProviders = allowExternalProviders
            self.requireUserConsent = requireUserConsent
            self.logExternalCalls = logExternalCalls
        }
    }

    // MARK: - AI Provider Enum

    public enum AIProvider: String, CaseIterable {
        case foundationModels
        case privateCloudCompute
        case anthropic
        case openai
        case gemini

        public var rawValue: String {
            switch self {
            case .foundationModels:
                return AIProviderConstants.ProviderNames.apple
            case .privateCloudCompute:
                return "Private Cloud Compute"
            case .anthropic:
                return AIProviderConstants.ProviderNames.anthropic
            case .openai:
                return AIProviderConstants.ProviderNames.openAI
            case .gemini:
                return AIProviderConstants.ProviderNames.gemini
            }
        }

        public var priority: Int {
            switch self {
            case .foundationModels:
                return 0 // Highest priority
            case .privateCloudCompute:
                return 1
            case .anthropic:
                return 2
            case .openai:
                return 3
            case .gemini:
                return 4 // Lowest priority
            }
        }

        public var isExternal: Bool {
            switch self {
            case .foundationModels, .privateCloudCompute:
                return false
            case .anthropic, .openai, .gemini:
                return true
            }
        }
    }

    // MARK: - Initialization

    public init(privacyConfig: PrivacyConfiguration = PrivacyConfiguration()) {
        self.privacyConfig = privacyConfig

        // Initialize coordinator
        self.coordinator = AIProviderCoordinator()

        // Configure router with coordinator and privacy config
        self.router = ProviderRouter(coordinator: coordinator, privacyConfig: privacyConfig)

        // Initialize providers asynchronously
        Task {
            await initializeProviders()
        }
    }

    private func initializeProviders() async {
        do {
            try await coordinator.initialize()
            print("[ProviderManager] Successfully initialized providers")
        } catch {
            print("[ProviderManager] Failed to initialize: \(error.localizedDescription)")
        }
    }

    // MARK: - Provider Information

    /// Gets list of available providers based on configuration
    public func getAvailableProviders() -> [AIProvider] {
        var providers: [AIProvider] = [.foundationModels, .privateCloudCompute]

        if privacyConfig.allowExternalProviders {
            providers.append(contentsOf: [.anthropic, .openai, .gemini])
        }

        return providers.sorted { $0.priority < $1.priority }
    }

    /// Checks if a specific provider is available
    public func isProviderAvailable(_ provider: AIProvider) -> Bool {
        switch provider {
        case .foundationModels, .privateCloudCompute:
            return true
        case .anthropic, .openai, .gemini:
            return privacyConfig.allowExternalProviders
        }
    }

    // MARK: - Provider Access

    /// Gets the coordinator for direct provider access
    public var providerCoordinator: AIProviderCoordinator {
        return coordinator
    }

    /// Gets the router for intelligent routing
    public var providerRouter: ProviderRouter {
        return router
    }

    // MARK: - Provider Selection

    /// Selects best provider for given message length and complexity
    public func selectProvider(
        for message: String,
        preferApple: Bool = true
    ) -> AIProvider {
        let messageLength = message.count

        // Short messages prefer on-device
        if messageLength < 100 { // Short message threshold
            return .foundationModels
        }

        // Medium messages can use PCC
        if messageLength < 2000 {
            return .privateCloudCompute
        }

        // Long messages may need external if allowed
        if privacyConfig.allowExternalProviders {
            return .anthropic  // Best for long context
        }

        // Fall back to PCC for long messages if external not allowed
        return .privateCloudCompute
    }

    /// Routes messages using the provider router
    public func routeMessages(_ messages: [ChatMessage]) -> [ProviderRouter.Route] {
        return router.route(messages: messages)
    }

    // MARK: - Provider Execution

    /// Executes a request with a specific provider using the coordinator
    public func executeWithProvider(
        _ provider: AIProvider,
        message: String,
        systemPrompt: String? = nil
    ) async throws -> String {
        // If external providers are not allowed and the requested provider is external,
        // automatically fall back to Apple provider
        var actualProvider = provider
        if !privacyConfig.allowExternalProviders && provider.isExternal {
            actualProvider = .foundationModels
        }

        guard isProviderAvailable(actualProvider) else {
            throw ProviderError.notAvailable(actualProvider.rawValue)
        }

        // Create messages
        var messages: [ChatMessage] = []

        if let systemPrompt = systemPrompt {
            messages.append(ChatMessage(role: .system, content: systemPrompt))
        }
        messages.append(ChatMessage(role: .user, content: message))

        // Map provider to key and switch to it
        let providerKey = mapProviderToKey(actualProvider)
        _ = coordinator.switchProvider(to: providerKey)

        // Execute directly without routing if we're using Apple provider
        if !actualProvider.isExternal {
            let result = await coordinator.sendMessages(messages)
            switch result {
            case .success(let response):
                return response
            case .failure(let error):
                throw ProviderError.executionFailed(error.localizedDescription)
            }
        }

        // For external providers, use routing
        let routes = routeMessages(messages)

        guard let firstRoute = routes.first else {
            throw ProviderError.noRouteAvailable
        }

        // Execute based on route
        return try await executeWithRoute(firstRoute, messages: messages)
    }

    private func executeWithRoute(
        _ route: ProviderRouter.Route,
        messages: [ChatMessage]
    ) async throws -> String {
        // Check if external provider and verify permission
        if route.isExternal && !privacyConfig.allowExternalProviders {
            throw ProviderError.externalNotAllowed
        }

        // Switch to the selected provider
        _ = coordinator.switchProvider(to: route.provider)

        // Execute the request
        let result = await coordinator.sendMessages(messages)
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw ProviderError.executionFailed(error.localizedDescription)
        }
    }

    // MARK: - Helper Methods

    /// Maps internal provider enum to provider key string
    private func mapProviderToKey(_ provider: AIProvider) -> String {
        switch provider {
        case .foundationModels:
            return AIProviderConstants.ProviderKeys.apple
        case .privateCloudCompute:
            return AIProviderConstants.ProviderKeys.apple
        case .anthropic:
            return AIProviderConstants.ProviderKeys.anthropic
        case .openai:
            return AIProviderConstants.ProviderKeys.openAI
        case .gemini:
            return AIProviderConstants.ProviderKeys.gemini
        }
    }
}

// MARK: - Provider Errors

public enum ProviderError: LocalizedError {
    case notAvailable(String)
    case notFound(String)
    case initializationFailed(String)
    case executionFailed(String)
    case noRouteAvailable
    case externalNotAllowed

    public var errorDescription: String? {
        switch self {
        case .notAvailable(let provider):
            return "Provider \(provider) is not available"
        case .notFound(let provider):
            return "Provider \(provider) not found"
        case .initializationFailed(let reason):
            return "Failed to initialize: \(reason)"
        case .executionFailed(let reason):
            return "Execution failed: \(reason)"
        case .noRouteAvailable:
            return "No route available for request"
        case .externalNotAllowed:
            return AIProviderConstants.ErrorMessages.externalProvidersDisabled
        }
    }
}