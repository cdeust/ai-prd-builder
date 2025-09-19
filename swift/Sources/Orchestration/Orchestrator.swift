import Foundation
import AIProvidersCore
import ThinkingCore
import CommonModels

/// Privacy-first orchestrator with Apple Foundation Models as primary provider
/// Refactored to use clean architecture with separated components
public final class Orchestrator {

    // MARK: - Component Managers

    private let providerManager: ProviderManager
    private let sessionManager: SessionManagement
    private let glossaryManager: GlossaryManager
    private let thinkingModeManager: ThinkingModeManager
    private let appleIntelligence: AppleIntelligenceClient

    // MARK: - Type Aliases for Compatibility

    public typealias AIProvider = ProviderManager.AIProvider
    public typealias PrivacyConfiguration = ProviderManager.PrivacyConfiguration
    public typealias ThinkingMode = ThinkingModeManager.ThinkingMode
    public typealias ThoughtProcess = ThinkingModeManager.ThoughtProcess

    // MARK: - Initialization

    public init(privacyConfig: PrivacyConfiguration = PrivacyConfiguration()) {
        // Initialize managers
        self.providerManager = ProviderManager(privacyConfig: privacyConfig)
        self.sessionManager = SessionManagement()
        self.glossaryManager = GlossaryManager(sessionManager: sessionManager)
        self.thinkingModeManager = ThinkingModeManager()
        self.appleIntelligence = AppleIntelligenceClient()

        // Initialize components asynchronously
        Task {
            await initialize()
        }
    }

    private func initialize() async {
        await glossaryManager.loadDefaultGlossary()
    }

    // MARK: - Session Management (Delegated)

    public func startNewSession() -> UUID {
        return sessionManager.startNewSession()
    }

    public func clearConversation() {
        sessionManager.clearConversation()
    }

    public var conversationHistory: [ChatMessage] {
        return sessionManager.conversationHistory
    }

    public var sessionId: UUID {
        return sessionManager.sessionId
    }

    public func getSessionHistory(_ sessionId: UUID? = nil) -> [ChatMessage] {
        return sessionManager.getSessionHistory(sessionId)
    }

    // MARK: - Glossary Management (Delegated)

    public func listGlossary() async -> [Glossary.Entry] {
        return await glossaryManager.listGlossary()
    }

    public func glossaryForCurrentSession() -> Glossary {
        return glossaryManager.glossaryForCurrentSession()
    }

    // MARK: - Provider Management (Delegated)

    public func getAvailableProviders() -> [AIProvider] {
        return providerManager.getAvailableProviders()
    }

    // MARK: - Thinking Mode Management (Delegated)

    public func getThoughtProcess() -> ThoughtProcess {
        return thinkingModeManager.getThoughtProcess()
    }

    // MARK: - Main Chat Interface

    public func chat(
        message: String,
        useAppleIntelligence: Bool = true,
        options: ChatOptions = ChatOptions(),
        thinkingMode: ThinkingMode = .automatic
    ) async throws -> (response: String, provider: AIProvider) {
        // Validate input
        guard !message.isEmpty else {
            throw OrchestratorError.emptyMessage
        }

        // Process thinking mode
        let mode = try await processThinkingMode(thinkingMode, for: message)

        // Store user message
        storeUserMessage(message)

        // Process with Apple Intelligence if requested
        if useAppleIntelligence && shouldUseAppleIntelligence(for: message) {
            return try await processWithAppleIntelligence(
                message: message,
                options: options,
                mode: mode
            )
        }

        // Process with regular providers
        return try await processWithProviders(
            message: message,
            options: options,
            mode: mode
        )
    }

    // MARK: - Private Processing Methods

    private func processThinkingMode(
        _ thinkingMode: ThinkingMode,
        for message: String
    ) async throws -> ThinkingMode {
        thinkingModeManager.resetThoughtProcess()

        let mode = thinkingMode == .automatic ?
            try await thinkingModeManager.selectBestMode(for: message) :
            thinkingMode

        thinkingModeManager.setThinkingMode(mode)
        thinkingModeManager.displayCurrentMode()

        return mode
    }

