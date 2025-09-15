import Foundation

/// Simple deterministic router for provider selection based on request characteristics
public final class ProviderRouter {
    
    public enum Route: Equatable {
        case appleOnDevice      // Apple Foundation Models on-device
        case applePCC           // Apple Private Cloud Compute
        case externalAPI(String) // Anthropic/OpenAI/Gemini
    }
    
    public struct RoutingPolicy {
        public let allowExternalProviders: Bool
        public let preferPrivacy: Bool
        public let useAppleIntelligenceFirst: Bool
        public let maxContextForOnDevice: Int
        public let maxContextForPCC: Int
        
        public init(
            allowExternalProviders: Bool = false,
            preferPrivacy: Bool = true,
            useAppleIntelligenceFirst: Bool = true,
            maxContextForOnDevice: Int = 1500,
            maxContextForPCC: Int = 6000
        ) {
            self.allowExternalProviders = allowExternalProviders
            self.preferPrivacy = preferPrivacy
            self.useAppleIntelligenceFirst = useAppleIntelligenceFirst
            self.maxContextForOnDevice = maxContextForOnDevice
            self.maxContextForPCC = maxContextForPCC
        }
    }
    
    private let policy: RoutingPolicy
    private let capabilities: DeviceCapabilities
    
    public init(policy: RoutingPolicy) {
        self.policy = policy
        self.capabilities = DeviceCapabilities.probe()
    }
    
    /// Enhanced routing with Apple Intelligence prioritization
    public func route(messages: [ChatMessage], needsJSON: Bool = false) -> [Route] {
        // Calculate content size
        let contentSize = messages.reduce(0) { sum, message in
            sum + message.content.count
        }
        
        var routes: [Route] = []
        
        // Decision tree based on Apple's recommended thresholds
        if contentSize < policy.maxContextForOnDevice && !needsJSON {
            // Small prompts (< 1500 chars) without JSON → on-device first
            if capabilities.hasFoundationModels {
                routes.append(.appleOnDevice)
            }
            
            // Fallback to external providers if allowed
            if policy.allowExternalProviders {
                routes.append(.externalAPI(AIProviderConstants.ProviderKeys.anthropic))
                routes.append(.externalAPI(AIProviderConstants.ProviderKeys.openAI))
                routes.append(.externalAPI(AIProviderConstants.ProviderKeys.gemini))
            }
            
        } else if contentSize < policy.maxContextForPCC {
            // Medium prompts (< 6000 chars) → try PCC first
            if capabilities.supportsPCC {
                routes.append(.applePCC)
            }
            
            // If JSON is needed and external allowed, add them
            if needsJSON && policy.allowExternalProviders {
                routes.append(.externalAPI(AIProviderConstants.ProviderKeys.anthropic))  // Best for JSON
                routes.append(.externalAPI(AIProviderConstants.ProviderKeys.openAI))
                routes.append(.externalAPI(AIProviderConstants.ProviderKeys.gemini))
            }
            
            // Fallback to on-device if available
            if capabilities.hasFoundationModels {
                routes.append(.appleOnDevice)
            }
            
            // Final fallback to external providers if not already added
            if !needsJSON && policy.allowExternalProviders {
                routes.append(.externalAPI(AIProviderConstants.ProviderKeys.openAI))
                routes.append(.externalAPI(AIProviderConstants.ProviderKeys.anthropic))
                routes.append(.externalAPI(AIProviderConstants.ProviderKeys.gemini))
            }
            
        } else {
            // Large prompts (6000+ chars) or strict JSON requirements
            
            // External providers first if allowed
            if policy.allowExternalProviders {
                if needsJSON {
                    routes.append(.externalAPI(AIProviderConstants.ProviderKeys.anthropic))  // Claude best for JSON
                    routes.append(.externalAPI(AIProviderConstants.ProviderKeys.openAI))
                    routes.append(.externalAPI(AIProviderConstants.ProviderKeys.gemini))
                } else {
                    routes.append(.externalAPI(AIProviderConstants.ProviderKeys.openAI))     // GPT good for long context
                    routes.append(.externalAPI(AIProviderConstants.ProviderKeys.anthropic))
                    routes.append(.externalAPI(AIProviderConstants.ProviderKeys.gemini))
                }
            }
            
            // Try PCC if available
            if capabilities.supportsPCC {
                routes.append(.applePCC)
            }
        }
        
        return routes
    }
    
