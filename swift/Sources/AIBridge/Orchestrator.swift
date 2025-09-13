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
    
    // MARK: - Glossary/Domain per session
    private var sessionGlossary: [UUID: DomainGlossary] = [:]
    
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
        if let sid = self.currentSession {
            sessionGlossary[sid] = DomainGlossary(domain: .product)
        }
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
        sessionGlossary[sessionId] = DomainGlossary(domain: .product)
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
    
    // MARK: - Glossary/Domain Public API
    
    public func setDomain(_ domain: DomainGlossary.Domain) async {
        guard let sid = currentSession else { return }
        if sessionGlossary[sid] == nil {
            sessionGlossary[sid] = DomainGlossary(domain: domain)
        } else {
            if let glossary = sessionGlossary[sid] {
                await glossary.setDomain(domain)
            }
        }
    }
    
    public func addGlossaryEntry(acronym: String, expansion: String) async {
        guard let sid = currentSession else { return }
        if sessionGlossary[sid] == nil {
            sessionGlossary[sid] = DomainGlossary(domain: .product)
        }
        if let glossary = sessionGlossary[sid] {
            await glossary.addOverride(acronym: acronym, expansion: expansion)
        }
    }
    
    public func listGlossary() async -> [DomainGlossary.Entry] {
        guard let sid = currentSession, let g = sessionGlossary[sid] else { return [] }
        return await g.list()
    }
    
    private func glossaryForCurrentSession() -> DomainGlossary {
        if let sid = currentSession, let g = sessionGlossary[sid] {
            return g
        }
        let g = DomainGlossary(domain: .product)
        if let sid = currentSession { sessionGlossary[sid] = g }
        return g
    }
    
    private func buildAcronymSystemPolicy() async -> String {
        let glossary = glossaryForCurrentSession()
        let domain = await glossary.domain
        let entries = await glossary.list()
        let pairs = entries.map { "\($0.acronym): \($0.expansion)" }.joined(separator: "; ")
        let domainName = domain.rawValue.capitalized
        return """
        Acronym Policy (Domain: \(domainName)):
        - Use the following glossary when interpreting acronyms.
        - If an acronym is not in the glossary or is ambiguous, ask a brief clarification question instead of guessing.
        - On first use, expand the acronym in parentheses, e.g., "PRD (Product Requirements Document)".
        - Maintain consistency across the conversation.
        Glossary: \(pairs)
        """
    }
    
    // MARK: - Apple Intelligence Post-Processing
    
    private func postProcessWithAppleIntelligence(_ content: String) async -> String {
        guard appleIntelligence.isAvailable() else { return content }
        
        do {
            let improved = try await appleIntelligence.applyWritingTools(
                text: content,
                command: .makeProfessional
            )
            print("✨ Enhanced with Apple Intelligence Writing Tools")
            return improved
        } catch {
            return content
        }
    }
    
    // MARK: - Provider Selection
    
    /// Select specific provider for generation
    public func generateWithProvider(
        _ provider: Orchestrator.AIProvider,
        prompt: String
    ) async throws -> String {
        
        let config = ProviderConfiguration.fromEnvironment(for: provider)
        guard let config = config, config.isConfigured else {
            throw NSError(
                domain: "AIOrchestrator",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "\(provider.rawValue) is not configured. Please set API key."]
            )
        }
        
        let messages = [
            ChatMessage(role: .system, content: "You are an expert software developer. Generate high-quality code."),
            ChatMessage(role: .user, content: prompt)
        ]
        
        switch provider {
        case .foundationModels:
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
        case .privateCloudCompute:
            if privacyConfig.allowExternalProviders {
                guard privacyConfig.allowExternalProviders else {
                    throw NSError(
                        domain: "AIOrchestrator",
                        code: 403,
                        userInfo: [NSLocalizedDescriptionKey: "External providers disabled. Run with --allow-external"]
                    )
                }
            }
            return try await useSpecificExternalProvider("private-cloud-compute", messages: messages)
            
        case .anthropic:
            guard privacyConfig.allowExternalProviders else {
                throw NSError(
                    domain: "AIOrchestrator",
                    code: 403,
                    userInfo: [NSLocalizedDescriptionKey: "External providers disabled. Run with --allow-external"]
                )
            }
            return try await useSpecificExternalProvider("anthropic", messages: messages)
            
        case .openai:
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
        useAppleIntelligence: Bool = true,
        options: ChatOptions = ChatOptions()
    ) async throws -> (response: String, provider: AIProvider) {
        
        storeInSession(content: message, role: .user)
        
        let glossary = glossaryForCurrentSession()
        let systemPolicy = await buildAcronymSystemPolicy()
        let userMessageExpanded = await AcronymResolver.expandFirstUse(in: message, glossary: glossary)

        let fixedContext = options.injectContext ? SystemContextBuilder.buildFixedContext(persona: options.persona) : ""
        let combinedSystem = [ "You are a helpful AI assistant.", fixedContext, systemPolicy ]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        
        if useAppleIntelligence && appleIntelligence.isAvailable() && message.count < 500 {
            do {
                var response = try await appleIntelligence.applyWritingTools(
                    text: userMessageExpanded,
                    command: .rewrite
                )
                if options.twoPassRefine {
                    let rewritePrompt = SystemContextBuilder.buildRewriteInstruction(persona: options.persona)
                    response = try await refineResponseWithProvider(
                        base: response,
                        system: combinedSystem,
                        instruction: rewritePrompt
                    )
                }
                if options.enforcePRD {
                    let validation = PRDChatValidator.validate(response)
                    if !validation.isValid {
                        let correction = PRDChatValidator.buildCorrectionPrompt(missing: validation, persona: options.persona)
                        response = try await refineResponseWithProvider(
                            base: response,
                            system: combinedSystem,
                            instruction: correction
                        )
                    }
                }
                let (validated, _) = await AcronymResolver.validateAndAmend(response: response, glossary: glossary)
                storeInSession(content: validated, role: .assistant)
                return (validated, .foundationModels)
            } catch {
                // Fall back to LLM
            }
        }
        
        var messages: [ChatMessage] = []
        messages.append(ChatMessage(role: .system, content: combinedSystem))
        messages.append(ChatMessage(role: .user, content: userMessageExpanded))
        
        let routes = router.route(messages: messages)
        
        for route in routes {
            do {
                var (content, provider) = try await executeRoute(
                    route: route,
                    messages: messages,
                    originalRequest: (message, "", "medium", [])
                )
                
                if options.twoPassRefine {
                    let rewritePrompt = SystemContextBuilder.buildRewriteInstruction(persona: options.persona)
                    content = try await refineResponseWithProvider(
                        base: content,
                        system: combinedSystem,
                        instruction: rewritePrompt
                    )
                }
                
                if options.enforcePRD {
                    let validation = PRDChatValidator.validate(content)
                    if !validation.isValid {
                        let correction = PRDChatValidator.buildCorrectionPrompt(missing: validation, persona: options.persona)
                        content = try await refineResponseWithProvider(
                            base: content,
                            system: combinedSystem,
                            instruction: correction
                        )
                    }
                }
                
                let (validated, _) = await AcronymResolver.validateAndAmend(response: content, glossary: glossary)
                storeInSession(content: validated, role: .assistant)
                return (validated, provider)
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
    
    private func refineResponseWithProvider(base: String, system: String, instruction: String) async throws -> String {
        let refineMessages = [
            ChatMessage(role: .system, content: system),
            ChatMessage(role: .user, content: "\(instruction)\n\n---\nOriginal Answer:\n\(base)")
        ]
        
        let routes = router.route(messages: refineMessages)
        for route in routes {
            do {
                let (content, _) = try await executeRoute(
                    route: route,
                    messages: refineMessages,
                    originalRequest: ("", "", "", [])
                )
                return content
            } catch {
                continue
            }
        }
        return base
    }
    
    // MARK: - PRD Generation and Routing
    
    public func getAvailableProviders() -> [AIProvider] {
        var providers: [AIProvider] = []
        
        if appleOnDevice.isAvailable() {
            providers.append(.foundationModels)
        }
        if applePCC.isAvailable() {
            providers.append(.privateCloudCompute)
        }
        
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
    
    public func generatePRD(
        feature: String,
        context: String,
        priority: String,
        requirements: [String],
        skipValidation: Bool = false,
        useAppleIntelligence: Bool = true,
        useEnhancedGeneration: Bool = true
    ) async throws -> (content: String, provider: AIProvider, quality: PRDQuality) {
        
        if useEnhancedGeneration {
            do {
                print("🚀 Starting enhanced multi-stage PRD generation...")
                
                let systemPolicy = await buildAcronymSystemPolicy()
                
                let generateFunc: (String) async throws -> String = { prompt in
                    let messages = [
                        ChatMessage(role: .system, content: "You are an expert PRD generator. Follow instructions precisely.\n" + systemPolicy),
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
                            let (validated, _) = await AcronymResolver.validateAndAmend(response: content, glossary: self.glossaryForCurrentSession())
                            return validated
                        } catch {
                            continue
                        }
                    }
                    
                    throw NSError(domain: "PRDGeneration", code: 500, userInfo: [NSLocalizedDescriptionKey: "All providers failed"])
                }
                
                let (prdContent, score, iterations) = try await PRDUtil.GenerationPipeline.generateEnhancedPRD(
                    feature: feature,
                    context: context,
                    requirements: requirements,
                    generateFunc: generateFunc
                )
                
                print("✅ Enhanced PRD generated with score: \(score)% after \(iterations) iterations")
                
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
                
                storeInSession(content: prdContent, role: .assistant)
                
                let finalContent = await postProcessWithAppleIntelligence(prdContent)
                
                return (finalContent, .foundationModels, quality)
                
            } catch {
                print("⚠️ Enhanced generation failed, falling back to standard: \(error)")
            }
        }
        
        let messages = PRDMessageBuilder.build(
            feature: feature,
            context: context,
            priority: priority,
            requirements: requirements,
            includeHistory: true,
            history: currentSession.flatMap { sessionHistory[$0] } ?? [],
            glossaryPolicy: await buildAcronymSystemPolicy()
        )
        
        let needsJSON = true
        let routes = router.route(messages: messages, needsJSON: needsJSON)
        
        print(router.explainRoute(messages: messages, needsJSON: needsJSON))
        
        for route in routes {
            do {
                let (content, provider) = try await executeRoute(
                    route: route,
                    messages: messages,
                    originalRequest: (feature, context, priority, requirements)
                )
                
                print("✅ Generated using \(provider.rawValue)")
                
                storeInSession(content: content, role: .assistant)
                
                let finalContent = await postProcessWithAppleIntelligence(content)
                
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
                jsonSchema: nil,
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
}
