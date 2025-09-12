import Foundation
import AIProviders

/// Privacy-first orchestrator with Apple Foundation Models as primary provider
/// Refactored with clean architecture and better separation of concerns
public final class Orchestrator {
    
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
    /// Now with multi-stage generation and iterative refinement for GPT-5 level quality
    public func generatePRD(
        feature: String,
        context: String,
        priority: String,
        requirements: [String],
        skipValidation: Bool = false,
        useAppleIntelligence: Bool = true,
        useEnhancedGeneration: Bool = true
    ) async throws -> (content: String, provider: AIProvider, quality: PRDQuality) {
        
        // Try enhanced multi-stage generation if enabled
        if useEnhancedGeneration {
            do {
                print("🚀 Starting enhanced multi-stage PRD generation...")
                
                // Create generation function that uses the selected provider
                let generateFunc: (String) async throws -> String = { prompt in
                    let messages = [
                        ChatMessage(role: .system, content: "You are an expert PRD generator. Follow instructions precisely."),
                        ChatMessage(role: .user, content: prompt)
                    ]
                    
                    let routes = self.router.route(messages: messages, needsJSON: true)
                    
                    for route in routes {
                        do {
                            let (content, _) = try await self.executeRoute(
                                route: route,
                                messages: messages,
                                originalRequest: (feature, context, priority, requirements)
                            )
                            return content
                        } catch {
                            continue
                        }
                    }
                    
                    throw NSError(domain: "PRDGeneration", code: 500, userInfo: [NSLocalizedDescriptionKey: "All providers failed"])
                }
                
                // Execute multi-stage pipeline
                let (prdContent, score, iterations) = try await PRDUtil.GenerationPipeline.generateEnhancedPRD(
                    feature: feature,
                    context: context,
                    requirements: requirements,
                    generateFunc: generateFunc
                )
                
                print("✅ Enhanced PRD generated with score: \(score)% after \(iterations) iterations")
                
                // Calculate detailed quality metrics
                let detailedScore = PRDUtil.PRDScorer.scoreEnhanced(prdContent)
                let quality = PRDQuality(
                    score: detailedScore.overall,
                    completeness: detailedScore.completeness,
                    specificity: detailedScore.specificity,
                    technicalDepth: detailedScore.technicalDepth,
                    clarity: detailedScore.clarity,
                    actionability: detailedScore.actionability,
                    iterations: iterations
                )
                
                // Store in session
                storeInSession(content: prdContent, role: .assistant)
                
                // Post-process with Apple Intelligence if available
                let finalContent = await postProcessWithAppleIntelligence(prdContent)
                
                return (finalContent, .foundationModels, quality)
                
            } catch {
                print("⚠️ Enhanced generation failed, falling back to standard: \(error)")
            }
        }
        
        // Fallback: Try Apple Intelligence Writing Tools if available
        if useAppleIntelligence && appleIntelligence.isAvailable() {
            do {
                let prdContent = try await appleIntelligence.generatePRD(
                    feature: feature,
                    context: context,
                    priority: priority,
                    requirements: requirements
                )
                
                // Calculate quality score
                let detailedScore = PRDUtil.PRDScorer.scoreEnhanced(prdContent)
                let quality = PRDQuality(
                    score: detailedScore.overall,
                    completeness: detailedScore.completeness,
                    specificity: detailedScore.specificity,
                    technicalDepth: detailedScore.technicalDepth,
                    clarity: detailedScore.clarity,
                    actionability: detailedScore.actionability,
                    iterations: 1
                )
                
                // Store in session
                storeInSession(content: prdContent, role: .assistant)
                
                return (prdContent, .foundationModels, quality)
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
                
                // Calculate quality score for standard generation
                let detailedScore = PRDUtil.PRDScorer.scoreEnhanced(finalContent)
                let quality = PRDQuality(
                    score: detailedScore.overall,
                    completeness: detailedScore.completeness,
                    specificity: detailedScore.specificity,
                    technicalDepth: detailedScore.technicalDepth,
                    clarity: detailedScore.clarity,
                    actionability: detailedScore.actionability,
                    iterations: 1
                )
                
                return (finalContent, provider, quality)
                
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
    
    public func clearConversation() {
        if let sessionId = currentSession {
            sessionHistory[sessionId] = []
        }
    }
    
    public var conversationHistory: [ChatMessage] {
        guard let sessionId = currentSession else { return [] }
        return sessionHistory[sessionId] ?? []
    }
    
    public var sessionId: UUID {
        return currentSession ?? UUID()
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
    
    // MARK: - Provider Selection
    
    /// Select specific provider for generation
    public func generateWithProvider(
        _ provider: ImplementationGenerator.AIProvider,
        prompt: String
    ) async throws -> String {
        
        // Check if provider is configured
        let config = ImplementationGenerator.ProviderConfiguration.fromEnvironment(for: provider)
        guard let config = config, config.isConfigured else {
            throw NSError(
                domain: "AIOrchestrator",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "\(provider.rawValue) is not configured. Please set API key."]
            )
        }
        
        // Route to appropriate provider
        let messages = [
            ChatMessage(role: .system, content: "You are an expert software developer. Generate high-quality code."),
            ChatMessage(role: .user, content: prompt)
        ]
        
        switch provider {
        case .appleIntelligence:
            if appleIntelligence.isAvailable() {
                let response = try await appleIntelligence.applyWritingTools(
                    text: prompt,
                    command: .rewrite
                )
                return response
            } else {
                throw NSError(
                    domain: "AIOrchestrator",
                    code: 503,
                    userInfo: [NSLocalizedDescriptionKey: "Apple Intelligence not available"]
                )
            }
            
        case .claude:
            guard privacyConfig.allowExternalProviders else {
                throw NSError(
                    domain: "AIOrchestrator",
                    code: 403,
                    userInfo: [NSLocalizedDescriptionKey: "External providers disabled. Run with --allow-external"]
                )
            }
            return try await useSpecificExternalProvider("anthropic", messages: messages)
            
        case .gpt:
            guard privacyConfig.allowExternalProviders else {
                throw NSError(
                    domain: "AIOrchestrator",
                    code: 403,
                    userInfo: [NSLocalizedDescriptionKey: "External providers disabled. Run with --allow-external"]
                )
            }
            return try await useSpecificExternalProvider("openai", messages: messages)
            
        case .gemini:
            guard privacyConfig.allowExternalProviders else {
                throw NSError(
                    domain: "AIOrchestrator",
                    code: 403,
                    userInfo: [NSLocalizedDescriptionKey: "External providers disabled. Run with --allow-external"]
                )
            }
            return try await useSpecificExternalProvider("gemini", messages: messages)
        }
    }
    
    private func useSpecificExternalProvider(
        _ providerKey: String,
        messages: [ChatMessage]
    ) async throws -> String {
        
        _ = coordinator.setActiveProvider(providerKey)
        let result = await coordinator.sendMessages(messages)
        
        switch result {
        case .success(let content):
            return content
        case .failure(let error):
            throw error
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
    
    // MARK: - PRD Quality Tracking
    
    public struct PRDQuality {
        public let score: Double
        public let completeness: Double
        public let specificity: Double
        public let technicalDepth: Double
        public let clarity: Double
        public let actionability: Double
        public let iterations: Int
        
        public var isProductionReady: Bool {
            return score >= 85.0
        }
        
        public var summary: String {
            """
            PRD Quality Assessment:
            Overall Score: \(String(format: "%.1f", score))% \(isProductionReady ? "✅" : "⚠️")
            - Completeness: \(String(format: "%.1f", completeness))%
            - Specificity: \(String(format: "%.1f", specificity))%
            - Technical Depth: \(String(format: "%.1f", technicalDepth))%
            - Clarity: \(String(format: "%.1f", clarity))%
            - Actionability: \(String(format: "%.1f", actionability))%
            Iterations: \(iterations)
            Status: \(isProductionReady ? "Production Ready" : "Needs Improvement")
            """
        }
    }
    
    private func buildPRDMessages(
        feature: String,
        context: String,
        priority: String,
        requirements: [String],
        includeHistory: Bool = false
    ) -> [ChatMessage] {
        
        let systemPrompt = """
        You are a senior technical product manager creating production-ready PRDs.
        
        Your PRDs must be:
        1. **Comprehensive**: Cover all aspects from problem to deployment
        2. **Specific**: Use exact numbers, dates, and metrics (no vague terms)
        3. **Technical**: Include API specs, data models, and architecture
        4. **Actionable**: Clear acceptance criteria and implementation steps
        5. **Measurable**: Quantified success metrics and KPIs
        
        Structure:
        - Executive Summary (with quantified problem/solution)
        - Functional Requirements (with priorities)
        - Technical Specification (APIs, database, security)
        - Acceptance Criteria (GIVEN-WHEN-THEN format)
        - Success Metrics (baseline → target)
        - Implementation Plan (phased delivery)
        - Risks & Mitigation (with probabilities)
        
        Focus on developer-readiness and immediate actionability.
        """
        
        let userPrompt = """
        Create a comprehensive PRD for:
        
        **Feature:** \(feature)
        **Context:** \(context)
        **Priority:** \(priority)
        **Requirements:**
        \(requirements.map { "- \($0)" }.joined(separator: "\n"))
        
        The PRD must be production-ready with:
        - Specific technical specifications
        - Clear API endpoint definitions
        - Database schema if applicable
        - Measurable acceptance criteria
        - Quantified success metrics
        - Realistic timeline with phases
        - Risk assessment with mitigation
        
        Make it immediately actionable for developers.
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