    /// Enhanced routing decision with capability scoring
    public func routeWithCapabilities(
        messages: [ChatMessage],
        requiredCapabilities: Set<String> = []
    ) -> [Route] {
        var routes = route(messages: messages, needsJSON: requiredCapabilities.contains(AIProviderConstants.CapabilityNames.json))
        
        // Prioritize based on required capabilities
        if requiredCapabilities.contains(AIProviderConstants.CapabilityNames.longContext) {
            // Move external providers to front if allowed
            if policy.allowExternalProviders {
                routes = routes.sorted { route1, route2 in
                    switch (route1, route2) {
                    case (.externalAPI(_), _):
                        return true
                    case (_, .externalAPI(_)):
                        return false
                    default:
                        return false
                    }
                }
            }
        }
        
        if requiredCapabilities.contains(AIProviderConstants.CapabilityNames.realtime) {
            // Prioritize on-device for lowest latency
            routes = routes.sorted { route1, route2 in
                switch (route1, route2) {
                case (.appleOnDevice, _):
                    return true
                case (_, .appleOnDevice):
                    return false
                default:
                    return false
                }
            }
        }
        
        return routes
    }
    
    /// Get routing explanation for debugging
    public func explainRoute(messages: [ChatMessage], needsJSON: Bool = false) -> String {
        let routes = route(messages: messages, needsJSON: needsJSON)
        let contentSize = messages.reduce(0) { $0 + $1.content.count }
        
        var explanation = AIProviderConstants.RoutingDecisions.routingDecisionHeader
        explanation += String(format: AIProviderConstants.RoutingDecisions.contentSizeFormat, contentSize)
        explanation += String(format: AIProviderConstants.RoutingDecisions.needsJSONFormat, needsJSON ? "yes" : "no")
        explanation += String(format: AIProviderConstants.RoutingDecisions.privacyModeFormat, policy.preferPrivacy ? AIProviderConstants.RoutingDecisions.enabled : AIProviderConstants.RoutingDecisions.disabled)
        explanation += String(format: AIProviderConstants.RoutingDecisions.appleIntelligenceFormat, policy.useAppleIntelligenceFirst ? AIProviderConstants.RoutingDecisions.prioritized : AIProviderConstants.RoutingDecisions.normal)
        explanation += String(format: AIProviderConstants.RoutingDecisions.externalAllowedFormat, policy.allowExternalProviders ? "yes" : "no")
        explanation += String(format: AIProviderConstants.RoutingDecisions.routeChainFormat, routes.map { $0.description }.joined(separator: AIProviderConstants.RoutingDecisions.arrow))
        
        if let first = routes.first {
            switch first {
            case .appleOnDevice:
                explanation += AIProviderConstants.RoutingDecisions.onDeviceMessage
            case .applePCC:
                explanation += AIProviderConstants.RoutingDecisions.pccMessage
            case .externalAPI:
                explanation += AIProviderConstants.RoutingDecisions.externalMessage
            }
        }
        
        return explanation
    }
}

extension ProviderRouter.Route: Hashable, CustomStringConvertible {
    public var description: String {
        switch self {
        case .appleOnDevice:
            return AIProviderConstants.RouteDescriptions.appleOnDevice
        case .applePCC:
            return AIProviderConstants.RouteDescriptions.applePCC
        case .externalAPI(let provider):
            return "\(provider)\(AIProviderConstants.RouteDescriptions.apiSuffix)"
        }
    }
}

// Re-export DeviceCapabilities for convenience
public extension ProviderRouter {
    var deviceCapabilities: DeviceCapabilities {
        return capabilities
    }
}