    private func storeUserMessage(_ message: String) {
        sessionManager.storeInSession(
            content: message,
            role: .user
        )
    }

    private func shouldUseAppleIntelligence(for message: String) -> Bool {
        return appleIntelligence.isAvailable() &&
               message.count < OrchestratorConstants.Timing.shortMessageThreshold
    }

    private func processWithAppleIntelligence(
        message: String,
        options: ChatOptions,
        mode: ThinkingMode
    ) async throws -> (response: String, provider: AIProvider) {
        // Expand acronyms
        let expandedMessage = await glossaryManager.expandAcronyms(in: message)

        // Apply Apple Intelligence
        var response = try await appleIntelligence.applyWritingTools(
            text: expandedMessage,
            command: .rewrite
        )

        // Refine if requested
        if options.useRefinement {
            response = try await refineResponse(response, options: options)
        }

        // Store response
        storeAssistantMessage(response)

        return (response, .foundationModels)
    }

    private func processWithProviders(
        message: String,
        options: ChatOptions,
        mode: ThinkingMode
    ) async throws -> (response: String, provider: AIProvider) {
        // Build system context
        let systemContext = await buildSystemContext(options: options)

        // Expand message
        let expandedMessage = await glossaryManager.expandAcronyms(in: message)

        // Select provider
        let provider = providerManager.selectProvider(
            for: expandedMessage,
            preferApple: true
        )

        // Execute with provider
        let response = try await providerManager.executeWithProvider(
            provider,
            message: expandedMessage,
            systemPrompt: systemContext
        )

        // Store response
        storeAssistantMessage(response)

        return (response, provider)
    }

    private func buildSystemContext(options: ChatOptions) async -> String {
        var contextParts: [String] = [
            OrchestratorConstants.SystemMessages.defaultAssistant
        ]

        // Add glossary policy
        let glossaryPolicy = await glossaryManager.buildAcronymSystemPolicy()
        if !glossaryPolicy.isEmpty {
            contextParts.append(glossaryPolicy)
        }

        // Add custom context if requested
        if options.injectContext {
            let customContext = SystemContextBuilder.buildDefaultContext()
            if !customContext.isEmpty {
                contextParts.append(customContext)
            }
        }

        return contextParts
            .filter { !$0.isEmpty }
            .joined(separator: OrchestratorConstants.Formatting.newlineDouble)
    }

    private func refineResponse(
        _ response: String,
        options: ChatOptions
    ) async throws -> String {
        let refinePrompt = OrchestratorConstants.ChatMessages.refinePrompt

        return try await providerManager.executeWithProvider(
            .privateCloudCompute,
            message: response,
            systemPrompt: refinePrompt
        )
    }

    private func storeAssistantMessage(_ response: String) {
        sessionManager.storeInSession(
            content: response,
            role: .assistant
        )
    }

    // MARK: - Convenience Methods

    /// Sends a message with specific provider preference
    public func sendMessage(
        _ prompt: String,
        systemPrompt: String? = nil,
        needsJSON: Bool = false
    ) async throws -> (String, AIProvider) {
        let options = ChatOptions(
            injectContext: systemPrompt != nil,
            useRefinement: false
        )

        return try await chat(
            message: prompt,
            useAppleIntelligence: false,
            options: options
        )
    }

    /// Generates with a specific provider
    public func generateWithProvider(
        _ provider: AIProvider,
        prompt: String,
        systemPrompt: String? = nil
    ) async throws -> String {
        return try await providerManager.executeWithProvider(
            provider,
            message: prompt,
            systemPrompt: systemPrompt
        )
    }
}

// MARK: - Orchestrator Errors

public enum OrchestratorError: LocalizedError {
    case emptyMessage
    case noProvidersAvailable
    case sessionNotFound
    case invalidConfiguration

    public var errorDescription: String? {
        switch self {
        case .emptyMessage:
            return OrchestratorConstants.ChatMessages.messageEmpty
        case .noProvidersAvailable:
            return OrchestratorConstants.ChatMessages.noProvidersAvailable
        case .sessionNotFound:
            return OrchestratorConstants.Errors.sessionNotFound
        case .invalidConfiguration:
            return OrchestratorConstants.Defaults.invalidConfiguration
        }
    }
}