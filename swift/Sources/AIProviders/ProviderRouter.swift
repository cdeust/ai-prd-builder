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
                routes.append(.externalAPI("anthropic"))
                routes.append(.externalAPI("openai"))
                routes.append(.externalAPI("gemini"))
            }
            
        } else if contentSize < policy.maxContextForPCC {
            // Medium prompts (< 6000 chars) → try PCC first
            if capabilities.supportsPCC {
                routes.append(.applePCC)
            }
            
            // If JSON is needed and external allowed, add them
            if needsJSON && policy.allowExternalProviders {
                routes.append(.externalAPI("anthropic"))  // Best for JSON
                routes.append(.externalAPI("openai"))
                routes.append(.externalAPI("gemini"))
            }
            
            // Fallback to on-device if available
            if capabilities.hasFoundationModels {
                routes.append(.appleOnDevice)
            }
            
            // Final fallback to external providers if not already added
            if !needsJSON && policy.allowExternalProviders {
                routes.append(.externalAPI("openai"))
                routes.append(.externalAPI("anthropic"))
                routes.append(.externalAPI("gemini"))
            }
            
        } else {
            // Large prompts (6000+ chars) or strict JSON requirements
            
            // External providers first if allowed
            if policy.allowExternalProviders {
                if needsJSON {
                    routes.append(.externalAPI("anthropic"))  // Claude best for JSON
                    routes.append(.externalAPI("openai"))
                    routes.append(.externalAPI("gemini"))
                } else {
                    routes.append(.externalAPI("openai"))     // GPT good for long context
                    routes.append(.externalAPI("anthropic"))
                    routes.append(.externalAPI("gemini"))
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
        var routes = route(messages: messages, needsJSON: requiredCapabilities.contains("json"))
        
        // Prioritize based on required capabilities
        if requiredCapabilities.contains("long_context") {
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
        
        if requiredCapabilities.contains("realtime") {
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
        
        var explanation = "📍 Routing Decision:\n"
        explanation += "  Content size: \(contentSize) chars\n"
        explanation += "  Needs JSON: \(needsJSON)\n"
        explanation += "  Privacy mode: \(policy.preferPrivacy ? "enabled" : "disabled")\n"
        explanation += "  Apple Intelligence: \(policy.useAppleIntelligenceFirst ? "prioritized" : "normal")\n"
        explanation += "  External allowed: \(policy.allowExternalProviders)\n"
        explanation += "  Route chain: \(routes.map { $0.description }.joined(separator: " → "))\n"
        
        if let first = routes.first {
            switch first {
            case .appleOnDevice:
                explanation += "  ✅ Using on-device for privacy & speed"
            case .applePCC:
                explanation += "  ☁️ Using PCC for privacy-preserved cloud processing"
            case .externalAPI:
                explanation += "  🌐 Using external API for advanced capabilities"
            }
        }
        
        return explanation
    }
}

extension ProviderRouter.Route: Hashable, CustomStringConvertible {
    public var description: String {
        switch self {
        case .appleOnDevice:
            return "Apple FM (on-device)"
        case .applePCC:
            return "Apple PCC"
        case .externalAPI(let provider):
            return "\(provider) API"
        }
    }
}

// Re-export DeviceCapabilities for convenience
public extension ProviderRouter {
    var deviceCapabilities: DeviceCapabilities {
        return capabilities
    }
}