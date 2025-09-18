import Foundation
import AIProviders

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
                return OrchestratorConstants.ProviderDisplayNames.foundationModels
            case .privateCloudCompute:
                return OrchestratorConstants.ProviderDisplayNames.privateCloudCompute
            case .anthropic:
                return OrchestratorConstants.ProviderDisplayNames.anthropic
            case .openai:
                return OrchestratorConstants.ProviderDisplayNames.openai
            case .gemini:
                return OrchestratorConstants.ProviderDisplayNames.gemini
            }
        }

        public var priority: Int {
            switch self {
            case .foundationModels:
                return OrchestratorConstants.ProviderPriority.foundationModels
            case .privateCloudCompute:
                return OrchestratorConstants.ProviderPriority.privateCloudCompute
            case .anthropic:
                return OrchestratorConstants.ProviderPriority.anthropic
            case .openai:
                return OrchestratorConstants.ProviderPriority.openai
            case .gemini:
                return OrchestratorConstants.ProviderPriority.gemini
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

        // Configure routing policy based on privacy config
        let routingPolicy = ProviderRouter.RoutingPolicy(
            allowExternalProviders: privacyConfig.allowExternalProviders,
            preferPrivacy: true,
            useAppleIntelligenceFirst: true
        )

        self.router = ProviderRouter(policy: routingPolicy)

        // Initialize providers asynchronously
        Task {
            await initializeProviders()
        }
    }

    private func initializeProviders() async {
        let result = await coordinator.initialize()
        switch result {
        case .success:
            print(OrchestratorConstants.ProviderMessages.initializeSuccess)
        case .failure(let error):
            print(String(format: OrchestratorConstants.ProviderMessages.initializeFailure, error.localizedDescription))
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
        if messageLength < OrchestratorConstants.Timing.shortMessageThreshold {
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
        guard isProviderAvailable(provider) else {
            throw ProviderError.notAvailable(provider.rawValue)
        }

        // Create messages for routing
        var messages: [ChatMessage] = []

        if let systemPrompt = systemPrompt {
            messages.append(ChatMessage(role: .system, content: systemPrompt))
        }
        messages.append(ChatMessage(role: .user, content: message))

        // Route and execute
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
        switch route {
        case .appleOnDevice:
            // Use Apple on-device provider
            let result = await coordinator.sendMessages(messages)
            switch result {
            case .success(let response):
                return response
            case .failure(let error):
                throw ProviderError.executionFailed(error.localizedDescription)
            }

        case .applePCC:
            // Use Apple PCC provider
            let result = await coordinator.sendMessages(messages)
            switch result {
            case .success(let response):
                return response
            case .failure(let error):
                throw ProviderError.executionFailed(error.localizedDescription)
            }

        case .externalAPI(let providerKey):
            // Use external provider
            guard privacyConfig.allowExternalProviders else {
                throw ProviderError.externalNotAllowed
            }

            // Switch to specific external provider
            _ = await coordinator.switchProvider(to: providerKey)

            let result = await coordinator.sendMessages(messages)
            switch result {
            case .success(let response):
                return response
            case .failure(let error):
                throw ProviderError.executionFailed(error.localizedDescription)
            }
        }
    }

    // MARK: - Helper Methods

    /// Maps internal provider enum to provider key string
    private func mapProviderToKey(_ provider: AIProvider) -> String {
        switch provider {
        case .foundationModels:
            return OrchestratorConstants.ProviderKeys.appleOnDevice
        case .privateCloudCompute:
            return OrchestratorConstants.ProviderKeys.applePCC
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
            return String(format: OrchestratorConstants.Errors.providerNotAvailable, provider)
        case .notFound(let provider):
            return String(format: OrchestratorConstants.Errors.providerNotFound, provider)
        case .initializationFailed(let reason):
            return String(format: OrchestratorConstants.Errors.failedToInitialize, reason)
        case .executionFailed(let reason):
            return String(format: OrchestratorConstants.Errors.executionFailed, reason)
        case .noRouteAvailable:
            return OrchestratorConstants.Errors.noRouteAvailable
        case .externalNotAllowed:
            return OrchestratorConstants.Errors.externalNotAllowed
        }
    }
}