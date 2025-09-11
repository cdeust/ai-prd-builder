import Foundation
import AIProviders

/// Privacy-first orchestrator with Apple Foundation Models as primary provider
/// Refactored with clean architecture and better separation of concerns
public final class AIOrchestrator {
    
    // MARK: - Provider Management
    private let appleOnDevice: AppleOnDeviceProvider
    private let applePCC: ApplePCCProvider
    private let coordinator: AIProviderCoordinator
    private let router: ProviderRouter
    
    // MARK: - Apple Intelligence Integration
    private let appleIntelligence: AppleIntelligenceClient
    
    // MARK: - Session Management
    private var sessionHistory: [UUID: [ChatMessage]] = [:]
    private var currentSession: UUID?
    
    public enum AIProvider: String, CaseIterable {
        case foundationModels = "Apple Foundation Models (On-Device)"
        case privateCloudCompute = "Apple Private Cloud Compute"
        case anthropic = "Anthropic Claude"
        case openai = "OpenAI GPT"
        case gemini = "Google Gemini"
        
        var priority: Int {
            switch self {
            case .foundationModels: return 1      // Highest priority - on-device
            case .privateCloudCompute: return 2   // Privacy-preserved cloud
            case .anthropic: return 3              // External APIs only when needed
            case .openai: return 4
            case .gemini: return 5
            }
        }
    }
    
    private let privacyConfig: PrivacyConfiguration
    
    public struct PrivacyConfiguration {
        public let allowExternalProviders: Bool
        public let requireUserConsent: Bool
        public let logExternalCalls: Bool
        public let maxContextForExternal: Int
        
        public init(
            allowExternalProviders: Bool = false,
            requireUserConsent: Bool = true,
            logExternalCalls: Bool = true,
            maxContextForExternal: Int = 8192
        ) {
            self.allowExternalProviders = allowExternalProviders
            self.requireUserConsent = requireUserConsent
            self.logExternalCalls = logExternalCalls
            self.maxContextForExternal = maxContextForExternal
        }
    }
    
    public init(privacyConfig: PrivacyConfiguration = PrivacyConfiguration()) {
        print("AIOrchestrator init started")
        self.privacyConfig = privacyConfig
        
        print("Creating Apple providers...")
        // Initialize Apple providers (primary)
        self.appleOnDevice = AppleOnDeviceProvider()
        self.applePCC = ApplePCCProvider()
        self.appleIntelligence = AppleIntelligenceClient()
        
        print("Creating coordinator...")
        // Initialize fallback providers
        self.coordinator = AIProviderCoordinator()
        
        print("Setting up router...")
        // Setup router with enhanced policy
        let routingPolicy = ProviderRouter.RoutingPolicy(
            allowExternalProviders: privacyConfig.allowExternalProviders,
            preferPrivacy: true,
            useAppleIntelligenceFirst: true
        )
        
        self.router = ProviderRouter(policy: routingPolicy)
        self.currentSession = UUID()
        print("AIOrchestrator init completed")
    }
    
    private func initialize() async {
        await setupExternalProviders()
        
        // Check Apple Intelligence availability
        if appleIntelligence.isAvailable() {
            print("✅ Apple Intelligence Writing Tools available")
        } else {
            print("ℹ️ Apple Intelligence not available, using LLM providers")
        }
    }
    
    private func setupExternalProviders() async {
        guard privacyConfig.allowExternalProviders else {
            print("🔒 External providers disabled for privacy")
            return
        }
        
        let result = await coordinator.initialize()
        
        switch result {
        case .success:
            print("✅ External providers available (will only use if necessary)")
        case .failure:
            print("ℹ️ No external API keys - using Apple FM and local models only")
        }
    }
    
    /// Get available providers in privacy-preserving order
    public func getAvailableProviders() -> [AIProvider] {
        var providers: [AIProvider] = []
        
        // Apple Foundation Models (always first)
        if appleOnDevice.isAvailable() {
            providers.append(.foundationModels)
        }
        if applePCC.isAvailable() {
            providers.append(.privateCloudCompute)
        }
        
        // External providers only if allowed
        if privacyConfig.allowExternalProviders {
            let registeredProviders = coordinator.getAllProviders()
            if registeredProviders[AIProviderConstants.ProviderKeys.anthropic] != nil {
                providers.append(.anthropic)
            }
            if registeredProviders[AIProviderConstants.ProviderKeys.openAI] != nil {
                providers.append(.openai)
            }
            if registeredProviders[AIProviderConstants.ProviderKeys.gemini] != nil {
                providers.append(.gemini)
            }
        }
        
        
        return providers.sorted { $0.priority < $1.priority }
    }
    
