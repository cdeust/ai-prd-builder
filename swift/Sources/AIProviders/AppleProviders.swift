import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Apple On-Device Provider

public final class AppleOnDeviceProvider: LLMProvider {
    public let name = AIProviderConstants.AppleProviders.onDeviceName
    private let capabilities = DeviceCapabilities.probe()

    public init() {}

    public func generate(_ req: LLMRequest) async throws -> LLMResponse {
        let startTime = Date()
        var response = AIProviderConstants.Formatting.empty

        #if canImport(FoundationModels)
        if #available(macOS 16.0, iOS 26.0, *) {
            // Use Foundation Models framework
            let model = SystemLanguageModel.default

            // Check availability
            guard model.isAvailable else {
                throw NSError(
                    domain: AIProviderConstants.AppleProviders.onDeviceDomain,
                    code: 503,
                    userInfo: [NSLocalizedDescriptionKey: AIProviderConstants.ErrorMessages.appleIntelligenceNotAvailable]
                )
            }

            // Build prompt from request
            var promptText = AIProviderConstants.Formatting.empty
            if let system = req.system {
                promptText += system + AIProviderConstants.Formatting.newlineDouble
            }
            for message in req.messages {
                promptText += "\(message.role)\(AIProviderConstants.Formatting.colonSpace)\(message.content)\(AIProviderConstants.Formatting.newline)"
            }

            // Create session and generate
            let session = LanguageModelSession(instructions: req.system ?? AIProviderConstants.Formatting.empty)
            let output = try await session.respond(to: promptText)
            response = output.content
        } else {
            // Fallback for older OS versions
            throw NSError(
                domain: AIProviderConstants.AppleProviders.onDeviceDomain,
                code: 501,
                userInfo: [NSLocalizedDescriptionKey: AIProviderConstants.ErrorMessages.foundationModelsRequirement]
            )
        }
        #else
        // FoundationModels not available in this build
        throw NSError(
            domain: AIProviderConstants.AppleProviders.onDeviceDomain,
            code: 501,
            userInfo: [NSLocalizedDescriptionKey: AIProviderConstants.ErrorMessages.foundationModelsFrameworkNotAvailable]
        )
        #endif

        let latency = Int(Date().timeIntervalSince(startTime) * 1000)

        return LLMResponse(
            text: response,
            provider: name,
            latencyMs: latency
        )
    }

    public func isAvailable() -> Bool {
        return capabilities.hasFoundationModels
    }
}

// MARK: - Apple PCC Provider

public final class ApplePCCProvider: LLMProvider {
    public let name = AIProviderConstants.AppleProviders.pccName
    private let capabilities = DeviceCapabilities.probe()

    public init() {}

    public func generate(_ req: LLMRequest) async throws -> LLMResponse {
        let startTime = Date()
        var response = AIProviderConstants.Formatting.empty

        if #available(macOS 16.0, iOS 26.0, *) {
            // Use Foundation Models with Private Cloud Compute configuration
            let model = SystemLanguageModel.default // PCC is automatic escalation

            // Check availability
            guard model.isAvailable else {
                throw NSError(
                    domain: AIProviderConstants.AppleProviders.pccDomain,
                    code: 503,
                    userInfo: [NSLocalizedDescriptionKey: AIProviderConstants.ErrorMessages.appleIntelligenceNotAvailablePCC]
                )
            }

            // Build prompt from request
            var promptText = AIProviderConstants.Formatting.empty
            if let system = req.system {
                promptText += system + AIProviderConstants.Formatting.newlineDouble
            }
            for message in req.messages {
                promptText += "\(message.role)\(AIProviderConstants.Formatting.colonSpace)\(message.content)\(AIProviderConstants.Formatting.newline)"
            }

            // Create session with PCC preference and generate
            let session = LanguageModelSession(instructions: req.system ?? AIProviderConstants.Formatting.empty)
            let output = try await session.respond(to: promptText)
            response = output.content
        } else {
            throw NSError(
                domain: AIProviderConstants.AppleProviders.pccDomain,
                code: 501,
                userInfo: [NSLocalizedDescriptionKey: AIProviderConstants.ErrorMessages.foundationModelsRequirement]
            )
        }

        let latency = Int(Date().timeIntervalSince(startTime) * 1000)

        return LLMResponse(
            text: response,
            provider: name,
            latencyMs: latency
        )
    }

    public func isAvailable() -> Bool {
        return capabilities.supportsPCC
    }
}