    /// Generate PRD with Apple Intelligence integration and privacy-first provider selection
    public func generatePRD(
        feature: String,
        context: String,
        priority: String,
        requirements: [String],
        skipValidation: Bool = false,
        useAppleIntelligence: Bool = true
    ) async throws -> (content: String, provider: AIProvider) {
        
        // Try Apple Intelligence Writing Tools first if available
        if useAppleIntelligence && appleIntelligence.isAvailable() {
            do {
                let prdContent = try await appleIntelligence.generatePRD(
                    feature: feature,
                    context: context,
                    priority: priority,
                    requirements: requirements
                )
                
                // Store in session
                storeInSession(content: prdContent, role: .assistant)
                
                return (prdContent, .foundationModels)
            } catch {
                print("⚠️ Apple Intelligence failed, falling back to LLM: \(error)")
            }
        }
        
        let messages = buildPRDMessages(
            feature: feature,
            context: context,
            priority: priority,
            requirements: requirements,
            includeHistory: true
        )
        
        // Get routing decision (PRDs often need JSON structure)
        let needsJSON = true  // PRDs benefit from structured output
        let routes = router.route(messages: messages, needsJSON: needsJSON)
        
        print(router.explainRoute(messages: messages, needsJSON: needsJSON))
        
        // Try each route in order
        for route in routes {
            do {
                let (content, provider) = try await executeRoute(
                    route: route,
                    messages: messages,
                    originalRequest: (feature, context, priority, requirements)
                )
                
                print("✅ Generated using \(provider.rawValue)")
                
                // Store in session
                storeInSession(content: content, role: .assistant)
                
                // Post-process with Apple Intelligence if available
                let finalContent = await postProcessWithAppleIntelligence(content)
                
                return (finalContent, provider)
                
            } catch {
                print("⚠️ Route \(route) failed: \(error.localizedDescription)")
                continue
            }
        }
        
        throw NSError(
            domain: "AIOrchestrator",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "All providers failed. Check configuration and model availability."]
        )
    }
    
    private func executeRoute(
        route: ProviderRouter.Route,
        messages: [ChatMessage],
        originalRequest: (String, String, String, [String])
    ) async throws -> (String, AIProvider) {
        
        switch route {
        case .appleOnDevice:
            let req = LLMRequest(
                system: messages.first { $0.role == .system }?.content,
                messages: messages.map { ($0.role.rawValue, $0.content) },
                jsonSchema: nil,  // Can add schema when needed
                temperature: 0.7
            )
            let response = try await appleOnDevice.generate(req)
            return (response.text, .foundationModels)
            
        case .applePCC:
            let req = LLMRequest(
                system: messages.first { $0.role == .system }?.content,
                messages: messages.map { ($0.role.rawValue, $0.content) },
                jsonSchema: nil,
                temperature: 0.7
            )
            let response = try await applePCC.generate(req)
            return (response.text, .privateCloudCompute)
            
        case .externalAPI(let provider):
            guard privacyConfig.allowExternalProviders else {
                throw AIProviderError.notConfigured
            }
            
            if privacyConfig.logExternalCalls {
                print("⚠️ Using external provider: \(provider)")
            }
            
            return try await useExternalProvider(
                provider: provider,
                messages: messages
            )
            
        case .localMLX:
            throw NSError(
                domain: "AIOrchestrator",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Local MLX models not supported. Please use Apple Intelligence or external providers."]
            )
        }
    }
    
    private func useExternalProvider(
        provider: String,
        messages: [ChatMessage]
    ) async throws -> (String, AIProvider) {
        
        let providerKey: String
        let aiProvider: AIProvider
        
        switch provider {
        case "anthropic":
            providerKey = AIProviderConstants.ProviderKeys.anthropic
            aiProvider = .anthropic
        case "openai":
            providerKey = AIProviderConstants.ProviderKeys.openAI
            aiProvider = .openai
        case "gemini":
            providerKey = AIProviderConstants.ProviderKeys.gemini
            aiProvider = .gemini
        default:
            throw AIProviderError.notConfigured
        }
        
        _ = coordinator.setActiveProvider(providerKey)
        let result = await coordinator.sendMessages(messages)
        
        switch result {
        case .success(let content):
            return (content, aiProvider)
        case .failure(let error):
            throw error
        }
    }
    
    // MARK: - Session Management
    
    private func storeInSession(content: String, role: ChatMessage.Role) {
        guard let sessionId = currentSession else { return }
        
        let message = ChatMessage(role: role, content: content)
        if sessionHistory[sessionId] == nil {
            sessionHistory[sessionId] = []
        }
        sessionHistory[sessionId]?.append(message)
    }
    
    public func startNewSession() -> UUID {
        let sessionId = UUID()
        currentSession = sessionId
        sessionHistory[sessionId] = []
        return sessionId
    }
    
    public func getSessionHistory(_ sessionId: UUID? = nil) -> [ChatMessage] {
        let id = sessionId ?? currentSession ?? UUID()
        return sessionHistory[id] ?? []
    }
    
    // MARK: - Apple Intelligence Post-Processing
    
    private func postProcessWithAppleIntelligence(_ content: String) async -> String {
        guard appleIntelligence.isAvailable() else { return content }
        
        do {
            // Use Apple Intelligence to make the content more professional
            let improved = try await appleIntelligence.applyWritingTools(
                text: content,
                command: .makeProfessional
            )
            print("✨ Enhanced with Apple Intelligence Writing Tools")
            return improved
        } catch {
            // If post-processing fails, return original content
            return content
        }
    }
    
    // MARK: - Chat Interface
    
    public func chat(
        message: String,
        useAppleIntelligence: Bool = true
    ) async throws -> (response: String, provider: AIProvider) {
        
        // Store user message
        storeInSession(content: message, role: .user)
        
        // Try Apple Intelligence for simple queries
        if useAppleIntelligence && appleIntelligence.isAvailable() && message.count < 500 {
            do {
                let response = try await appleIntelligence.applyWritingTools(
                    text: message,
                    command: .rewrite
                )
                storeInSession(content: response, role: .assistant)
                return (response, .foundationModels)
            } catch {
                // Fall back to LLM
            }
        }
        
        // Use LLM for complex queries
        let messages = [
            ChatMessage(role: .system, content: "You are a helpful AI assistant."),
            ChatMessage(role: .user, content: message)
        ]
        
        let routes = router.route(messages: messages)
        
        for route in routes {
            do {
                let (content, provider) = try await executeRoute(
                    route: route,
                    messages: messages,
                    originalRequest: (message, "", "medium", [])
                )
                
                storeInSession(content: content, role: .assistant)
                return (content, provider)
            } catch {
                continue
            }
        }
        
        throw NSError(
            domain: "AIOrchestrator",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "All providers failed"]
        )
    }
    
    private func buildPRDMessages(
        feature: String,
        context: String,
        priority: String,
        requirements: [String],
        includeHistory: Bool = false
    ) -> [ChatMessage] {
        
        let systemPrompt = """
        You are a Product Requirements Document (PRD) generator.
        Create a comprehensive PRD with sections for: Overview, User Stories,
        Functional Requirements, Non-Functional Requirements, Success Metrics,
        and Technical Considerations.
        Focus on clarity and actionable specifications.
        """
        
        let userPrompt = """
        Feature: \(feature)
        Context: \(context)
        Priority: \(priority)
        Requirements:
        \(requirements.map { "- \($0)" }.joined(separator: "\n"))
        
        Generate a detailed PRD for this feature.
        """
        
        var messages = [ChatMessage(role: .system, content: systemPrompt)]
        
        // Include session history if requested
        if includeHistory, let sessionId = currentSession {
            let history = sessionHistory[sessionId] ?? []
            messages.append(contentsOf: history.suffix(5)) // Last 5 messages for context
        }
        
        messages.append(ChatMessage(role: .user, content: userPrompt))
        
        return messages
    }
}